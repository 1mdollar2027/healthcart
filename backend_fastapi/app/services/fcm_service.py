"""
FCM Service – Firebase Cloud Messaging push notifications.
"""
import firebase_admin
from firebase_admin import credentials, messaging
from app.core.config import get_settings

settings = get_settings()
_initialized = False


def _init_firebase():
    global _initialized
    if _initialized:
        return
    if settings.FIREBASE_CREDENTIALS_PATH:
        cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
        firebase_admin.initialize_app(cred)
        _initialized = True


async def send_push_notification(
    fcm_token: str,
    title: str,
    body: str,
    data: dict | None = None,
) -> bool:
    """
    Send a push notification via FCM.

    Args:
        fcm_token: Device FCM registration token
        title: Notification title
        body: Notification body
        data: Optional data payload

    Returns:
        True if sent successfully, False otherwise
    """
    try:
        _init_firebase()
    except Exception:
        print(f"[FCM] Firebase not initialized, skipping push: {title}")
        return False

    if not fcm_token:
        return False

    try:
        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data={k: str(v) for k, v in (data or {}).items()},
            token=fcm_token,
            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    channel_id="healthcart_notifications",
                    priority="high",
                    sound="default",
                ),
            ),
        )
        response = messaging.send(message)
        print(f"[FCM] Sent: {response}")
        return True
    except Exception as e:
        print(f"[FCM] Error sending push: {e}")
        return False


async def send_push_to_user(user_id: str, title: str, body: str, data: dict = None, sb=None):
    """Send push to a user by looking up their FCM token."""
    if not sb:
        return False
    result = sb.table("profiles").select("fcm_token").eq("id", user_id).single().execute()
    if result.data and result.data.get("fcm_token"):
        return await send_push_notification(result.data["fcm_token"], title, body, data)
    return False
