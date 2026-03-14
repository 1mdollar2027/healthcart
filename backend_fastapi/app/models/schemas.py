"""
HealthCart – Pydantic schemas for request/response validation.
"""
from datetime import date, time, datetime
from enum import Enum
from pydantic import BaseModel, Field
from typing import Optional


# ── Enums ──
class UserRole(str, Enum):
    patient = "patient"
    doctor = "doctor"
    clinic_admin = "clinic_admin"
    lab_admin = "lab_admin"
    lab_technician = "lab_technician"
    pharmacy_admin = "pharmacy_admin"
    super_admin = "super_admin"


class AppointmentStatus(str, Enum):
    pending = "pending"
    confirmed = "confirmed"
    in_progress = "in_progress"
    completed = "completed"
    cancelled = "cancelled"
    no_show = "no_show"


class PaymentStatus(str, Enum):
    created = "created"
    authorized = "authorized"
    captured = "captured"
    failed = "failed"
    refunded = "refunded"


class LabBookingStatus(str, Enum):
    booked = "booked"
    sample_collected = "sample_collected"
    processing = "processing"
    completed = "completed"
    cancelled = "cancelled"


class PharmacyOrderStatus(str, Enum):
    received = "received"
    preparing = "preparing"
    ready = "ready"
    dispatched = "dispatched"
    delivered = "delivered"
    cancelled = "cancelled"


class VerificationStatus(str, Enum):
    pending = "pending"
    verified = "verified"
    rejected = "rejected"


# ── Auth ──
class OTPRequest(BaseModel):
    phone: str = Field(..., pattern=r"^\+91\d{10}$", examples=["+919876543210"])


class OTPVerify(BaseModel):
    phone: str = Field(..., pattern=r"^\+91\d{10}$")
    otp: str = Field(..., min_length=4, max_length=6)


class ProfileCreate(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=100)
    role: UserRole = UserRole.patient
    phone: Optional[str] = None
    email: Optional[str] = None
    gender: Optional[str] = None
    date_of_birth: Optional[date] = None
    address_line: Optional[str] = None
    city: str = "Jaipur"
    state: str = "Rajasthan"
    pincode: Optional[str] = None
    language_pref: str = "en"


class ProfileUpdate(BaseModel):
    full_name: Optional[str] = None
    email: Optional[str] = None
    gender: Optional[str] = None
    date_of_birth: Optional[date] = None
    address_line: Optional[str] = None
    city: Optional[str] = None
    pincode: Optional[str] = None
    language_pref: Optional[str] = None
    fcm_token: Optional[str] = None
    avatar_url: Optional[str] = None


class ProfileResponse(BaseModel):
    id: str
    role: str
    full_name: str
    phone: Optional[str] = None
    email: Optional[str] = None
    avatar_url: Optional[str] = None
    city: Optional[str] = None
    consent_given: bool = False
    created_at: Optional[datetime] = None


class ConsentCreate(BaseModel):
    consent_type: str = "data_processing"
    consented: bool = True
    consent_text: Optional[str] = None


# ── Doctor ──
class DoctorCreate(BaseModel):
    registration_number: str
    qualification: str
    specialization: str
    experience_years: int = 0
    consultation_fee: float = 500.0
    bio: Optional[str] = None
    languages: list[str] = ["Hindi", "English"]


class DoctorUpdate(BaseModel):
    consultation_fee: Optional[float] = None
    bio: Optional[str] = None
    available_for_video: Optional[bool] = None
    languages: Optional[list[str]] = None


class DoctorResponse(BaseModel):
    id: str
    profile_id: str
    registration_number: str
    qualification: str
    specialization: str
    experience_years: int
    consultation_fee: float
    bio: Optional[str] = None
    languages: list[str]
    available_for_video: bool
    average_rating: float
    total_consultations: int
    verification_status: str
    is_active: bool
    # Joined fields
    full_name: Optional[str] = None
    avatar_url: Optional[str] = None
    phone: Optional[str] = None


class DoctorSearchParams(BaseModel):
    specialization: Optional[str] = None
    city: Optional[str] = None
    min_fee: Optional[float] = None
    max_fee: Optional[float] = None
    min_rating: Optional[float] = None
    available_for_video: Optional[bool] = None
    query: Optional[str] = None
    page: int = 1
    limit: int = 20


# ── Appointments ──
class AppointmentCreate(BaseModel):
    doctor_id: str
    clinic_id: Optional[str] = None
    appointment_date: date
    appointment_time: time
    consultation_type: str = "video"
    reason: Optional[str] = None


