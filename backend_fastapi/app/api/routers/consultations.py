"""
Consultations Router – Video session management with Agora token gen.
"""
from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException
from supabase import Client
from app.core.deps import get_supabase_admin
from app.core.security import get_current_user
from app.services.agora_service import generate_agora_token
from app.models.schemas import ConsultationCreate, ConsultationEnd, MessageResponse
import uuid

router = APIRouter()


@router.post("/start")
async def start_consultation(
    body: ConsultationCreate,
    current_user: Annotated[dict, Depends(get_current_user)],
    sb: Annotated[Client, Depends(get_supabase_admin)],
):
    """Start a video consultation – generates Agora tokens for both parties."""
    # Verify appointment exists and is confirmed
    appt = sb.table("appointments").select("*").eq("id", body.appointment_id).single().execute()
    if not appt.data:
        raise HTTPException(status_code=404, detail="Appointment not found")
    if appt.data["status"] not in ("confirmed", "pending"):
        raise HTTPException(status_code=400, detail=f"Cannot start consultation for {appt.data['status']} appointment")

    # Generate unique channel name
    channel_name = f"hc_{body.appointment_id[:8]}_{uuid.uuid4().hex[:6]}"

    # Generate Agora tokens
    patient_uid = 1
    doctor_uid = 2
    token_patient = generate_agora_token(channel_name, patient_uid)
    token_doctor = generate_agora_token(channel_name, doctor_uid)

    # Create consultation record
    consultation_data = {
        "appointment_id": body.appointment_id,
        "agora_channel_name": channel_name,
        "agora_token_patient": token_patient,
        "agora_token_doctor": token_doctor,
        "started_at": "now()",
    }
    result = sb.table("consultations").insert(consultation_data).execute()

    # Update appointment status
    sb.table("appointments").update({"status": "in_progress"}).eq("id", body.appointment_id).execute()

    # Audit log
    sb.table("audit_logs").insert({
        "user_id": current_user["id"],
        "action": "start_consultation",
        "resource_type": "consultations",
        "resource_id": result.data[0]["id"],
        "details": {"channel": channel_name, "appointment_id": body.appointment_id},
    }).execute()

    return {
        "consultation_id": result.data[0]["id"],
        "channel_name": channel_name,
        "agora_token": token_patient if current_user["id"] == appt.data["patient_id"] else token_doctor,
        "agora_uid": patient_uid if current_user["id"] == appt.data["patient_id"] else doctor_uid,
    }


@router.get("/{consultation_id}/token")
async def get_consultation_token(
    consultation_id: str,
    current_user: Annotated[dict, Depends(get_current_user)],
    sb: Annotated[Client, Depends(get_supabase_admin)],
):
    """Get Agora token for joining an existing consultation."""
    consultation = sb.table("consultations").select(
        "*, appointments!inner(patient_id, doctor_id)"
    ).eq("id", consultation_id).single().execute()

    if not consultation.data:
        raise HTTPException(status_code=404, detail="Consultation not found")

    appt = consultation.data.get("appointments", {})
    is_patient = current_user["id"] == appt.get("patient_id")
    is_doctor_profile = current_user["id"] == appt.get("doctor_id")

    # Also check if user is the doctor via doctors table
    if not is_patient and not is_doctor_profile:
        doctor_check = sb.table("doctors").select("id").eq(
            "profile_id", current_user["id"]
        ).eq("id", appt.get("doctor_id")).maybe_single().execute()
        is_doctor_profile = doctor_check.data is not None

    if not is_patient and not is_doctor_profile:
        raise HTTPException(status_code=403, detail="Not authorized for this consultation")

    return {
        "channel_name": consultation.data["agora_channel_name"],
        "agora_token": consultation.data["agora_token_patient"] if is_patient else consultation.data["agora_token_doctor"],
        "agora_uid": 1 if is_patient else 2,
    }


@router.post("/{consultation_id}/end", response_model=MessageResponse)
async def end_consultation(
    consultation_id: str,
    body: ConsultationEnd,
    current_user: Annotated[dict, Depends(get_current_user)],
    sb: Annotated[Client, Depends(get_supabase_admin)],
):
    """End a video consultation."""
    update_data = {
        "ended_at": "now()",
        "doctor_notes": body.doctor_notes,
        "diagnosis": body.diagnosis,
    }
    result = sb.table("consultations").update(update_data).eq("id", consultation_id).execute()
    if not result.data:
        raise HTTPException(status_code=404, detail="Consultation not found")

    # Update appointment
    consultation = result.data[0]
    sb.table("appointments").update({"status": "completed"}).eq(
        "id", consultation["appointment_id"]
    ).execute()

    # Update doctor stats
    appt = sb.table("appointments").select("doctor_id").eq(
        "id", consultation["appointment_id"]
    ).single().execute()
    if appt.data:
        sb.rpc("increment_doctor_consultations", {"d_id": appt.data["doctor_id"]}).execute()

    # Audit log
    sb.table("audit_logs").insert({
        "user_id": current_user["id"],
        "action": "end_consultation",
        "resource_type": "consultations",
        "resource_id": consultation_id,
    }).execute()

    return MessageResponse(message="Consultation ended successfully")
