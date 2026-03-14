"""
Auth Router – Phone OTP login, profile management, consent.
"""
from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException, status
from supabase import Client
from app.core.deps import get_supabase_admin
from app.core.security import get_current_user
from app.models.schemas import (
    OTPRequest, OTPVerify, ProfileCreate, ProfileUpdate,
    ProfileResponse, ConsentCreate, MessageResponse
)

router = APIRouter()


@router.post("/send-otp", response_model=MessageResponse)
async def send_otp(
    body: OTPRequest,
    sb: Annotated[Client, Depends(get_supabase_admin)],
):
    """Send OTP to phone number via Supabase Auth (phone provider)."""
    try:
        result = sb.auth.sign_in_with_otp({"phone": body.phone})
        return MessageResponse(message="OTP sent successfully", data={"phone": body.phone})
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to send OTP: {str(e)}")


@router.post("/verify-otp")
async def verify_otp(
    body: OTPVerify,
    sb: Annotated[Client, Depends(get_supabase_admin)],
):
    """Verify OTP and return session tokens."""
    try:
        result = sb.auth.verify_otp({"phone": body.phone, "token": body.otp, "type": "sms"})
        session = result.session
        if not session:
            raise HTTPException(status_code=401, detail="OTP verification failed")

        # Check if profile exists
        profile = sb.table("profiles").select("*").eq("id", session.user.id).maybe_single().execute()

        return {
            "access_token": session.access_token,
            "refresh_token": session.refresh_token,
            "expires_in": session.expires_in,
            "user_id": session.user.id,
            "is_new_user": profile.data is None,
            "profile": profile.data,
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"OTP verification failed: {str(e)}")


@router.post("/profile", response_model=ProfileResponse)
async def create_profile(
    body: ProfileCreate,
    current_user: Annotated[dict, Depends(get_current_user)],
    sb: Annotated[Client, Depends(get_supabase_admin)],
):
    """Create user profile after first login (role selection)."""
    # Check if profile already exists
    existing = sb.table("profiles").select("id").eq("id", current_user["id"]).maybe_single().execute()
    if existing.data:
        raise HTTPException(status_code=409, detail="Profile already exists")

    profile_data = {
        "id": current_user["id"],
        **body.model_dump(exclude_none=True),
    }
    result = sb.table("profiles").insert(profile_data).execute()

    # Create role-specific record
    if body.role == "patient":
        sb.table("patients").insert({"profile_id": current_user["id"]}).execute()

    # Update user metadata in auth
    sb.auth.admin.update_user_by_id(
        current_user["id"],
        {"user_metadata": {"role": body.role.value, "full_name": body.full_name}}
    )

    return ProfileResponse(**result.data[0])


@router.get("/profile", response_model=ProfileResponse)
async def get_profile(
    current_user: Annotated[dict, Depends(get_current_user)],
    sb: Annotated[Client, Depends(get_supabase_admin)],
):
    """Get current user's profile."""
    result = sb.table("profiles").select("*").eq("id", current_user["id"]).single().execute()
    if not result.data:
        raise HTTPException(status_code=404, detail="Profile not found")
    return ProfileResponse(**result.data)


@router.patch("/profile", response_model=ProfileResponse)
async def update_profile(
    body: ProfileUpdate,
    current_user: Annotated[dict, Depends(get_current_user)],
    sb: Annotated[Client, Depends(get_supabase_admin)],
):
    """Update current user's profile."""
    update_data = body.model_dump(exclude_none=True)
    if not update_data:
        raise HTTPException(status_code=400, detail="No fields to update")

    result = sb.table("profiles").update(update_data).eq("id", current_user["id"]).execute()
    return ProfileResponse(**result.data[0])


@router.post("/refresh")
async def refresh_token(
    refresh_token: str,
    sb: Annotated[Client, Depends(get_supabase_admin)],
):
    """Refresh access token."""
    try:
        result = sb.auth.refresh_session(refresh_token)
        session = result.session
        return {
            "access_token": session.access_token,
            "refresh_token": session.refresh_token,
            "expires_in": session.expires_in,
        }
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Token refresh failed: {str(e)}")


@router.post("/consent", response_model=MessageResponse)
async def record_consent(
    body: ConsentCreate,
    current_user: Annotated[dict, Depends(get_current_user)],
    sb: Annotated[Client, Depends(get_supabase_admin)],
):
    """Record user consent (DPDP compliance)."""
    sb.table("consent_records").insert({
        "user_id": current_user["id"],
        **body.model_dump(),
    }).execute()

    if body.consented and body.consent_type == "data_processing":
        sb.table("profiles").update({
            "consent_given": True,
            "consent_given_at": "now()",
        }).eq("id", current_user["id"]).execute()

    return MessageResponse(message="Consent recorded successfully")


@router.post("/logout", response_model=MessageResponse)
async def logout(
    current_user: Annotated[dict, Depends(get_current_user)],
):
    """Logout (client should discard tokens)."""
    return MessageResponse(message="Logged out successfully")
