"""
Bookings Router – Doctor search, appointment CRUD, slot management.
"""
from typing import Annotated, Optional
from datetime import date
from fastapi import APIRouter, Depends, HTTPException, Query
from supabase import Client
from app.core.deps import get_supabase_admin
from app.core.security import get_current_user, require_doctor, require_authenticated
from app.models.schemas import (
    AppointmentCreate, AppointmentUpdate, AppointmentResponse,
    DoctorSearchParams, DoctorResponse, MessageResponse
)

router = APIRouter()


@router.get("/doctors")
async def search_doctors(
    specialization: Optional[str] = None,
    city: Optional[str] = None,
    min_fee: Optional[float] = None,
    max_fee: Optional[float] = None,
    available_for_video: Optional[bool] = None,
    query: Optional[str] = None,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=50),
    sb: Client = Depends(get_supabase_admin),
):
    """Search doctors with filters. Public endpoint (verified doctors only)."""
    q = sb.table("doctors").select(
        "*, profiles!inner(full_name, avatar_url, phone, city)"
    ).eq("verification_status", "verified").eq("is_active", True)

    if specialization:
        q = q.ilike("specialization", f"%{specialization}%")
    if city:
        q = q.eq("profiles.city", city)
    if min_fee is not None:
        q = q.gte("consultation_fee", min_fee)
    if max_fee is not None:
        q = q.lte("consultation_fee", max_fee)
    if available_for_video is not None:
        q = q.eq("available_for_video", available_for_video)

    offset = (page - 1) * limit
    result = q.range(offset, offset + limit - 1).execute()

    doctors = []
    for d in result.data or []:
        profile = d.pop("profiles", {})
        doctors.append({
            **d,
            "full_name": profile.get("full_name"),
            "avatar_url": profile.get("avatar_url"),
            "phone": profile.get("phone"),
        })

    return {"items": doctors, "page": page, "limit": limit}


@router.get("/doctors/{doctor_id}")
async def get_doctor(
    doctor_id: str,
    sb: Client = Depends(get_supabase_admin),
):
    """Get doctor details with profile info."""
    result = sb.table("doctors").select(
        "*, profiles!inner(full_name, avatar_url, phone, city, email)"
    ).eq("id", doctor_id).single().execute()

    if not result.data:
        raise HTTPException(status_code=404, detail="Doctor not found")

    profile = result.data.pop("profiles", {})
    return {**result.data, **profile}


@router.get("/doctors/{doctor_id}/slots")
async def get_doctor_slots(
    doctor_id: str,
    target_date: Optional[date] = None,
    sb: Client = Depends(get_supabase_admin),
):
    """Get available slots for a doctor on a given date."""
    # Get slot templates
    q = sb.table("doctor_slots").select("*").eq("doctor_id", doctor_id).eq("is_active", True)
    if target_date:
        q = q.eq("day_of_week", target_date.weekday())

    slots = q.execute()

    # Get existing appointments for that date to mark booked slots
    booked = []
    if target_date:
        booked_result = sb.table("appointments").select("appointment_time").eq(
            "doctor_id", doctor_id
        ).eq("appointment_date", target_date.isoformat()).not_.is_("status", "cancelled").execute()
        booked = [a["appointment_time"] for a in (booked_result.data or [])]

    return {
        "slots": slots.data or [],
        "booked_times": booked,
        "date": target_date.isoformat() if target_date else None,
    }


@router.post("/appointments", response_model=AppointmentResponse)
async def create_appointment(
    body: AppointmentCreate,
    current_user: Annotated[dict, Depends(get_current_user)],
    sb: Client = Depends(get_supabase_admin),
):
    """Create a new appointment (patient action)."""
    # Check doctor exists
    doctor = sb.table("doctors").select("id, consultation_fee").eq(
        "id", body.doctor_id
    ).single().execute()
    if not doctor.data:
        raise HTTPException(status_code=404, detail="Doctor not found")

    # Check slot not already booked
    existing = sb.table("appointments").select("id").eq(
        "doctor_id", body.doctor_id
    ).eq("appointment_date", body.appointment_date.isoformat()
    ).eq("appointment_time", body.appointment_time.isoformat()
    ).not_.is_("status", "cancelled").maybe_single().execute()

    if existing.data:
        raise HTTPException(status_code=409, detail="This slot is already booked")

    appointment_data = {
        "patient_id": current_user["id"],
        "doctor_id": body.doctor_id,
        "clinic_id": body.clinic_id,
        "appointment_date": body.appointment_date.isoformat(),
        "appointment_time": body.appointment_time.isoformat(),
        "consultation_type": body.consultation_type,
        "reason": body.reason,
        "status": "pending",
    }

    result = sb.table("appointments").insert(appointment_data).execute()

    # Create audit log
    sb.table("audit_logs").insert({
        "user_id": current_user["id"],
        "action": "create_appointment",
        "resource_type": "appointments",
        "resource_id": result.data[0]["id"],
        "details": {"doctor_id": body.doctor_id, "date": body.appointment_date.isoformat()},
    }).execute()

    return AppointmentResponse(**result.data[0])


@router.get("/appointments")
async def list_appointments(
    status: Optional[str] = None,
    upcoming: bool = False,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=50),
    current_user: dict = Depends(get_current_user),
    sb: Client = Depends(get_supabase_admin),
):
    """List appointments for current user (patient or doctor)."""
    # Check role from profile
    profile = sb.table("profiles").select("role").eq("id", current_user["id"]).single().execute()
    role = profile.data["role"]

    if role == "patient":
        q = sb.table("appointments").select(
            "*, doctors!inner(id, specialization, consultation_fee, profiles!inner(full_name, avatar_url))"
        ).eq("patient_id", current_user["id"])
    elif role == "doctor":
        doctor = sb.table("doctors").select("id").eq("profile_id", current_user["id"]).single().execute()
        q = sb.table("appointments").select(
            "*, profiles!inner(full_name, avatar_url, phone)"
        ).eq("doctor_id", doctor.data["id"])
    else:
        raise HTTPException(status_code=403, detail="Not authorized")

    if status:
        q = q.eq("status", status)
    if upcoming:
        from datetime import date as d
        q = q.gte("appointment_date", d.today().isoformat())

    q = q.order("appointment_date", desc=True).order("appointment_time", desc=True)
    offset = (page - 1) * limit
    result = q.range(offset, offset + limit - 1).execute()

    return {"items": result.data or [], "page": page, "limit": limit}


@router.patch("/appointments/{appointment_id}")
async def update_appointment(
    appointment_id: str,
    body: AppointmentUpdate,
    current_user: dict = Depends(get_current_user),
    sb: Client = Depends(get_supabase_admin),
):
    """Update appointment status (accept/reject/cancel)."""
    update_data = body.model_dump(exclude_none=True)
    if not update_data:
        raise HTTPException(status_code=400, detail="No fields to update")

    result = sb.table("appointments").update(update_data).eq("id", appointment_id).execute()
    if not result.data:
        raise HTTPException(status_code=404, detail="Appointment not found")

    # Audit log
    sb.table("audit_logs").insert({
        "user_id": current_user["id"],
        "action": f"update_appointment_{body.status}" if body.status else "update_appointment",
        "resource_type": "appointments",
        "resource_id": appointment_id,
        "details": update_data,
    }).execute()

    return result.data[0]
