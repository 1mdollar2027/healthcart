"""
Agora RTC Token Service – Generate tokens for video consultations.
Uses the Agora token builder algorithm (RtcTokenBuilder).
"""
import time
import hmac
import hashlib
import struct
import base64
import os
from app.core.config import get_settings

settings = get_settings()

# Agora privileges
PRIVILEGE_JOIN_CHANNEL = 1
PRIVILEGE_PUBLISH_AUDIO = 2
PRIVILEGE_PUBLISH_VIDEO = 3
PRIVILEGE_PUBLISH_DATA = 4


def _pack_uint16(val):
    return struct.pack('<H', val)


def _pack_uint32(val):
    return struct.pack('<I', val)


def _pack_string(val):
    encoded = val.encode('utf-8') if isinstance(val, str) else val
    return _pack_uint16(len(encoded)) + encoded


def _pack_map(m):
    ret = _pack_uint16(len(m))
    for k, v in m.items():
        ret += _pack_uint16(k) + _pack_uint32(v)
    return ret


def generate_agora_token(channel_name: str, uid: int, expire_seconds: int = 3600) -> str:
    """
    Generate an Agora RTC token for joining a video channel.

    Args:
        channel_name: Unique channel name for the consultation
        uid: Numeric user ID (1=patient, 2=doctor)
        expire_seconds: Token expiry in seconds (default 1 hour)

    Returns:
        Token string for Agora SDK
    """
    app_id = settings.AGORA_APP_ID
    app_certificate = settings.AGORA_APP_CERTIFICATE

    if not app_id or not app_certificate:
        # Return a dev placeholder token
        return f"dev_token_{channel_name}_{uid}_{int(time.time())}"

    now = int(time.time())
    expired_ts = now + expire_seconds

    # Build privileges map
    privileges = {
        PRIVILEGE_JOIN_CHANNEL: expired_ts,
        PRIVILEGE_PUBLISH_AUDIO: expired_ts,
        PRIVILEGE_PUBLISH_VIDEO: expired_ts,
        PRIVILEGE_PUBLISH_DATA: expired_ts,
    }

    # Pack message
    message = _pack_uint32(0)  # salt (we'll use 0 for simplicity)
    message += _pack_uint32(now)
    message += _pack_uint32(expired_ts)
    message += _pack_map(privileges)

    # Sign
    val = app_id.encode('utf-8') + channel_name.encode('utf-8') + str(uid).encode('utf-8') + message
    signature = hmac.new(app_certificate.encode('utf-8'), val, hashlib.sha256).digest()

    # Pack content
    content = _pack_string(signature)
    content += _pack_uint32(0)  # crc_channel
    content += _pack_uint32(0)  # crc_uid
    content += _pack_string(message)

    # Final token
    version = "007"
    token = f"{version}{app_id}{base64.b64encode(content).decode('utf-8')}"

    return token
