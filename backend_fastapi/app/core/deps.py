"""
HealthCart Backend – Dependency injection
Supabase client factories, common deps.
"""
from typing import Annotated
from functools import lru_cache
from fastapi import Depends
from supabase import create_client, Client
from app.core.config import get_settings, Settings


@lru_cache()
def get_supabase_admin() -> Client:
    """Supabase client with service_role key (bypasses RLS) for admin operations."""
    s = get_settings()
    return create_client(s.SUPABASE_URL, s.SUPABASE_SERVICE_ROLE_KEY)


def get_supabase_client(token: str | None = None) -> Client:
    """Supabase client with anon key (respects RLS). Optionally pass user JWT."""
    s = get_settings()
    client = create_client(s.SUPABASE_URL, s.SUPABASE_ANON_KEY)
    if token:
        client.auth.set_session(token, "")
    return client


# Type alias for injection
SupabaseAdmin = Annotated[Client, Depends(get_supabase_admin)]
