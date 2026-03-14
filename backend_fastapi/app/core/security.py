"""
HealthCart Backend – Security utilities
JWT verification, role guards, rate limiting.
"""
from datetime import datetime, timedelta, timezone
from typing import Annotated
from jose import JWTError, jwt
from fastapi import Depends, HTTPException, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from supabase import Client
from app.core.config import get_settings, Settings
from app.core.deps import get_supabase_admin

security_scheme = HTTPBearer()
settings = get_settings()


def verify_jwt(token: str) -> dict:
    """Verify a Supabase JWT and return the payload."""
    try:
        payload = jwt.decode(
            token,
            settings.SUPABASE_JWT_SECRET,
            algorithms=[settings.JWT_ALGORITHM],
            audience="authenticated",
        )
        return payload
    except JWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid authentication token: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(security_scheme)],
) -> dict:
    """Extract and verify the current user from the Bearer token."""
    payload = verify_jwt(credentials.credentials)
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token: missing user ID",
        )
    return {
        "id": user_id,
        "email": payload.get("email"),
        "role": payload.get("user_metadata", {}).get("role", "patient"),
        "token": credentials.credentials,
    }


class RoleChecker:
    """FastAPI dependency for role-based access control."""

    def __init__(self, allowed_roles: list[str]):
        self.allowed_roles = allowed_roles

    async def __call__(
        self,
        current_user: Annotated[dict, Depends(get_current_user)],
        sb: Annotated[Client, Depends(get_supabase_admin)],
    ) -> dict:
        # Fetch role from profiles table (source of truth)
        result = sb.table("profiles").select("role").eq("id", current_user["id"]).single().execute()
        if not result.data:
            raise HTTPException(status_code=404, detail="User profile not found")

        user_role = result.data["role"]
        if user_role not in self.allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access denied. Required roles: {self.allowed_roles}",
            )
        current_user["role"] = user_role
        return current_user


# Pre-built role checkers
require_patient = RoleChecker(["patient"])
require_doctor = RoleChecker(["doctor"])
require_clinic_admin = RoleChecker(["clinic_admin"])
require_lab_admin = RoleChecker(["lab_admin", "lab_technician"])
require_pharmacy_admin = RoleChecker(["pharmacy_admin"])
require_super_admin = RoleChecker(["super_admin"])
require_any_admin = RoleChecker(["clinic_admin", "lab_admin", "pharmacy_admin", "super_admin"])
require_authenticated = RoleChecker(
    ["patient", "doctor", "clinic_admin", "lab_admin", "lab_technician", "pharmacy_admin", "super_admin"]
)
