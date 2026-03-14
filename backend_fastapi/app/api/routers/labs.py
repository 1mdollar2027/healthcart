"""
Labs Router – Test catalog, booking, result management.
"""
from typing import Annotated, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File
from supabase import Client
from app.core.deps import get_supabase_admin
from app.core.security import get_current_user, require_lab_admin
from app.models.schemas import LabBookingCreate, LabBookingUpdate, LabResultUpload, MessageResponse

router = APIRouter()


@router.get("/")
async def list_labs(
    city: Optional[str] = None,
    home_collection: Optional[bool] = None,
    sb: Client = Depends(get_supabase_admin),
):
    """List verified labs, optionally filtered."""
    q = sb.table("labs").select("*").eq("verification_status", "verified").eq("is_active", True)
    if city:
        q = q.eq("city", city)
    if home_collection is not None:
        q = q.eq("home_collection_available", home_collection)
    result = q.execute()
    return {"items": result.data or []}


@router.get("/{lab_id}/tests")
async def list_lab_tests(
    lab_id: str,
    category: Optional[str] = None,
    sb: Client = Depends(get_supabase_admin),
):
    """List available tests for a lab."""
    q = sb.table("lab_tests").select("*").eq("lab_id", lab_id).eq("is_active", True)
    if category:
        q = q.eq("category", category)
    result = q.order("name").execute()
    return {"items": result.data or []}


@router.post("/bookings")
async def create_lab_booking(
    body: LabBookingCreate,
    current_user: Annotated[dict, Depends(get_current_user)],
    sb: Annotated[Client, Depends(get_supabase_admin)],
):
    """Book a lab test / home collection."""
    booking_data = {
        "patient_id": current_user["id"],
        **body.model_dump(),
        "collection_date": body.collection_date.isoformat(),
        "status": "booked",
    }
    result = sb.table("lab_bookings").insert(booking_data).execute()

    # Notify lab admin
    lab = sb.table("labs").select("admin_profile_id, name").eq("id", body.lab_id).single().execute()
    if lab.data:
        sb.table("notifications").insert({
            "user_id": lab.data["admin_profile_id"],
            "title": "New Lab Booking",
            "body": f"New sample collection booking for {body.collection_date}",
            "notification_type": "appointment",
            "data": {"lab_booking_id": result.data[0]["id"]},
        }).execute()

    return result.data[0]


@router.get("/bookings")
async def list_lab_bookings(
    status: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
    sb: Client = Depends(get_supabase_admin),
):
    """List lab bookings (patient or lab admin)."""
    profile = sb.table("profiles").select("role").eq("id", current_user["id"]).single().execute()
    role = profile.data["role"]

    if role == "patient":
        q = sb.table("lab_bookings").select(
            "*, lab_tests!inner(name, category, sample_type), labs!inner(name)"
        ).eq("patient_id", current_user["id"])
    elif role in ("lab_admin", "lab_technician"):
        labs = sb.table("labs").select("id").eq("admin_profile_id", current_user["id"]).execute()
        lab_ids = [l["id"] for l in (labs.data or [])]
        if not lab_ids:
            return {"items": []}
        q = sb.table("lab_bookings").select(
            "*, lab_tests!inner(name), profiles!inner(full_name, phone)"
        ).in_("lab_id", lab_ids)
    else:
        raise HTTPException(status_code=403, detail="Not authorized")

    if status:
        q = q.eq("status", status)
    result = q.order("collection_date", desc=True).execute()
    return {"items": result.data or []}


@router.patch("/bookings/{booking_id}")
async def update_lab_booking(
    booking_id: str,
    body: LabBookingUpdate,
    current_user: Annotated[dict, Depends(require_lab_admin)],
    sb: Annotated[Client, Depends(get_supabase_admin)],
):
    """Update lab booking status / assign technician."""
    update_data = body.model_dump(exclude_none=True)
    result = sb.table("lab_bookings").update(update_data).eq("id", booking_id).execute()
    if not result.data:
        raise HTTPException(status_code=404, detail="Booking not found")

    # Notify patient on status change
    if body.status:
        booking = result.data[0]
        sb.table("notifications").insert({
            "user_id": booking["patient_id"],
            "title": "Lab Booking Update",
            "body": f"Your lab booking status is now: {body.status}",
            "notification_type": "lab_result",
            "data": {"lab_booking_id": booking_id, "status": body.status},
        }).execute()

    return result.data[0]


@router.post("/results/upload")
async def upload_lab_result(
    body: LabResultUpload,
    current_user: Annotated[dict, Depends(require_lab_admin)],
    sb: Annotated[Client, Depends(get_supabase_admin)],
    file: Optional[UploadFile] = File(None),
):
    """Upload lab result (PDF or data)."""
    result_data = {
        "lab_booking_id": body.lab_booking_id,
        "result_data": body.result_data,
        "remarks": body.remarks,
        "uploaded_by": current_user["id"],
    }

    # Upload PDF if provided
    if file:
        file_bytes = await file.read()
        file_path = f"{body.lab_booking_id}/{file.filename}"
        sb.storage.from_("lab-results").upload(
            path=file_path,
            file=file_bytes,
            file_options={"content-type": file.content_type or "application/pdf"}
        )
        result_data["result_pdf_url"] = sb.storage.from_("lab-results").get_public_url(file_path)

    result = sb.table("lab_results").insert(result_data).execute()

    # Update booking status
    sb.table("lab_bookings").update({"status": "completed"}).eq("id", body.lab_booking_id).execute()

    # Notify patient
    booking = sb.table("lab_bookings").select("patient_id").eq("id", body.lab_booking_id).single().execute()
    if booking.data:
        sb.table("notifications").insert({
            "user_id": booking.data["patient_id"],
            "title": "Lab Results Ready",
            "body": "Your lab test results are now available.",
            "notification_type": "lab_result",
            "data": {"lab_booking_id": body.lab_booking_id},
        }).execute()

    return result.data[0]


@router.get("/results/{booking_id}")
async def get_lab_results(
    booking_id: str,
    current_user: dict = Depends(get_current_user),
    sb: Client = Depends(get_supabase_admin),
):
    """Get lab results for a booking."""
    results = sb.table("lab_results").select("*").eq("lab_booking_id", booking_id).execute()
    return {"items": results.data or []}
