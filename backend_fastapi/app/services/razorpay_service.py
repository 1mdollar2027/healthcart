"""
Razorpay Service – Order creation, signature verification.
"""
import hmac
import hashlib
import razorpay
from app.core.config import get_settings

settings = get_settings()


class RazorpayService:
    def __init__(self):
        self.key_id = settings.RAZORPAY_KEY_ID
        self.key_secret = settings.RAZORPAY_KEY_SECRET
        self.webhook_secret = settings.RAZORPAY_WEBHOOK_SECRET

        if self.key_id and self.key_secret:
            self.client = razorpay.Client(auth=(self.key_id, self.key_secret))
        else:
            self.client = None

    def create_order(self, amount: float, receipt: str, notes: dict = None) -> dict:
        """Create a Razorpay order. Amount in INR (converted to paise)."""
        if not self.client:
            # Return mock order for development
            import uuid
            return {
                "id": f"order_{uuid.uuid4().hex[:16]}",
                "amount": int(amount * 100),
                "currency": "INR",
                "receipt": receipt,
                "status": "created",
            }

        order_data = {
            "amount": int(amount * 100),  # Convert to paise
            "currency": "INR",
            "receipt": receipt[:40],
            "payment_capture": 1,  # Auto-capture
        }
        if notes:
            order_data["notes"] = {k: str(v)[:255] for k, v in notes.items()}

        return self.client.order.create(data=order_data)

    def verify_payment_signature(self, order_id: str, payment_id: str, signature: str) -> bool:
        """Verify Razorpay payment signature."""
        if not self.client:
            return True  # Dev mode

        try:
            self.client.utility.verify_payment_signature({
                "razorpay_order_id": order_id,
                "razorpay_payment_id": payment_id,
                "razorpay_signature": signature,
            })
            return True
        except razorpay.errors.SignatureVerificationError:
            return False

    def verify_webhook_signature(self, body: str, signature: str) -> bool:
        """Verify Razorpay webhook signature."""
        if not self.webhook_secret:
            return True  # Dev mode

        expected = hmac.new(
            self.webhook_secret.encode("utf-8"),
            body.encode("utf-8"),
            hashlib.sha256,
        ).hexdigest()
        return hmac.compare_digest(expected, signature)

    def fetch_payment(self, payment_id: str) -> dict:
        """Fetch payment details from Razorpay."""
        if not self.client:
            return {"id": payment_id, "status": "captured"}
        return self.client.payment.fetch(payment_id)

    def create_refund(self, payment_id: str, amount: float) -> dict:
        """Create a refund."""
        if not self.client:
            return {"id": "rfnd_mock", "amount": int(amount * 100)}
        return self.client.payment.refund(payment_id, int(amount * 100))
