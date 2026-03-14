"""
Payments Router – Razorpay order creation, webhook verification.
"""
from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException, Request
from supabase import Client
from app.core.deps import get_supabase_admin
from app.core.security import get_current_user
from app.services.razorpay_service import RazorpayService
from app.models.schemas import PaymentOrderCreate, PaymentVerify, MessageResponse

router = APIRouter()
rp = RazorpayService()


@router.post("/create-order")
async def create_payment_order(
    body: PaymentOrderCreate,
    current_user: Annotated[dict, Depends(get_current_user)],
    sb: Annotated[Client, Depends(get_supabase_admin)],
):
    """Create a Razorpay order for UPI/card payment."""
    # Create Razorpay order
    rp_order = rp.create_order(
        amount=body.amount,
        receipt=f"hc_{body.appointment_id or body.lab_booking_id or body.pharmacy_order_id}",
        notes={"patient_id": current_user["id"], "description": body.description},
    )

    # Save payment record
    payment_data = {
        "patient_id": current_user["id"],
        "appointment_id": body.appointment_id,
        "lab_booking_id": body.lab_booking_id,
        "pharmacy_order_id": body.pharmacy_order_id,
        "razorpay_order_id": rp_order["id"],
        "amount": body.amount,
        "description": body.description,
        "receipt": rp_order.get("receipt"),
        "status": "created",
    }
    result = sb.table("payments").insert(payment_data).execute()

    return {
        "payment_id": result.data[0]["id"],
        "razorpay_order_id": rp_order["id"],
        "razorpay_key_id": rp.key_id,
        "amount": int(body.amount * 100),  # paise
        "currency": "INR",
        "description": body.description,
        "prefill": {
            "contact": "",
            "email": "",
        },
    }


@router.post("/verify", response_model=MessageResponse)
async def verify_payment(
    body: PaymentVerify,
    current_user: Annotated[dict, Depends(get_current_user)],
    sb: Annotated[Client, Depends(get_supabase_admin)],
):
    """Verify Razorpay payment signature (client-side verification)."""
    is_valid = rp.verify_payment_signature(
        order_id=body.razorpay_order_id,
        payment_id=body.razorpay_payment_id,
        signature=body.razorpay_signature,
    )

    if not is_valid:
        # Mark payment as failed
        sb.table("payments").update({"status": "failed"}).eq(
            "razorpay_order_id", body.razorpay_order_id
        ).execute()
        raise HTTPException(status_code=400, detail="Payment verification failed")

    # Update payment as captured
    payment = sb.table("payments").update({
        "status": "captured",
        "razorpay_payment_id": body.razorpay_payment_id,
        "razorpay_signature": body.razorpay_signature,
    }).eq("razorpay_order_id", body.razorpay_order_id).execute()

    if payment.data:
        p = payment.data[0]
        # If appointment payment, confirm the appointment
        if p.get("appointment_id"):
            sb.table("appointments").update({"status": "confirmed"}).eq(
                "id", p["appointment_id"]
            ).execute()

            # Notify doctor
            appt = sb.table("appointments").select(
                "doctor_id, appointment_date, appointment_time"
            ).eq("id", p["appointment_id"]).single().execute()
            if appt.data:
                doctor = sb.table("doctors").select("profile_id").eq(
                    "id", appt.data["doctor_id"]
                ).single().execute()
                if doctor.data:
                    sb.table("notifications").insert({
                        "user_id": doctor.data["profile_id"],
                        "title": "New Appointment Confirmed",
                        "body": f"New appointment on {appt.data['appointment_date']} at {appt.data['appointment_time']}",
                        "notification_type": "appointment",
                        "data": {"appointment_id": p["appointment_id"]},
                    }).execute()

    return MessageResponse(message="Payment verified successfully")


@router.post("/webhook")
async def razorpay_webhook(request: Request, sb: Client = Depends(get_supabase_admin)):
    """Handle Razorpay webhook events (server-to-server)."""
    body = await request.body()
    signature = request.headers.get("X-Razorpay-Signature", "")

    if not rp.verify_webhook_signature(body.decode(), signature):
        raise HTTPException(status_code=400, detail="Invalid webhook signature")

    payload = await request.json()
    event = payload.get("event", "")
    payment_entity = payload.get("payload", {}).get("payment", {}).get("entity", {})

    if event == "payment.captured":
        order_id = payment_entity.get("order_id")
        if order_id:
            sb.table("payments").update({
                "status": "captured",
                "razorpay_payment_id": payment_entity.get("id"),
                "webhook_payload": payload,
            }).eq("razorpay_order_id", order_id).execute()

    elif event == "payment.failed":
        order_id = payment_entity.get("order_id")
        if order_id:
            sb.table("payments").update({
                "status": "failed",
                "webhook_payload": payload,
            }).eq("razorpay_order_id", order_id).execute()

    elif event == "refund.created":
        payment_id = payment_entity.get("payment_id")
        if payment_id:
            sb.table("payments").update({
                "status": "refunded",
                "webhook_payload": payload,
            }).eq("razorpay_payment_id", payment_id).execute()

    return {"status": "ok"}


@router.get("/")
async def list_payments(
    current_user: dict = Depends(get_current_user),
    sb: Client = Depends(get_supabase_admin),
):
    """List payments for current user."""
    result = sb.table("payments").select("*").eq(
        "patient_id", current_user["id"]
    ).order("created_at", desc=True).execute()
    return {"items": result.data or []}
