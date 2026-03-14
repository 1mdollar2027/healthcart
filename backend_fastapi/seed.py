"""
HealthCart – Seed Script
Populates the database with realistic fake data for testing.
Run: python seed.py
"""
import os
import sys
import random
from datetime import datetime, timedelta, date, time
from supabase import create_client

# Configuration
SUPABASE_URL = os.getenv("SUPABASE_URL", "http://localhost:8000")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")

if not SUPABASE_KEY:
    print("⚠️  SUPABASE_SERVICE_ROLE_KEY not set. Using direct DB connection instead.")
    print("Set the env var and re-run, or manually execute the SQL below.")

sb = create_client(SUPABASE_URL, SUPABASE_KEY) if SUPABASE_KEY else None

# ── Fake Data ──
SPECIALIZATIONS = [
    "General Medicine", "Cardiology", "Dermatology", "Orthopedics",
    "Pediatrics", "Gynecology", "ENT", "Ophthalmology",
    "Neurology", "Psychiatry"
]

DOCTOR_NAMES = [
    "Dr. Rajesh Sharma", "Dr. Priya Patel", "Dr. Arun Kumar",
    "Dr. Sneha Gupta", "Dr. Vikram Singh", "Dr. Meera Joshi",
    "Dr. Amit Verma", "Dr. Ananya Reddy", "Dr. Sanjay Mishra",
    "Dr. Kavita Agarwal"
]

PATIENT_NAMES = [
    "Rahul Mehta", "Sunita Devi", "Arvind Kumar", "Pooja Sharma",
    "Ravi Teja", "Neha Singh", "Mohit Gupta", "Anjali Patel",
    "Deepak Verma", "Priyanka Jain", "Suresh Yadav", "Rekha Mishra",
    "Ajay Chauhan", "Sita Kumari", "Manoj Agarwal", "Kavya Nair",
    "Rohit Saxena", "Divya Pillai", "Ganesh Bhatt", "Laxmi Rathore",
    "Tikaram Choudhary", "Meena Kanwar", "Bhupendra Shekhawat",
    "Gauri Sharma", "Dinesh Joshi", "Padma Vyas", "Chetan Soni",
    "Sundar Prajapati", "Kamla Bisht", "Ramesh Meena",
    "Sunil Kumar", "Anita Rani", "Prakash Ola", "Geeta Devi",
    "Mahendra Singh", "Usha Kumari", "Naresh Pareek", "Seema Rajput",
    "Vijay Suthar", "Nirmala Devi", "Hari Om", "Santosh Kumari",
    "Bharat Lal", "Pushpa Devi", "Yogesh Tak", "Kanchan Bai",
    "Jagdish Prasad", "Sarla Devi", "Mukesh Kumar", "Tulsi Bai"
]

CLINIC_NAMES = [
    "Jaipur City Hospital", "Rajasthan Super Speciality Clinic",
    "Mahatma Gandhi Medical Centre", "Pink City Healthcare",
    "Arogya Wellness Clinic"
]

LAB_NAMES = [
    "PathCare Diagnostics Jaipur", "Rajasthan Clinical Labs",
    "MedTest Laboratories"
]

PHARMACY_NAMES = [
    "Apollo Pharmacy Jaipur", "MedPlus Pharmacy",
    "Jan Aushadhi Medical Store", "HealthKart Pharmacy"
]

MEDICINES = [
    ("Paracetamol 500mg", "Paracetamol", "GSK", 12.00),
    ("Amoxicillin 250mg", "Amoxicillin", "Cipla", 45.00),
    ("Cetirizine 10mg", "Cetirizine", "Sun Pharma", 8.00),
    ("Metformin 500mg", "Metformin", "USV", 25.00),
    ("Amlodipine 5mg", "Amlodipine", "Lupin", 18.00),
    ("Omeprazole 20mg", "Omeprazole", "Dr Reddy's", 35.00),
    ("Azithromycin 500mg", "Azithromycin", "Zydus", 65.00),
    ("Pantoprazole 40mg", "Pantoprazole", "Alkem", 42.00),
    ("Atorvastatin 10mg", "Atorvastatin", "Ranbaxy", 55.00),
    ("Clopidogrel 75mg", "Clopidogrel", "Mankind", 38.00),
]

LAB_TESTS = [
    ("Complete Blood Count (CBC)", "Hematology", 350, "Blood", 12),
    ("Blood Glucose Fasting", "Diabetology", 150, "Blood", 6),
    ("Thyroid Profile (T3, T4, TSH)", "Endocrinology", 650, "Blood", 24),
    ("Lipid Profile", "Cardiology", 500, "Blood", 12),
    ("Liver Function Test (LFT)", "Gastroenterology", 550, "Blood", 24),
    ("Kidney Function Test (KFT)", "Nephrology", 450, "Blood", 24),
    ("HbA1c", "Diabetology", 400, "Blood", 24),
    ("Vitamin D", "General", 700, "Blood", 48),
    ("Vitamin B12", "General", 600, "Blood", 48),
    ("COVID-19 RT-PCR", "Infectious Disease", 500, "Swab", 24),
]


