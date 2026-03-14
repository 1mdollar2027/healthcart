"""
Clinics Router – Clinic management, doctor assignments, slots.
"""
from typing import Annotated, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from supabase import Client
from app.core.deps import get_supabase_admin
from app.core.security import get_current_user, require_clinic_admin
from app.models.schemas import ClinicCreate, ClinicDoctorAdd, DoctorSlotCreate, MessageResponse

router = APIRouter()


@router.get("/")
async def list_clinics(
    city: Optional[str] = None,
    clinic_type: Optional[str] = None,
    sb: Client = Depends(get_supabase_admin),
):
    """List verified clinics."""
    q = sb.table("clinics").select("*").eq("verification_status", "verified").eq("is_active", True)
    if city:
        q = q.eq("city", city)
    if clinic_type:
        q = q.eq("clinic_type", clinic_type)
    result = q.execute()
    return {"items": result.data or []}


@router.post("/")
async def create_clinic(
    body: ClinicCreate,
    current_user: Annotated[dict, Depends(require_clinic_admin)],
    sb: Annotated[Client, Depends(get_supabase_admin)],
):
    """Create a new clinic (clinic admin)."""
    clinic_data = {
        "admin_profile_id": current_user["id"],
        **body.model_dump(exclude_none=True),
    }
    if body.operating_hours:
        import json
        clinic_data["operating_hours"] = json.dumps(body.operating_hours)
    result = sb.table("clinics").insert(clinic_data).execute()
    return result.data[0]


@router.get("/{clinic_id}")
async def get_clinic(clinic_id: str, sb: Client = Depends(get_supabase_admin)):
    """Get clinic details with doctors."""
    clinic = sb.table("clinics").select("*").eq("id", clinic_id).single().execute()
    if not clinic.data:
        raise HTTPException(status_code=404, detail="Clinic not found")

    # Get doctors in this clinic
    doctors = sb.table("clinic_doctors").select(
        "*, doctors!inner(*, profiles!inner(full_name, avatar_url))"
    ).eq("clinic_id", clinic_id).execute()

    clinic.data["doctors"] = doctors.data or []
    return clinic.data


@router.get("/my-clinics")
async def my_clinics(
    current_user: Annotated[dict, Depends(require_clinic_admin)],
    sb: Annotated[Client, Depends(get_supabase_admin)],
):
    """Get clinics owned by current admin."""
    result = sb.table("clinics").select("*").eq("admin_profile_id", current_user["id"]).execute()
    return {"items": result.data or []}


@router.post("/{clinic_id}/doctors")
async def add_doctor_to_clinic(
    clinic_id: str,
    body: ClinicDoctorAdd,
    current_user: Annotated[dict, Depends(require_clinic_admin)],
    sb: Annotated[Client, Depends(get_supabase_admin)],
):
    """Add a doctor to a clinic."""
    # Verify clinic ownership
    clinic = sb.table("clinics").select("id").eq("id", clinic_id).eq(
        "admin_profile_id", current_user["id"]
    ).maybe_single().execute()
    if not clinic.data:
        raise HTTPException(status_code=403, detail="Not your clinic")

    result = sb.table("clinic_doctors").insert({
        "clinic_id": clinic_id,
        "doctor_id": body.doctor_id,
        "is_primary": body.is_primary,
        "slot_duration_minutes": body.slot_duration_minutes,
    }).execute()
    return result.data[0]


@router.delete("/{clinic_id}/doctors/{doctor_id}")
async def remove_doctor_from_clinic(
    clinic_id: str,
    doctor_id: str,
    current_user: Annotated[dict, Depends(require_clinic_admin)],
    sb: Annotated[Client, Depends(get_supabase_admin)],
):
    """Remove a doctor from a clinic."""
    sb.table("clinic_doctors").delete().eq("clinic_id", clinic_id).eq("doctor_id", doctor_id).execute()
    return MessageResponse(message="Doctor removed from clinic")


@router.post("/slots")
async def create_doctor_slot(
    body: DoctorSlotCreate,
    current_user: Annotated[dict, Depends(get_current_user)],
    sb: Annotated[Client, Depends(get_supabase_admin)],
):
    """Create a recurring time slot for a doctor."""
    slot_data = {
        **body.model_dump(),
        "start_time": body.start_time.isoformat(),
        "end_time": body.end_time.isoformat(),
    }
    result = sb.table("doctor_slots").insert(slot_data).execute()
    return result.data[0]


@router.get("/{clinic_id}/appointments")
async def clinic_appointments(
    clinic_id: str,
    date: Optional[str] = None,
    status: Optional[str] = None,
    current_user: Annotated[dict, Depends(require_clinic_admin)],
    sb: Annotated[Client, Depends(get_supabase_admin)],
):
    """Get all appointments for a clinic."""
    q = sb.table("appointments").select(
        "*, doctors!inner(profiles!inner(full_name)), profiles!inner(full_name, phone)"
    ).eq("clinic_id", clinic_id)
    if date:
        q = q.eq("appointment_date", date)
    if status:
        q = q.eq("status", status)
    result = q.order("appointment_date").order("appointment_time").execute()
    return {"items": result.data or []}


@router.get("/{clinic_id}/revenue")
async def clinic_revenue(
    clinic_id: str,
    current_user: Annotated[dict, Depends(require_clinic_admin)],
    sb: Annotated[Client, Depends(get_supabase_admin)],
):
    """Get clinic revenue summary."""
    # Get completed appointments
    appts = sb.table("appointments").select(
        "id, doctors!inner(consultation_fee)"
    ).eq("clinic_id", clinic_id).eq("status", "completed").execute()

    total_revenue = sum(
        a.get("doctors", {}).get("consultation_fee", 0) for a in (appts.data or [])
    )
    total_consultations = len(appts.data or [])

    return {
        "total_revenue": total_revenue,
        "total_consultations": total_consultations,
        "average_per_consultation": total_revenue / total_consultations if total_consultations > 0 else 0,
    }
