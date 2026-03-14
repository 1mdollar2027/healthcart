"""
Admin Router – Super admin dashboard: KYC verification, analytics, user management.
"""
from typing import Annotated, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from supabase import Client
from app.core.deps import get_supabase_admin
from app.core.security import require_super_admin
from app.models.schemas import MessageResponse

router = APIRouter()


@router.get("/dashboard")
async def admin_dashboard(
    current_user: Annotated[dict, Depends(require_super_admin)],
    sb: Annotated[Client, Depends(get_supabase_admin)],
):
    """Get admin dashboard analytics."""
    # Counts
    patients = sb.table("profiles").select("id", count="exact").eq("role", "patient").execute()
    doctors = sb.table("doctors").select("id", count="exact").execute()
    clinics = sb.table("clinics").select("id", count="exact").execute()
    labs_count = sb.table("labs").select("id", count="exact").execute()
    pharmacies = sb.table("pharmacies").select("id", count="exact").execute()
    appointments = sb.table("appointments").select("id", count="exact").execute()
    payments = sb.table("payments").select("amount").eq("status", "captured").execute()

    total_revenue = sum(p.get("amount", 0) for p in (payments.data or []))

    # Pending verifications
    pending_doctors = sb.table("doctors").select("id", count="exact").eq("verification_status", "pending").execute()
    pending_labs = sb.table("labs").select("id", count="exact").eq("verification_status", "pending").execute()
    pending_pharmacies = sb.table("pharmacies").select("id", count="exact").eq("verification_status", "pending").execute()

    return {
        "total_patients": patients.count or 0,
        "total_doctors": doctors.count or 0,
        "total_clinics": clinics.count or 0,
        "total_labs": labs_count.count or 0,
        "total_pharmacies": pharmacies.count or 0,
        "total_appointments": appointments.count or 0,
        "total_revenue": total_revenue,
        "pending_verifications": {
            "doctors": pending_doctors.count or 0,
            "labs": pending_labs.count or 0,
            "pharmacies": pending_pharmacies.count or 0,
        },
    }


@router.get("/pending-verifications")
async def pending_verifications(
    entity_type: str = Query(..., pattern="^(doctors|labs|pharmacies)$"),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=50),
    current_user: Annotated[dict, Depends(require_super_admin)] = None,
    sb: Client = Depends(get_supabase_admin),
):
    """List entities pending KYC verification."""
    if entity_type == "doctors":
        q = sb.table("doctors").select("*, profiles!inner(full_name, phone, email, city)").eq("verification_status", "pending")
    elif entity_type == "labs":
        q = sb.table("labs").select("*").eq("verification_status", "pending")
    else:
        q = sb.table("pharmacies").select("*").eq("verification_status", "pending")

    offset = (page - 1) * limit
    result = q.range(offset, offset + limit - 1).execute()
    return {"items": result.data or [], "page": page, "limit": limit}


@router.post("/verify/{entity_type}/{entity_id}")
async def verify_entity(
    entity_type: str,
    entity_id: str,
    action: str = Query(..., pattern="^(verified|rejected)$"),
    current_user: Annotated[dict, Depends(require_super_admin)] = None,
    sb: Client = Depends(get_supabase_admin),
):
    """Verify or reject a doctor/lab/pharmacy."""
    table_map = {"doctors": "doctors", "labs": "labs", "pharmacies": "pharmacies"}
    table = table_map.get(entity_type)
    if not table:
        raise HTTPException(status_code=400, detail="Invalid entity type")

    result = sb.table(table).update({"verification_status": action}).eq("id", entity_id).execute()
    if not result.data:
        raise HTTPException(status_code=404, detail="Entity not found")

    # Notify the entity admin
    entity = result.data[0]
    notify_user_id = entity.get("profile_id") or entity.get("admin_profile_id")
    if notify_user_id:
        sb.table("notifications").insert({
            "user_id": notify_user_id,
            "title": f"Verification {action.title()}",
            "body": f"Your {entity_type[:-1]} profile has been {action}.",
            "notification_type": "general",
        }).execute()

    # Audit log
    sb.table("audit_logs").insert({
        "user_id": current_user["id"],
        "action": f"verify_{entity_type}",
        "resource_type": entity_type,
        "resource_id": entity_id,
        "details": {"status": action},
    }).execute()

    return MessageResponse(message=f"{entity_type[:-1].title()} {action} successfully")


@router.get("/users")
async def list_users(
    role: Optional[str] = None,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=50),
    current_user: Annotated[dict, Depends(require_super_admin)] = None,
    sb: Client = Depends(get_supabase_admin),
):
    """List all users with optional role filter."""
    q = sb.table("profiles").select("*")
    if role:
        q = q.eq("role", role)
    offset = (page - 1) * limit
    result = q.order("created_at", desc=True).range(offset, offset + limit - 1).execute()
    return {"items": result.data or [], "page": page, "limit": limit}


@router.get("/audit-logs")
async def get_audit_logs(
    resource_type: Optional[str] = None,
    page: int = Query(1, ge=1),
    limit: int = Query(50, ge=1, le=100),
    current_user: Annotated[dict, Depends(require_super_admin)] = None,
    sb: Client = Depends(get_supabase_admin),
):
    """View audit logs."""
    q = sb.table("audit_logs").select("*, profiles!inner(full_name)")
    if resource_type:
        q = q.eq("resource_type", resource_type)
    offset = (page - 1) * limit
    result = q.order("created_at", desc=True).range(offset, offset + limit - 1).execute()
    return {"items": result.data or [], "page": page, "limit": limit}