def seed_data():
    """Seed all fake data."""
    if not sb:
        print("❌ Cannot seed without Supabase connection.")
        return

    print("🌱 Seeding HealthCart database...")

    # Create super admin
    print("  → Creating super admin...")
    admin_auth = sb.auth.admin.create_user({
        "email": "admin@healthcart.in",
        "password": "Admin@2026!",
        "email_confirm": True,
        "user_metadata": {"role": "super_admin", "full_name": "Super Admin"}
    })
    admin_id = admin_auth.user.id
    sb.table("profiles").insert({
        "id": admin_id, "role": "super_admin", "full_name": "Super Admin",
        "email": "admin@healthcart.in", "phone": "+919999999999",
        "consent_given": True, "verification_status": "verified"
    }).execute()

    # Create doctors
    print("  → Creating 10 doctors...")
    doctor_ids = []
    for i, name in enumerate(DOCTOR_NAMES):
        phone = f"+9198765{str(i).zfill(5)}"
        auth_result = sb.auth.admin.create_user({
            "phone": phone, "phone_confirm": True,
            "user_metadata": {"role": "doctor", "full_name": name}
        })
        uid = auth_result.user.id
        sb.table("profiles").insert({
            "id": uid, "role": "doctor", "full_name": name, "phone": phone,
            "city": "Jaipur", "state": "Rajasthan", "consent_given": True,
            "verification_status": "verified"
        }).execute()
        doc = sb.table("doctors").insert({
            "profile_id": uid, "registration_number": f"RJ-MED-{2020+i}",
            "qualification": random.choice(["MBBS", "MBBS, MD", "MBBS, MS", "BDS"]),
            "specialization": SPECIALIZATIONS[i],
            "experience_years": random.randint(3, 25),
            "consultation_fee": random.choice([300, 500, 700, 1000, 1500]),
            "bio": f"{name} is a highly experienced {SPECIALIZATIONS[i]} specialist.",
            "verification_status": "verified", "is_active": True,
            "average_rating": round(random.uniform(3.5, 5.0), 2),
        }).execute()
        doctor_ids.append(doc.data[0]["id"])

        # Add slots for each doctor
        for day in range(1, 6):  # Mon-Fri
            sb.table("doctor_slots").insert({
                "doctor_id": doc.data[0]["id"],
                "day_of_week": day,
                "start_time": "09:00", "end_time": "13:00",
            }).execute()
            sb.table("doctor_slots").insert({
                "doctor_id": doc.data[0]["id"],
                "day_of_week": day,
                "start_time": "15:00", "end_time": "18:00",
            }).execute()

    # Create clinics
    print("  → Creating 5 clinics...")
    clinic_ids = []
    for i, name in enumerate(CLINIC_NAMES):
        phone = f"+9187654{str(i).zfill(5)}"
        auth_result = sb.auth.admin.create_user({
            "phone": phone, "phone_confirm": True,
            "user_metadata": {"role": "clinic_admin", "full_name": f"{name} Admin"}
        })
        uid = auth_result.user.id
        sb.table("profiles").insert({
            "id": uid, "role": "clinic_admin", "full_name": f"{name} Admin", "phone": phone,
            "city": "Jaipur", "consent_given": True, "verification_status": "verified"
        }).execute()
        clinic = sb.table("clinics").insert({
            "admin_profile_id": uid, "name": name, "phone": phone,
            "address_line": f"{random.randint(1,500)}, MI Road, Jaipur",
            "city": "Jaipur", "pincode": f"3020{i+1}",
            "latitude": 26.9124 + random.uniform(-0.05, 0.05),
            "longitude": 75.7873 + random.uniform(-0.05, 0.05),
            "verification_status": "verified",
        }).execute()
        clinic_ids.append(clinic.data[0]["id"])

        # Assign 2 doctors to each clinic
        for j in range(2):
            didx = (i * 2 + j) % len(doctor_ids)
            sb.table("clinic_doctors").insert({
                "clinic_id": clinic.data[0]["id"],
                "doctor_id": doctor_ids[didx],
                "is_primary": j == 0,
            }).execute()

    # Create labs
    print("  → Creating 3 labs...")
    lab_ids = []
    for i, name in enumerate(LAB_NAMES):
        phone = f"+9176543{str(i).zfill(5)}"
        auth_result = sb.auth.admin.create_user({
            "phone": phone, "phone_confirm": True,
            "user_metadata": {"role": "lab_admin", "full_name": f"{name} Admin"}
        })
        uid = auth_result.user.id
        sb.table("profiles").insert({
            "id": uid, "role": "lab_admin", "full_name": f"{name} Admin", "phone": phone,
            "city": "Jaipur", "consent_given": True, "verification_status": "verified"
        }).execute()
        lab = sb.table("labs").insert({
            "admin_profile_id": uid, "name": name, "phone": phone,
            "address_line": f"{random.randint(1,300)}, Tonk Road, Jaipur",
            "city": "Jaipur", "pincode": f"3020{i+3}",
            "home_collection_available": True, "verification_status": "verified",
        }).execute()
        lab_ids.append(lab.data[0]["id"])

        # Add tests
        for test in LAB_TESTS:
            sb.table("lab_tests").insert({
                "lab_id": lab.data[0]["id"],
                "name": test[0], "category": test[1],
                "price": test[2], "sample_type": test[3],
                "turnaround_hours": test[4],
            }).execute()

    # Create pharmacies
    print("  → Creating 4 pharmacies...")
    pharmacy_ids = []
    for i, name in enumerate(PHARMACY_NAMES):
        phone = f"+9165432{str(i).zfill(5)}"
        auth_result = sb.auth.admin.create_user({
            "phone": phone, "phone_confirm": True,
            "user_metadata": {"role": "pharmacy_admin", "full_name": f"{name} Admin"}
        })
        uid = auth_result.user.id
        sb.table("profiles").insert({
            "id": uid, "role": "pharmacy_admin", "full_name": f"{name} Admin", "phone": phone,
            "city": "Jaipur", "consent_given": True, "verification_status": "verified"
        }).execute()
        pharm = sb.table("pharmacies").insert({
            "admin_profile_id": uid, "name": name, "phone": phone,
            "address_line": f"{random.randint(1,200)}, Ajmer Road, Jaipur",
            "city": "Jaipur", "pincode": f"3020{i+6}",
            "license_number": f"RJ-PH-{2020+i}", "verification_status": "verified",
        }).execute()
        pharmacy_ids.append(pharm.data[0]["id"])

        # Add medicines
        for med in MEDICINES:
            sb.table("medicines").insert({
                "pharmacy_id": pharm.data[0]["id"],
                "name": med[0], "generic_name": med[1], "manufacturer": med[2],
                "price": med[3], "mrp": med[3] * 1.2,
                "stock_quantity": random.randint(50, 500),
            }).execute()

    # Create patients
    print("  → Creating 50 patients...")
    patient_ids = []
    for i, name in enumerate(PATIENT_NAMES):
        phone = f"+9190000{str(i).zfill(5)}"
        auth_result = sb.auth.admin.create_user({
            "phone": phone, "phone_confirm": True,
            "user_metadata": {"role": "patient", "full_name": name}
        })
        uid = auth_result.user.id
        sb.table("profiles").insert({
            "id": uid, "role": "patient", "full_name": name, "phone": phone,
            "gender": random.choice(["male", "female"]),
            "date_of_birth": f"{random.randint(1960, 2005)}-{random.randint(1,12):02d}-{random.randint(1,28):02d}",
            "city": "Jaipur", "consent_given": True,
        }).execute()
        sb.table("patients").insert({
            "profile_id": uid,
            "blood_group": random.choice(["A+", "B+", "O+", "AB+", "A-", "B-", "O-"]),
            "emergency_contact_name": random.choice(PATIENT_NAMES),
            "emergency_contact_phone": f"+91900{random.randint(1000000,9999999)}",
        }).execute()
        patient_ids.append(uid)

    # Create sample appointments
    print("  → Creating sample appointments & vitals...")
    for i in range(20):
        patient_id = random.choice(patient_ids)
        doctor_id = random.choice(doctor_ids)
        appt_date = (datetime.now() + timedelta(days=random.randint(-10, 30))).date()
        appt_time = time(hour=random.choice([9, 10, 11, 14, 15, 16]))
        status = random.choice(["pending", "confirmed", "completed"])

        sb.table("appointments").insert({
            "patient_id": patient_id, "doctor_id": doctor_id,
            "appointment_date": appt_date.isoformat(),
            "appointment_time": appt_time.isoformat(),
            "status": status,
            "reason": random.choice(["Fever", "Headache", "Back pain", "Skin rash", "Check-up", "Follow-up"]),
        }).execute()

    # Create sample vitals
    for patient_id in patient_ids[:10]:
        for _ in range(5):
            sb.table("vitals").insert({
                "patient_id": patient_id,
                "vital_type": "blood_pressure_systolic",
                "value": random.randint(110, 160),
                "unit": "mmHg", "device_id": "sim_seed",
            }).execute()
            sb.table("vitals").insert({
                "patient_id": patient_id,
                "vital_type": "blood_glucose",
                "value": random.randint(80, 200),
                "unit": "mg/dL", "device_id": "sim_seed",
            }).execute()
            sb.table("vitals").insert({
                "patient_id": patient_id,
                "vital_type": "heart_rate",
                "value": random.randint(60, 100),
                "unit": "bpm", "device_id": "sim_seed",
            }).execute()

    print("✅ Seed complete!")
    print(f"   - {len(DOCTOR_NAMES)} doctors")
    print(f"   - {len(CLINIC_NAMES)} clinics")
    print(f"   - {len(LAB_NAMES)} labs")
    print(f"   - {len(PHARMACY_NAMES)} pharmacies")
    print(f"   - {len(PATIENT_NAMES)} patients")
    print(f"   - 20 sample appointments")
    print(f"   - Vitals data for 10 patients")
    print()
    print("🔑 Super Admin Login:")
    print("   Email: admin@healthcart.in")
    print("   Password: Admin@2026!")


if __name__ == "__main__":
    seed_data()
