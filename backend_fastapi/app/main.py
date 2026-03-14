"""
HealthCart Telemedicine Platform – FastAPI Backend
Production-ready async API server.
"""
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

from app.core.config import get_settings
from app.api.routers import (
    auth,
    bookings,
    consultations,
    prescriptions,
    labs,
    pharmacies,
    clinics,
    vitals,
    payments,
    admin,
    notifications,
)

settings = get_settings()
limiter = Limiter(key_func=get_remote_address, default_limits=[settings.RATE_LIMIT])


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup & shutdown lifecycle."""
    print(f"🚀 {settings.APP_NAME} v{settings.APP_VERSION} starting...")
    yield
    print("👋 Shutting down...")


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="Production telemedicine platform API for India",
    docs_url=f"{settings.API_PREFIX}/docs",
    redoc_url=f"{settings.API_PREFIX}/redoc",
    openapi_url=f"{settings.API_PREFIX}/openapi.json",
    lifespan=lifespan,
)

# Rate limiting
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Health check
@app.get("/health")
async def health_check():
    return {"status": "healthy", "app": settings.APP_NAME, "version": settings.APP_VERSION}


# Mount routers
PREFIX = settings.API_PREFIX
app.include_router(auth.router, prefix=f"{PREFIX}/auth", tags=["Authentication"])
app.include_router(bookings.router, prefix=f"{PREFIX}/bookings", tags=["Bookings"])
app.include_router(consultations.router, prefix=f"{PREFIX}/consultations", tags=["Consultations"])
app.include_router(prescriptions.router, prefix=f"{PREFIX}/prescriptions", tags=["Prescriptions"])
app.include_router(labs.router, prefix=f"{PREFIX}/labs", tags=["Labs"])
app.include_router(pharmacies.router, prefix=f"{PREFIX}/pharmacies", tags=["Pharmacies"])
app.include_router(clinics.router, prefix=f"{PREFIX}/clinics", tags=["Clinics"])
app.include_router(vitals.router, prefix=f"{PREFIX}/vitals", tags=["Vitals & IoT"])
app.include_router(payments.router, prefix=f"{PREFIX}/payments", tags=["Payments"])
app.include_router(admin.router, prefix=f"{PREFIX}/admin", tags=["Admin"])
app.include_router(notifications.router, prefix=f"{PREFIX}/notifications", tags=["Notifications"])
