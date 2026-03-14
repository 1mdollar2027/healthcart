import pytest
from unittest.mock import patch, MagicMock
from app.services.agora_service import generate_rtc_token
from app.services.razorpay_service import create_order, verify_signature

def test_generate_agora_token():
    # Test our Python logic for Token Generation
    with patch("app.core.config.settings.AGORA_APP_ID", "mock_app_id"), \
         patch("app.core.config.settings.AGORA_APP_CERTIFICATE", "mock_cert"):
        
        token = generate_rtc_token("test_channel", 123)
        assert token is not None
        assert isinstance(token, str)


def test_razorpay_create_order():
    # Test typical structure returned by razorpay sdk
    with patch("app.services.razorpay_service.client") as mock_client:
        mock_client.order.create.return_value = {
            "id": "order_mock123",
            "entity": "order",
            "amount": 50000,
            "currency": "INR",
            "status": "created"
        }
        
        order = create_order(500.00, "Consultation Fee")
        assert order["id"] == "order_mock123"
        assert order["amount"] == 50000
        assert order["currency"] == "INR"
        mock_client.order.create.assert_called_once()


def test_razorpay_verify_signature_success():
    with patch("app.services.razorpay_service.client") as mock_client:
        mock_client.utility.verify_payment_signature.return_value = True
        
        result = verify_signature("order_id", "payment_id", "signature")
        assert result is True


def test_razorpay_verify_signature_fail():
    with patch("app.services.razorpay_service.client") as mock_client:
        # Simulate an exception thrown on invalid signature as per Razorpay SDK behaviour
        mock_client.utility.verify_payment_signature.side_effect = Exception("Invalid signature")
        
        result = verify_signature("order_id", "payment_id", "bad_signature")
        assert result is False
