"""
SMS Service – MSG91 OTP send/verify for Indian phone numbers.
"""
import httpx
from app.core.config import get_settings

settings = get_settings()
MSG91_BASE = "https://control.msg91.com/api/v5"


async def send_otp(phone: str) -> dict:
    """
    Send OTP via MSG91.
    Note: In production, use Supabase Auth phone OTP as primary.
    This is a backup/direct OTP service.
    """
    if not settings.MSG91_AUTH_KEY:
        return {"type": "dev", "message": "MSG91 not configured, using dev mode"}

    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{MSG91_BASE}/otp",
            params={
                "template_id": settings.MSG91_TEMPLATE_ID,
                "mobile": phone.replace("+", ""),
                "authkey": settings.MSG91_AUTH_KEY,
                "otp_length": "6",
            },
        )
        return response.json()


async def verify_otp(phone: str, otp: str) -> bool:
    """Verify OTP via MSG91."""
    if not settings.MSG91_AUTH_KEY:
        return otp == "123456"  # Dev mode verification

    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{MSG91_BASE}/otp/verify",
            params={
                "mobile": phone.replace("+", ""),
                "otp": otp,
                "authkey": settings.MSG91_AUTH_KEY,
            },
        )
        data = response.json()
        return data.get("type") == "success"


async def send_sms(phone: str, message: str) -> dict:
    """Send a transactional SMS via MSG91."""
    if not settings.MSG91_AUTH_KEY:
        return {"type": "dev", "message": "SMS not sent (dev mode)"}

    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{MSG91_BASE}/flow",
            headers={"authkey": settings.MSG91_AUTH_KEY, "Content-Type": "application/json"},
            json={
                "sender": settings.MSG91_SENDER_ID,
                "route": "4",
                "country": "91",
                "sms": [{"message": message, "to": [phone.replace("+91", "")]}],
            },
        )
        return response.json()
