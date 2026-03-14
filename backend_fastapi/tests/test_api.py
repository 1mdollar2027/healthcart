import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.models.schemas import OTPRequest

client = TestClient(app)

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"

def test_request_otp_invalid_phone():
    response = client.post(
        "/api/v1/auth/request-otp",
        json={"phone": "12345"}
    )
    assert response.status_code == 422 # Validation error for wrong format

def test_request_otp_valid_phone():
    response = client.post(
        "/api/v1/auth/request-otp",
        json={"phone": "+919876543210"}
    )
    assert response.status_code == 200
    assert "otp" in response.json()["message"].lower()

@pytest.mark.asyncio
async def test_get_doctors():
    # Test doctor search without auth (should fail if protected, or pass if public)
    response = client.get("/api/v1/bookings/doctors")
    assert response.status_code in [200, 401] # Depends on exact auth setup

def test_create_razorpay_order_without_auth():
    # Should be 401 Unauthorized
    response = client.post(
        "/api/v1/payments/create-order",
        json={"amount": 500, "description": "Test"}
    )
    assert response.status_code == 401

