"""
Prescriptions Router – Create, list, generate PDF.
"""
from typing import Annotated, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from supabase import Client
from app.core.deps import get_supabase_admin
from app.core.security import get_current_user, require_doctor
from app.services.pdf_service import generate_prescription_pdf
from app.models.schemas import PrescriptionCreate, PrescriptionResponse, MessageResponse

router = APIRouter()


@router.post("/", response_model=PrescriptionResponse)
async def create_prescription(
    body: PrescriptionCreate,
    current_user: Annotated[dict, Depends(require_doctor)],
    sb: Annotated[Client, Depends(get_supabase_admin)],
):
    """Create a prescription with medicines (doctor action)."""
    # Get doctor record
    doctor = sb.table("doctors").select("id, profiles!inner(full_name)").eq(
        "profile_id", current_user["id"]
    ).single().execute()
    if not doctor.data:
        raise HTTPException(status_code=404, detail="Doctor profile not found")

    doctor_id = doctor.data["id"]
    doctor_name = doctor.data.get("profiles", {}).get("full_name", "Doctor")

    # Get patient name
    patient = sb.table("profiles").select("full_name, phone").eq(
        "id", body.patient_id
    ).single().execute()
    patient_name = patient.data.get("full_name", "Patient") if patient.data else "Patient"

    # Create prescription
    rx_data = {
        "consultation_id": body.consultation_id,
        "patient_id": body.patient_id,
        "doctor_id": doctor_id,
        "diagnosis": body.diagnosis,
        "notes": body.notes,
        "advice": body.advice,
        "follow_up_date": body.follow_up_date.isoformat() if body.follow_up_date else None,
    }
    rx_result = sb.table("prescriptions").insert(rx_data).execute()
    rx_id = rx_result.data[0]["id"]

    # Insert items
    items_data = [{"prescription_id": rx_id, **item.model_dump()} for item in body.items]
    sb.table("prescription_items").insert(items_data).execute()

    # Generate PDF
    pdf_bytes = generate_prescription_pdf(
        prescription_id=rx_id,
        doctor_name=doctor_name,
        patient_name=patient_name,
        diagnosis=body.diagnosis or "",
        advice=body.advice or "",
        items=[item.model_dump() for item in body.items],
        follow_up_date=body.follow_up_date,
    )

    # Upload PDF to Supabase Storage
    pdf_path = f"prescriptions/{rx_id}.pdf"
    sb.storage.from_("prescriptions").upload(
        path=f"{rx_id}.pdf",
        file=pdf_bytes,
        file_options={"content-type": "application/pdf"}
    )
    pdf_url = sb.storage.from_("prescriptions").get_public_url(f"{rx_id}.pdf")

    # Update prescription with PDF URL
    sb.table("prescriptions").update({"pdf_url": pdf_url}).eq("id", rx_id).execute()

    # Audit log
    sb.table("audit_logs").insert({
        "user_id": current_user["id"],
        "action": "create_prescription",
        "resource_type": "prescriptions",
        "resource_id": rx_id,
        "details": {"patient_id": body.patient_id, "items_count": len(body.items)},
    }).execute()

    # Send notification to patient
    sb.table("notifications").insert({
        "user_id": body.patient_id,
        "title": "New Prescription",
        "body": f"Dr. {doctor_name} has sent you a prescription.",
        "notification_type": "prescription",
        "data": {"prescription_id": rx_id, "pdf_url": pdf_url},
    }).execute()

    return PrescriptionResponse(
        id=rx_id,
        patient_id=body.patient_id,
        doctor_id=doctor_id,
        diagnosis=body.diagnosis,
        notes=body.notes,
        advice=body.advice,
        follow_up_date=body.follow_up_date,
        pdf_url=pdf_url,
        items=[item.model_dump() for item in body.items],
        doctor_name=doctor_name,
    )


@router.get("/")
async def list_prescriptions(
    patient_id: Optional[str] = None,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=50),
    current_user: dict = Depends(get_current_user),
    sb: Client = Depends(get_supabase_admin),
):
    """List prescriptions (patient sees own, doctor sees sent)."""
    profile = sb.table("profiles").select("role").eq("id", current_user["id"]).single().execute()
    role = profile.data["role"]

    if role == "patient":
        q = sb.table("prescriptions").select(
            "*, doctors!inner(profiles!inner(full_name))"
        ).eq("patient_id", current_user["id"])
    elif role == "doctor":
        doctor = sb.table("doctors").select("id").eq("profile_id", current_user["id"]).single().execute()
        q = sb.table("prescriptions").select(
            "*, profiles!inner(full_name)"
        ).eq("doctor_id", doctor.data["id"])
        if patient_id:
            q = q.eq("patient_id", patient_id)
    else:
        raise HTTPException(status_code=403, detail="Not authorized")

    offset = (page - 1) * limit
    result = q.order("created_at", desc=True).range(offset, offset + limit - 1).execute()

    return {"items": result.data or [], "page": page, "limit": limit}


@router.get("/{prescription_id}")
async def get_prescription(
    prescription_id: str,
    current_user: dict = Depends(get_current_user),
    sb: Client = Depends(get_supabase_admin),
):
    """Get prescription with items."""
    rx = sb.table("prescriptions").select("*").eq("id", prescription_id).single().execute()
    if not rx.data:
        raise HTTPException(status_code=404, detail="Prescription not found")

    items = sb.table("prescription_items").select("*").eq("prescription_id", prescription_id).execute()
    rx.data["items"] = items.data or []

    # Get doctor and patient names
    doctor = sb.table("doctors").select("profiles!inner(full_name)").eq("id", rx.data["doctor_id"]).single().execute()
    patient = sb.table("profiles").select("full_name").eq("id", rx.data["patient_id"]).single().execute()

    rx.data["doctor_name"] = doctor.data.get("profiles", {}).get("full_name") if doctor.data else None
    rx.data["patient_name"] = patient.data.get("full_name") if patient.data else None

    return rx.data
