"""
Pharmacies Router – Order management, inventory, delivery tracking.
"""
from typing import Annotated, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from supabase import Client
from app.core.deps import get_supabase_admin
from app.core.security import get_current_user, require_pharmacy_admin
from app.models.schemas import PharmacyOrderCreate, PharmacyOrderUpdate, MessageResponse

router = APIRouter()


@router.get("/")
async def list_pharmacies(
    city: Optional[str] = None,
    delivery: Optional[bool] = None,
    sb: Client = Depends(get_supabase_admin),
):
    """List verified pharmacies."""
    q = sb.table("pharmacies").select("*").eq("verification_status", "verified").eq("is_active", True)
    if city:
        q = q.eq("city", city)
    if delivery is not None:
        q = q.eq("delivery_available", delivery)
    result = q.execute()
    return {"items": result.data or []}


@router.get("/{pharmacy_id}/medicines")
async def list_medicines(
    pharmacy_id: str,
    category: Optional[str] = None,
    query: Optional[str] = None,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=50),
    sb: Client = Depends(get_supabase_admin),
):
    """List medicines available at a pharmacy."""
    q = sb.table("medicines").select("*").eq("pharmacy_id", pharmacy_id).eq("is_active", True)
    if category:
        q = q.eq("category", category)
    if query:
        q = q.ilike("name", f"%{query}%")
    offset = (page - 1) * limit
    result = q.order("name").range(offset, offset + limit - 1).execute()
    return {"items": result.data or [], "page": page, "limit": limit}


@router.post("/orders")
async def create_pharmacy_order(
    body: PharmacyOrderCreate,
    current_user: Annotated[dict, Depends(get_current_user)],
    sb: Annotated[Client, Depends(get_supabase_admin)],
):
    """Create a pharmacy order (from prescription or direct)."""
    # Calculate total
    total = 0.0
    order_items = []
    for item in body.items:
        medicine = sb.table("medicines").select("price, stock_quantity").eq(
            "id", item["medicine_id"]
        ).single().execute()
        if not medicine.data:
            raise HTTPException(status_code=404, detail=f"Medicine {item['medicine_id']} not found")
        if medicine.data["stock_quantity"] < item.get("quantity", 1):
            raise HTTPException(status_code=400, detail=f"Insufficient stock for medicine {item['medicine_id']}")
        qty = item.get("quantity", 1)
        total += medicine.data["price"] * qty
        order_items.append({
            "medicine_id": item["medicine_id"],
            "quantity": qty,
            "unit_price": medicine.data["price"],
        })

    # Create order
    order_data = {
        "patient_id": current_user["id"],
        "pharmacy_id": body.pharmacy_id,
        "prescription_id": body.prescription_id,
        "delivery_address": body.delivery_address,
        "total_amount": total,
        "delivery_fee": 40.0 if total < 500 else 0,
        "status": "received",
    }
    order_result = sb.table("pharmacy_orders").insert(order_data).execute()
    order_id = order_result.data[0]["id"]

    # Insert items
    for item in order_items:
        item["order_id"] = order_id
    sb.table("pharmacy_order_items").insert(order_items).execute()

    # Reduce stock
    for item in body.items:
        sb.rpc("decrement_medicine_stock", {
            "med_id": item["medicine_id"],
            "qty": item.get("quantity", 1)
        }).execute()

    # Notify pharmacy
    pharmacy = sb.table("pharmacies").select("admin_profile_id").eq("id", body.pharmacy_id).single().execute()
    if pharmacy.data:
        sb.table("notifications").insert({
            "user_id": pharmacy.data["admin_profile_id"],
            "title": "New Order Received",
            "body": f"New order worth ₹{total:.0f}",
            "notification_type": "general",
            "data": {"order_id": order_id},
        }).execute()

    return {**order_result.data[0], "items": order_items}


@router.get("/orders")
async def list_pharmacy_orders(
    status: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
    sb: Client = Depends(get_supabase_admin),
):
    """List pharmacy orders (patient or pharmacy admin)."""
    profile = sb.table("profiles").select("role").eq("id", current_user["id"]).single().execute()
    role = profile.data["role"]

    if role == "patient":
        q = sb.table("pharmacy_orders").select(
            "*, pharmacies!inner(name)"
        ).eq("patient_id", current_user["id"])
    elif role == "pharmacy_admin":
        pharms = sb.table("pharmacies").select("id").eq("admin_profile_id", current_user["id"]).execute()
        pharm_ids = [p["id"] for p in (pharms.data or [])]
        if not pharm_ids:
            return {"items": []}
        q = sb.table("pharmacy_orders").select(
            "*, profiles!inner(full_name, phone, address_line)"
        ).in_("pharmacy_id", pharm_ids)
    else:
        raise HTTPException(status_code=403, detail="Not authorized")

    if status:
        q = q.eq("status", status)
    result = q.order("created_at", desc=True).execute()
    return {"items": result.data or []}


@router.patch("/orders/{order_id}")
async def update_pharmacy_order(
    order_id: str,
    body: PharmacyOrderUpdate,
    current_user: Annotated[dict, Depends(require_pharmacy_admin)],
    sb: Annotated[Client, Depends(get_supabase_admin)],
):
    """Update pharmacy order status."""
    update_data = body.model_dump(exclude_none=True)
    if body.status and body.status.value == "delivered":
        from datetime import datetime, timezone
        update_data["delivered_at"] = datetime.now(timezone.utc).isoformat()

    result = sb.table("pharmacy_orders").update(update_data).eq("id", order_id).execute()
    if not result.data:
        raise HTTPException(status_code=404, detail="Order not found")

    # Notify patient
    order = result.data[0]
    status_messages = {
        "preparing": "Your order is being prepared.",
        "ready": "Your order is ready for pickup/dispatch.",
        "dispatched": "Your order has been dispatched!",
        "delivered": "Your order has been delivered.",
    }
    if body.status and body.status.value in status_messages:
        sb.table("notifications").insert({
            "user_id": order["patient_id"],
            "title": "Order Update",
            "body": status_messages[body.status.value],
            "notification_type": "general",
            "data": {"order_id": order_id, "status": body.status.value},
        }).execute()

    return result.data[0]
