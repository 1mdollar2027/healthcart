"""
Notifications Router – List, mark read.
"""
from typing import Annotated
from fastapi import APIRouter, Depends, Query
from supabase import Client
from app.core.deps import get_supabase_admin
from app.core.security import get_current_user
from app.models.schemas import MessageResponse

router = APIRouter()


@router.get("/")
async def list_notifications(
    unread_only: bool = False,
    page: int = Query(1, ge=1),
    limit: int = Query(30, ge=1, le=50),
    current_user: dict = Depends(get_current_user),
    sb: Client = Depends(get_supabase_admin),
):
    """List notifications for current user."""
    q = sb.table("notifications").select("*").eq("user_id", current_user["id"])
    if unread_only:
        q = q.eq("is_read", False)
    offset = (page - 1) * limit
    result = q.order("created_at", desc=True).range(offset, offset + limit - 1).execute()

    # Count unread
    unread = sb.table("notifications").select("id", count="exact").eq(
        "user_id", current_user["id"]
    ).eq("is_read", False).execute()

    return {
        "items": result.data or [],
        "unread_count": unread.count or 0,
        "page": page,
        "limit": limit,
    }


@router.post("/{notification_id}/read", response_model=MessageResponse)
async def mark_read(
    notification_id: str,
    current_user: dict = Depends(get_current_user),
    sb: Client = Depends(get_supabase_admin),
):
    """Mark a notification as read."""
    sb.table("notifications").update({"is_read": True}).eq(
        "id", notification_id
    ).eq("user_id", current_user["id"]).execute()
    return MessageResponse(message="Marked as read")


@router.post("/read-all", response_model=MessageResponse)
async def mark_all_read(
    current_user: dict = Depends(get_current_user),
    sb: Client = Depends(get_supabase_admin),
):
    """Mark all notifications as read."""
    sb.table("notifications").update({"is_read": True}).eq(
        "user_id", current_user["id"]
    ).eq("is_read", False).execute()
    return MessageResponse(message="All notifications marked as read")