class AppointmentUpdate(BaseModel):
    status: Optional[AppointmentStatus] = None
    notes: Optional[str] = None
    cancellation_reason: Optional[str] = None


class AppointmentResponse(BaseModel):
    id: str
    patient_id: str
    doctor_id: str
    clinic_id: Optional[str] = None
    appointment_date: date
    appointment_time: time
    status: str
    consultation_type: str
    reason: Optional[str] = None
    created_at: Optional[datetime] = None
    # Joined
    doctor_name: Optional[str] = None
    patient_name: Optional[str] = None
    specialization: Optional[str] = None


# ── Consultation ──
class ConsultationCreate(BaseModel):
    appointment_id: str


class ConsultationEnd(BaseModel):
    doctor_notes: Optional[str] = None
    diagnosis: Optional[str] = None


# ── Prescription ──
class PrescriptionItemCreate(BaseModel):
    medicine_name: str
    dosage: str
    frequency: str  # e.g. "1-0-1"
    duration: str   # e.g. "7 days"
    instructions: Optional[str] = None


class PrescriptionCreate(BaseModel):
    consultation_id: Optional[str] = None
    patient_id: str
    diagnosis: Optional[str] = None
    notes: Optional[str] = None
    advice: Optional[str] = None
    follow_up_date: Optional[date] = None
    items: list[PrescriptionItemCreate]


class PrescriptionResponse(BaseModel):
    id: str
    patient_id: str
    doctor_id: str
    diagnosis: Optional[str] = None
    notes: Optional[str] = None
    advice: Optional[str] = None
    follow_up_date: Optional[date] = None
    pdf_url: Optional[str] = None
    signed_at: Optional[datetime] = None
    items: list[PrescriptionItemCreate] = []
    doctor_name: Optional[str] = None


# ── Lab ──
class LabTestResponse(BaseModel):
    id: str
    lab_id: str
    name: str
    category: str
    price: float
    turnaround_hours: int
    sample_type: str
    preparation_instructions: Optional[str] = None
    lab_name: Optional[str] = None


class LabBookingCreate(BaseModel):
    lab_id: str
    lab_test_id: str
    collection_address: str
    collection_date: date
    collection_time_slot: str = "09:00-11:00"
    notes: Optional[str] = None


class LabBookingUpdate(BaseModel):
    status: Optional[LabBookingStatus] = None
    assigned_technician_id: Optional[str] = None


class LabResultUpload(BaseModel):
    lab_booking_id: str
    remarks: Optional[str] = None
    result_data: Optional[dict] = None


# ── Pharmacy ──
class PharmacyOrderCreate(BaseModel):
    pharmacy_id: str
    prescription_id: Optional[str] = None
    delivery_address: str
    items: list[dict]  # [{medicine_id, quantity}]


class PharmacyOrderUpdate(BaseModel):
    status: Optional[PharmacyOrderStatus] = None
    estimated_delivery_time: Optional[str] = None


# ── Payments ──
class PaymentOrderCreate(BaseModel):
    amount: float = Field(..., gt=0)
    appointment_id: Optional[str] = None
    lab_booking_id: Optional[str] = None
    pharmacy_order_id: Optional[str] = None
    description: str = "HealthCart Payment"


class PaymentVerify(BaseModel):
    razorpay_order_id: str
    razorpay_payment_id: str
    razorpay_signature: str


# ── Vitals ──
class VitalCreate(BaseModel):
    vital_type: str
    value: float
    unit: str
    device_id: Optional[str] = None


class VitalBatchCreate(BaseModel):
    readings: list[VitalCreate]


# ── Clinic ──
class ClinicCreate(BaseModel):
    name: str
    clinic_type: str = "clinic"
    phone: Optional[str] = None
    email: Optional[str] = None
    address_line: str
    city: str = "Jaipur"
    state: str = "Rajasthan"
    pincode: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    operating_hours: Optional[dict] = None


class ClinicDoctorAdd(BaseModel):
    doctor_id: str
    is_primary: bool = False
    slot_duration_minutes: int = 15


class DoctorSlotCreate(BaseModel):
    doctor_id: str
    clinic_id: Optional[str] = None
    day_of_week: int = Field(..., ge=0, le=6)
    start_time: time
    end_time: time


# ── Notifications ──
class NotificationResponse(BaseModel):
    id: str
    title: str
    body: str
    notification_type: str
    is_read: bool
    data: Optional[dict] = None
    created_at: Optional[datetime] = None


# ── Common ──
class PaginatedResponse(BaseModel):
    items: list
    total: int
    page: int
    limit: int
    has_more: bool


class MessageResponse(BaseModel):
    message: str
    data: Optional[dict] = None
