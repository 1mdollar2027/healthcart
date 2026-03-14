"""
Vitals Router – IoT data ingestion, history, alert rules.
"""
from typing import Annotated, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from supabase import Client
from app.core.deps import get_supabase_admin
from app.core.security import get_current_user
from app.services.alert_service import check_vital_alerts
from app.models.schemas import VitalCreate, VitalBatchCreate, MessageResponse

router = APIRouter()


@router.post("/record", response_model=MessageResponse)
async def record_vital(
    body: VitalCreate,
    current_user: Annotated[dict, Depends(get_current_user)],
    sb: Annotated[Client, Depends(get_supabase_admin)],
):
    """Record a single vital reading."""
    vital_data = {
        "patient_id": current_user["id"],
        "vital_type": body.vital_type,
        "value": body.value,
        "unit": body.unit,
        "device_id": body.device_id,
    }
    sb.table("vitals").insert(vital_data).execute()

    # Check alert rules
    alerts = check_vital_alerts(body.vital_type, body.value)
    if alerts:
        for alert in alerts:
            sb.table("notifications").insert({
                "user_id": current_user["id"],
                "title": alert["title"],
                "body": alert["body"],
                "notification_type": "vital_alert",
                "data": {"vital_type": body.vital_type, "value": body.value, "severity": alert["severity"]},
            }).execute()

    return MessageResponse(
        message="Vital recorded",
        data={"alerts": alerts} if alerts else None,
    )


@router.post("/batch", response_model=MessageResponse)
async def record_vitals_batch(
    body: VitalBatchCreate,
    current_user: Annotated[dict, Depends(get_current_user)],
    sb: Annotated[Client, Depends(get_supabase_admin)],
):
    """Record multiple vital readings (IoT batch upload)."""
    records = [{
        "patient_id": current_user["id"],
        "vital_type": r.vital_type,
        "value": r.value,
        "unit": r.unit,
        "device_id": r.device_id,
    } for r in body.readings]

    sb.table("vitals").insert(records).execute()

    # Check alerts for all readings
    all_alerts = []
    for r in body.readings:
        alerts = check_vital_alerts(r.vital_type, r.value)
        all_alerts.extend(alerts)

    # Send alert notifications
    for alert in all_alerts:
        sb.table("notifications").insert({
            "user_id": current_user["id"],
            "title": alert["title"],
            "body": alert["body"],
            "notification_type": "vital_alert",
            "data": {"severity": alert["severity"]},
        }).execute()

    return MessageResponse(
        message=f"Recorded {len(body.readings)} readings",
        data={"alert_count": len(all_alerts)},
    )


@router.get("/history")
async def get_vital_history(
    vital_type: Optional[str] = None,
    days: int = Query(30, ge=1, le=365),
    current_user: dict = Depends(get_current_user),
    sb: Client = Depends(get_supabase_admin),
):
    """Get vital history for current patient."""
    from datetime import datetime, timedelta, timezone
    since = (datetime.now(timezone.utc) - timedelta(days=days)).isoformat()

    q = sb.table("vitals").select("*").eq("patient_id", current_user["id"]).gte("recorded_at", since)
    if vital_type:
        q = q.eq("vital_type", vital_type)

    result = q.order("recorded_at", desc=True).limit(500).execute()
    return {"items": result.data or [], "days": days}


@router.get("/patient/{patient_id}/history")
async def get_patient_vitals(
    patient_id: str,
    vital_type: Optional[str] = None,
    days: int = Query(30, ge=1, le=365),
    current_user: dict = Depends(get_current_user),
    sb: Client = Depends(get_supabase_admin),
):
    """Get patient vitals (doctor view)."""
    from datetime import datetime, timedelta, timezone
    since = (datetime.now(timezone.utc) - timedelta(days=days)).isoformat()

    q = sb.table("vitals").select("*").eq("patient_id", patient_id).gte("recorded_at", since)
    if vital_type:
        q = q.eq("vital_type", vital_type)

    result = q.order("recorded_at", desc=True).limit(500).execute()
    return {"items": result.data or [], "days": days}


@router.get("/latest")
async def get_latest_vitals(
    current_user: dict = Depends(get_current_user),
    sb: Client = Depends(get_supabase_admin),
):
    """Get latest reading for each vital type."""
    vital_types = [
        "blood_pressure_systolic", "blood_pressure_diastolic",
        "heart_rate", "blood_glucose", "spo2", "temperature", "weight"
    ]
    latest = {}
    for vt in vital_types:
        result = sb.table("vitals").select("*").eq(
            "patient_id", current_user["id"]
        ).eq("vital_type", vt).order("recorded_at", desc=True).limit(1).execute()
        if result.data:
            latest[vt] = result.data[0]

    return {"vitals": latest}


@router.post("/simulate-iot", response_model=MessageResponse)
async def simulate_iot_reading(
    current_user: Annotated[dict, Depends(get_current_user)],
    sb: Annotated[Client, Depends(get_supabase_admin)],
):
    """Simulate IoT device readings (for testing). Generates random vitals including some critical values."""
    import random

    simulated = [
        {"vital_type": "blood_pressure_systolic", "value": random.choice([120, 130, 145, 170, 180]), "unit": "mmHg"},
        {"vital_type": "blood_pressure_diastolic", "value": random.choice([80, 85, 90, 105, 110]), "unit": "mmHg"},
        {"vital_type": "heart_rate", "value": random.choice([72, 80, 88, 95, 110, 120]), "unit": "bpm"},
        {"vital_type": "blood_glucose", "value": random.choice([90, 110, 140, 180, 220, 280]), "unit": "mg/dL"},
        {"vital_type": "spo2", "value": random.choice([98, 97, 95, 93, 90, 88]), "unit": "%"},
        {"vital_type": "temperature", "value": random.choice([97.5, 98.2, 98.6, 99.5, 100.4, 102.0]), "unit": "°F"},
    ]

    all_alerts = []
    for reading in simulated:
        sb.table("vitals").insert({
            "patient_id": current_user["id"],
            **reading,
            "device_id": "sim_iot_v1",
        }).execute()
        alerts = check_vital_alerts(reading["vital_type"], reading["value"])
        all_alerts.extend(alerts)

    # Send alerts
    for alert in all_alerts:
        sb.table("notifications").insert({
            "user_id": current_user["id"],
            "title": alert["title"],
            "body": alert["body"],
            "notification_type": "vital_alert",
            "data": {"severity": alert["severity"]},
        }).execute()

    return MessageResponse(
        message=f"Simulated {len(simulated)} readings, {len(all_alerts)} alerts triggered",
        data={"readings": simulated, "alerts": all_alerts},
    )
