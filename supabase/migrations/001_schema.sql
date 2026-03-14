-- ============================================================================
-- HealthCart Telemedicine Platform – Master Schema
-- Postgres 16+ with TimescaleDB, pgcrypto, RLS
-- ============================================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "timescaledb" CASCADE;

-- ============================================================================
-- ENUMS
-- ============================================================================
CREATE TYPE user_role AS ENUM (
  'patient', 'doctor', 'clinic_admin', 'lab_admin', 'lab_technician',
  'pharmacy_admin', 'super_admin'
);

CREATE TYPE gender_type AS ENUM ('male', 'female', 'other');

CREATE TYPE appointment_status AS ENUM (
  'pending', 'confirmed', 'in_progress', 'completed', 'cancelled', 'no_show'
);

CREATE TYPE payment_status AS ENUM (
  'created', 'authorized', 'captured', 'failed', 'refunded'
);

CREATE TYPE payment_method AS ENUM (
  'upi', 'card', 'netbanking', 'wallet', 'cod'
);

CREATE TYPE lab_booking_status AS ENUM (
  'booked', 'sample_collected', 'processing', 'completed', 'cancelled'
);

CREATE TYPE pharmacy_order_status AS ENUM (
  'received', 'preparing', 'ready', 'dispatched', 'delivered', 'cancelled'
);

CREATE TYPE consultation_type AS ENUM ('video', 'audio', 'chat');

CREATE TYPE verification_status AS ENUM ('pending', 'verified', 'rejected');

CREATE TYPE vital_type AS ENUM (
  'blood_pressure_systolic', 'blood_pressure_diastolic',
  'heart_rate', 'blood_glucose', 'spo2', 'temperature', 'weight'
);

CREATE TYPE notification_type AS ENUM (
  'appointment', 'prescription', 'lab_result', 'payment',
  'vital_alert', 'general', 'reminder'
);

-- ============================================================================
-- PROFILES (extends Supabase auth.users)
-- ============================================================================
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role user_role NOT NULL DEFAULT 'patient',
  full_name TEXT NOT NULL,
  phone TEXT UNIQUE,
  email TEXT,
  avatar_url TEXT,
  gender gender_type,
  date_of_birth DATE,
  address_line TEXT,
  city TEXT DEFAULT 'Jaipur',
  state TEXT DEFAULT 'Rajasthan',
  pincode TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  language_pref TEXT DEFAULT 'en',
  consent_given BOOLEAN DEFAULT FALSE,
  consent_given_at TIMESTAMPTZ,
  verification_status verification_status DEFAULT 'pending',
  is_active BOOLEAN DEFAULT TRUE,
  fcm_token TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- DOCTORS
-- ============================================================================
CREATE TABLE doctors (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL UNIQUE REFERENCES profiles(id) ON DELETE CASCADE,
  registration_number TEXT NOT NULL,
  qualification TEXT NOT NULL,
  specialization TEXT NOT NULL,
  experience_years INT DEFAULT 0,
  consultation_fee NUMERIC(10,2) NOT NULL DEFAULT 500.00,
  bio TEXT,
  languages TEXT[] DEFAULT ARRAY['Hindi','English'],
  available_for_video BOOLEAN DEFAULT TRUE,
  average_rating NUMERIC(3,2) DEFAULT 0.00,
  total_consultations INT DEFAULT 0,
  kyc_document_url TEXT,
  verification_status verification_status DEFAULT 'pending',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_doctors_specialization ON doctors(specialization);
CREATE INDEX idx_doctors_verification ON doctors(verification_status);

-- ============================================================================
-- CLINICS / HOSPITALS
-- ============================================================================
CREATE TABLE clinics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  clinic_type TEXT DEFAULT 'clinic', -- clinic, hospital, nursing_home
  phone TEXT,
  email TEXT,
  address_line TEXT NOT NULL,
  city TEXT DEFAULT 'Jaipur',
  state TEXT DEFAULT 'Rajasthan',
  pincode TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  logo_url TEXT,
  registration_number TEXT,
  operating_hours JSONB DEFAULT '{"mon":{"open":"09:00","close":"18:00"}}'::jsonb,
  verification_status verification_status DEFAULT 'pending',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Clinic ↔ Doctor M2M
CREATE TABLE clinic_doctors (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  clinic_id UUID NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
  doctor_id UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
  is_primary BOOLEAN DEFAULT FALSE,
  slot_duration_minutes INT DEFAULT 15,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(clinic_id, doctor_id)
);

-- Doctor availability slots
CREATE TABLE doctor_slots (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  doctor_id UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
  clinic_id UUID REFERENCES clinics(id) ON DELETE SET NULL,
  day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6), -- 0=Sun
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_doctor_slots_doctor ON doctor_slots(doctor_id);

-- ============================================================================
-- PATIENTS (extra patient-specific data)
-- ============================================================================
CREATE TABLE patients (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL UNIQUE REFERENCES profiles(id) ON DELETE CASCADE,
  blood_group TEXT,
  allergies TEXT[],
  chronic_conditions TEXT[],
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  height_cm NUMERIC(5,1),
  weight_kg NUMERIC(5,1),
  insurance_provider TEXT,
  insurance_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- APPOINTMENTS
-- ============================================================================
CREATE TABLE appointments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  doctor_id UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
  clinic_id UUID REFERENCES clinics(id) ON DELETE SET NULL,
  appointment_date DATE NOT NULL,
  appointment_time TIME NOT NULL,
  slot_duration_minutes INT DEFAULT 15,
  consultation_type consultation_type DEFAULT 'video',
  status appointment_status DEFAULT 'pending',
  reason TEXT,
  notes TEXT,
  cancellation_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_appointments_patient ON appointments(patient_id);
CREATE INDEX idx_appointments_doctor ON appointments(doctor_id);
CREATE INDEX idx_appointments_date ON appointments(appointment_date);
CREATE INDEX idx_appointments_status ON appointments(status);

-- ============================================================================
-- CONSULTATIONS (video/audio session metadata)
-- ============================================================================
CREATE TABLE consultations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  appointment_id UUID NOT NULL UNIQUE REFERENCES appointments(id) ON DELETE CASCADE,
  agora_channel_name TEXT,
  agora_token_patient TEXT,
  agora_token_doctor TEXT,
  started_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ,
  duration_seconds INT,
  recording_url TEXT,
  doctor_notes TEXT,
  diagnosis TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- PRESCRIPTIONS
-- ============================================================================
CREATE TABLE prescriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  consultation_id UUID REFERENCES consultations(id) ON DELETE SET NULL,
  patient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  doctor_id UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
  diagnosis TEXT,
  notes TEXT,
  advice TEXT,
  follow_up_date DATE,
  pdf_url TEXT,
  signed_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE prescription_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  prescription_id UUID NOT NULL REFERENCES prescriptions(id) ON DELETE CASCADE,
  medicine_name TEXT NOT NULL,
  dosage TEXT NOT NULL,
  frequency TEXT NOT NULL, -- e.g. "1-0-1"
  duration TEXT NOT NULL,  -- e.g. "7 days"
  instructions TEXT,       -- e.g. "After food"
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_prescriptions_patient ON prescriptions(patient_id);
CREATE INDEX idx_prescriptions_doctor ON prescriptions(doctor_id);

-- ============================================================================
-- LABS
-- ============================================================================
CREATE TABLE labs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  address_line TEXT NOT NULL,
  city TEXT DEFAULT 'Jaipur',
  state TEXT DEFAULT 'Rajasthan',
  pincode TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  logo_url TEXT,
  registration_number TEXT,
  home_collection_available BOOLEAN DEFAULT TRUE,
  verification_status verification_status DEFAULT 'pending',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE lab_tests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lab_id UUID NOT NULL REFERENCES labs(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT DEFAULT 'General',
  price NUMERIC(10,2) NOT NULL,
  turnaround_hours INT DEFAULT 24,
  sample_type TEXT DEFAULT 'Blood',
  preparation_instructions TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE lab_bookings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  lab_id UUID NOT NULL REFERENCES labs(id) ON DELETE CASCADE,
  lab_test_id UUID NOT NULL REFERENCES lab_tests(id) ON DELETE CASCADE,
  assigned_technician_id UUID REFERENCES profiles(id),
  collection_address TEXT,
  collection_date DATE NOT NULL,
  collection_time_slot TEXT, -- e.g. "09:00-11:00"
  status lab_booking_status DEFAULT 'booked',
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE lab_results (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lab_booking_id UUID NOT NULL REFERENCES lab_bookings(id) ON DELETE CASCADE,
  result_pdf_url TEXT,
  result_data JSONB,
  remarks TEXT,
  uploaded_by UUID REFERENCES profiles(id),
  uploaded_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_lab_bookings_patient ON lab_bookings(patient_id);
CREATE INDEX idx_lab_bookings_lab ON lab_bookings(lab_id);

-- ============================================================================
-- PHARMACIES
-- ============================================================================
CREATE TABLE pharmacies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  address_line TEXT NOT NULL,
  city TEXT DEFAULT 'Jaipur',
  state TEXT DEFAULT 'Rajasthan',
  pincode TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  logo_url TEXT,
  license_number TEXT,
  delivery_available BOOLEAN DEFAULT TRUE,
  delivery_radius_km NUMERIC(5,1) DEFAULT 10.0,
  verification_status verification_status DEFAULT 'pending',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE medicines (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pharmacy_id UUID NOT NULL REFERENCES pharmacies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  generic_name TEXT,
  manufacturer TEXT,
  category TEXT DEFAULT 'General',
  price NUMERIC(10,2) NOT NULL,
  mrp NUMERIC(10,2),
  stock_quantity INT DEFAULT 0,
  requires_prescription BOOLEAN DEFAULT TRUE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE pharmacy_orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  pharmacy_id UUID NOT NULL REFERENCES pharmacies(id) ON DELETE CASCADE,
  prescription_id UUID REFERENCES prescriptions(id),
  delivery_address TEXT NOT NULL,
  delivery_latitude DOUBLE PRECISION,
  delivery_longitude DOUBLE PRECISION,
  status pharmacy_order_status DEFAULT 'received',
  total_amount NUMERIC(10,2) NOT NULL DEFAULT 0,
  delivery_fee NUMERIC(10,2) DEFAULT 0,
  estimated_delivery_time TEXT,
  delivered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE pharmacy_order_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID NOT NULL REFERENCES pharmacy_orders(id) ON DELETE CASCADE,
  medicine_id UUID NOT NULL REFERENCES medicines(id) ON DELETE CASCADE,
  quantity INT NOT NULL DEFAULT 1,
  unit_price NUMERIC(10,2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_pharmacy_orders_patient ON pharmacy_orders(patient_id);
CREATE INDEX idx_pharmacy_orders_pharmacy ON pharmacy_orders(pharmacy_id);

-- ============================================================================
-- PAYMENTS
-- ============================================================================
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  appointment_id UUID REFERENCES appointments(id),
  lab_booking_id UUID REFERENCES lab_bookings(id),
  pharmacy_order_id UUID REFERENCES pharmacy_orders(id),
  razorpay_order_id TEXT,
  razorpay_payment_id TEXT,
  razorpay_signature TEXT,
  amount NUMERIC(10,2) NOT NULL,
  currency TEXT DEFAULT 'INR',
  method payment_method DEFAULT 'upi',
  status payment_status DEFAULT 'created',
  description TEXT,
  receipt TEXT,
  webhook_payload JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_payments_patient ON payments(patient_id);
CREATE INDEX idx_payments_razorpay ON payments(razorpay_order_id);

-- ============================================================================
-- VITALS (TimescaleDB hypertable for IoT time-series)
-- ============================================================================
CREATE TABLE vitals (
  id UUID DEFAULT uuid_generate_v4(),
  patient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  vital_type vital_type NOT NULL,
  value NUMERIC(10,2) NOT NULL,
  unit TEXT NOT NULL,
  device_id TEXT,
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (id, recorded_at)
);

-- Convert to TimescaleDB hypertable
SELECT create_hypertable('vitals', 'recorded_at', if_not_exists => TRUE);

CREATE INDEX idx_vitals_patient ON vitals(patient_id, recorded_at DESC);

-- ============================================================================
-- IoT DEVICES
-- ============================================================================
CREATE TABLE iot_devices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  device_type TEXT NOT NULL, -- bp_monitor, glucometer, pulse_oximeter, etc
  device_name TEXT,
  device_serial TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  last_sync_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- NOTIFICATIONS
-- ============================================================================
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  notification_type notification_type DEFAULT 'general',
  data JSONB,
  is_read BOOLEAN DEFAULT FALSE,
  sent_via TEXT DEFAULT 'fcm', -- fcm, sms, whatsapp
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id, created_at DESC);

-- ============================================================================
-- AUDIT LOGS (compliance)
-- ============================================================================
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id),
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id UUID,
  details JSONB,
  ip_address INET,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_user ON audit_logs(user_id, created_at DESC);
CREATE INDEX idx_audit_logs_resource ON audit_logs(resource_type, resource_id);

-- ============================================================================
-- CONSENT RECORDS (DPDP compliance)
-- ============================================================================
CREATE TABLE consent_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  consent_type TEXT NOT NULL, -- 'data_processing', 'marketing', 'sharing_with_doctor'
  consented BOOLEAN NOT NULL,
  consent_text TEXT,
  ip_address INET,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- REVIEWS / RATINGS
-- ============================================================================
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  doctor_id UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
  appointment_id UUID REFERENCES appointments(id),
  rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- UPDATED_AT TRIGGER
-- ============================================================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOR tbl IN
    SELECT table_name FROM information_schema.columns
    WHERE column_name = 'updated_at' AND table_schema = 'public'
  LOOP
    EXECUTE format(
      'CREATE TRIGGER trg_%s_updated_at BEFORE UPDATE ON %I
       FOR EACH ROW EXECUTE FUNCTION update_updated_at()',
      tbl, tbl
    );
  END LOOP;
END;
$$;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Helper function: get user role
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS user_role AS $$
  SELECT role FROM profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Helper: check if user is super_admin
CREATE OR REPLACE FUNCTION is_super_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin');
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ---- PROFILES ----
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT USING (id = auth.uid());

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE USING (id = auth.uid());

CREATE POLICY "Super admin can view all profiles"
  ON profiles FOR SELECT USING (is_super_admin());

CREATE POLICY "Super admin can update all profiles"
  ON profiles FOR UPDATE USING (is_super_admin());

CREATE POLICY "Anyone can insert on signup"
  ON profiles FOR INSERT WITH CHECK (id = auth.uid());

CREATE POLICY "Doctors can view assigned patient profiles"
  ON profiles FOR SELECT USING (
    get_user_role() = 'doctor' AND id IN (
      SELECT a.patient_id FROM appointments a
      JOIN doctors d ON d.id = a.doctor_id
      WHERE d.profile_id = auth.uid()
    )
  );

-- ---- DOCTORS ----
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view verified doctors"
  ON doctors FOR SELECT USING (verification_status = 'verified' AND is_active = TRUE);

CREATE POLICY "Doctor can view/update own record"
  ON doctors FOR ALL USING (profile_id = auth.uid());

CREATE POLICY "Super admin manages doctors"
  ON doctors FOR ALL USING (is_super_admin());

CREATE POLICY "Clinic admin can view own doctors"
  ON doctors FOR SELECT USING (
    get_user_role() = 'clinic_admin' AND id IN (
      SELECT cd.doctor_id FROM clinic_doctors cd
      JOIN clinics c ON c.id = cd.clinic_id
      WHERE c.admin_profile_id = auth.uid()
    )
  );

-- ---- CLINICS ----
ALTER TABLE clinics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view verified clinics"
  ON clinics FOR SELECT USING (verification_status = 'verified' AND is_active = TRUE);

CREATE POLICY "Clinic admin manages own clinic"
  ON clinics FOR ALL USING (admin_profile_id = auth.uid());

CREATE POLICY "Super admin manages clinics"
  ON clinics FOR ALL USING (is_super_admin());

-- ---- CLINIC_DOCTORS ----
ALTER TABLE clinic_doctors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view clinic-doctor mappings"
  ON clinic_doctors FOR SELECT USING (TRUE);

CREATE POLICY "Clinic admin manages own clinic doctors"
  ON clinic_doctors FOR ALL USING (
    clinic_id IN (SELECT id FROM clinics WHERE admin_profile_id = auth.uid())
  );

CREATE POLICY "Super admin manages clinic doctors"
  ON clinic_doctors FOR ALL USING (is_super_admin());

-- ---- DOCTOR_SLOTS ----
ALTER TABLE doctor_slots ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active slots"
  ON doctor_slots FOR SELECT USING (is_active = TRUE);

CREATE POLICY "Doctor manages own slots"
  ON doctor_slots FOR ALL USING (
    doctor_id IN (SELECT id FROM doctors WHERE profile_id = auth.uid())
  );

CREATE POLICY "Clinic admin manages doctor slots for own clinic"
  ON doctor_slots FOR ALL USING (
    clinic_id IN (SELECT id FROM clinics WHERE admin_profile_id = auth.uid())
  );

-- ---- PATIENTS ----
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Patient sees own record"
  ON patients FOR ALL USING (profile_id = auth.uid());

CREATE POLICY "Doctor views assigned patients"
  ON patients FOR SELECT USING (
    get_user_role() = 'doctor' AND profile_id IN (
      SELECT a.patient_id FROM appointments a
      JOIN doctors d ON d.id = a.doctor_id WHERE d.profile_id = auth.uid()
    )
  );

CREATE POLICY "Super admin views all patients"
  ON patients FOR SELECT USING (is_super_admin());

-- ---- APPOINTMENTS ----
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Patient manages own appointments"
  ON appointments FOR ALL USING (patient_id = auth.uid());

CREATE POLICY "Doctor manages assigned appointments"
  ON appointments FOR ALL USING (
    doctor_id IN (SELECT id FROM doctors WHERE profile_id = auth.uid())
  );

CREATE POLICY "Clinic admin views clinic appointments"
  ON appointments FOR SELECT USING (
    clinic_id IN (SELECT id FROM clinics WHERE admin_profile_id = auth.uid())
  );

CREATE POLICY "Super admin manages all appointments"
  ON appointments FOR ALL USING (is_super_admin());

-- ---- CONSULTATIONS ----
ALTER TABLE consultations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Patient views own consultations"
  ON consultations FOR SELECT USING (
    appointment_id IN (SELECT id FROM appointments WHERE patient_id = auth.uid())
  );

CREATE POLICY "Doctor manages own consultations"
  ON consultations FOR ALL USING (
    appointment_id IN (
      SELECT id FROM appointments WHERE doctor_id IN (
        SELECT id FROM doctors WHERE profile_id = auth.uid()
      )
    )
  );

CREATE POLICY "Super admin manages consultations"
  ON consultations FOR ALL USING (is_super_admin());

-- ---- PRESCRIPTIONS ----
ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Patient views own prescriptions"
  ON prescriptions FOR SELECT USING (patient_id = auth.uid());

CREATE POLICY "Doctor manages own prescriptions"
  ON prescriptions FOR ALL USING (
    doctor_id IN (SELECT id FROM doctors WHERE profile_id = auth.uid())
  );

CREATE POLICY "Pharmacy views linked prescriptions"
  ON prescriptions FOR SELECT USING (
    get_user_role() = 'pharmacy_admin' AND id IN (
      SELECT prescription_id FROM pharmacy_orders
      WHERE pharmacy_id IN (SELECT id FROM pharmacies WHERE admin_profile_id = auth.uid())
    )
  );

CREATE POLICY "Super admin manages prescriptions"
  ON prescriptions FOR ALL USING (is_super_admin());

-- ---- PRESCRIPTION_ITEMS ----
ALTER TABLE prescription_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Viewable if prescription is viewable"
  ON prescription_items FOR SELECT USING (
    prescription_id IN (SELECT id FROM prescriptions WHERE patient_id = auth.uid())
    OR prescription_id IN (
      SELECT id FROM prescriptions WHERE doctor_id IN (
        SELECT id FROM doctors WHERE profile_id = auth.uid()
      )
    )
    OR is_super_admin()
  );

CREATE POLICY "Doctor inserts items"
  ON prescription_items FOR INSERT WITH CHECK (
    prescription_id IN (
      SELECT id FROM prescriptions WHERE doctor_id IN (
        SELECT id FROM doctors WHERE profile_id = auth.uid()
      )
    )
  );

-- ---- LABS ----
ALTER TABLE labs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone views verified labs"
  ON labs FOR SELECT USING (verification_status = 'verified' AND is_active = TRUE);

CREATE POLICY "Lab admin manages own lab"
  ON labs FOR ALL USING (admin_profile_id = auth.uid());

CREATE POLICY "Super admin manages labs"
  ON labs FOR ALL USING (is_super_admin());

-- ---- LAB_TESTS ----
ALTER TABLE lab_tests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone views active lab tests"
  ON lab_tests FOR SELECT USING (is_active = TRUE);

CREATE POLICY "Lab admin manages own tests"
  ON lab_tests FOR ALL USING (
    lab_id IN (SELECT id FROM labs WHERE admin_profile_id = auth.uid())
  );

CREATE POLICY "Super admin manages lab tests"
  ON lab_tests FOR ALL USING (is_super_admin());

-- ---- LAB_BOOKINGS ----
ALTER TABLE lab_bookings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Patient manages own lab bookings"
  ON lab_bookings FOR ALL USING (patient_id = auth.uid());

CREATE POLICY "Lab admin manages own bookings"
  ON lab_bookings FOR ALL USING (
    lab_id IN (SELECT id FROM labs WHERE admin_profile_id = auth.uid())
  );

CREATE POLICY "Assigned technician views booking"
  ON lab_bookings FOR SELECT USING (assigned_technician_id = auth.uid());

CREATE POLICY "Super admin manages lab bookings"
  ON lab_bookings FOR ALL USING (is_super_admin());

-- ---- LAB_RESULTS ----
ALTER TABLE lab_results ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Patient views own results"
  ON lab_results FOR SELECT USING (
    lab_booking_id IN (SELECT id FROM lab_bookings WHERE patient_id = auth.uid())
  );

CREATE POLICY "Lab admin manages results"
  ON lab_results FOR ALL USING (
    lab_booking_id IN (
      SELECT id FROM lab_bookings WHERE lab_id IN (
        SELECT id FROM labs WHERE admin_profile_id = auth.uid()
      )
    )
  );

CREATE POLICY "Super admin manages lab results"
  ON lab_results FOR ALL USING (is_super_admin());

-- ---- PHARMACIES ----
ALTER TABLE pharmacies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone views verified pharmacies"
  ON pharmacies FOR SELECT USING (verification_status = 'verified' AND is_active = TRUE);

CREATE POLICY "Pharmacy admin manages own pharmacy"
  ON pharmacies FOR ALL USING (admin_profile_id = auth.uid());

CREATE POLICY "Super admin manages pharmacies"
  ON pharmacies FOR ALL USING (is_super_admin());

-- ---- MEDICINES ----
ALTER TABLE medicines ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone views active medicines"
  ON medicines FOR SELECT USING (is_active = TRUE);

CREATE POLICY "Pharmacy admin manages own medicines"
  ON medicines FOR ALL USING (
    pharmacy_id IN (SELECT id FROM pharmacies WHERE admin_profile_id = auth.uid())
  );

-- ---- PHARMACY_ORDERS ----
ALTER TABLE pharmacy_orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Patient manages own orders"
  ON pharmacy_orders FOR ALL USING (patient_id = auth.uid());

CREATE POLICY "Pharmacy admin manages own orders"
  ON pharmacy_orders FOR ALL USING (
    pharmacy_id IN (SELECT id FROM pharmacies WHERE admin_profile_id = auth.uid())
  );

CREATE POLICY "Super admin manages pharmacy orders"
  ON pharmacy_orders FOR ALL USING (is_super_admin());

-- ---- PHARMACY_ORDER_ITEMS ----
ALTER TABLE pharmacy_order_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Viewable if order is viewable"
  ON pharmacy_order_items FOR SELECT USING (
    order_id IN (SELECT id FROM pharmacy_orders WHERE patient_id = auth.uid())
    OR order_id IN (
      SELECT id FROM pharmacy_orders WHERE pharmacy_id IN (
        SELECT id FROM pharmacies WHERE admin_profile_id = auth.uid()
      )
    )
    OR is_super_admin()
  );

CREATE POLICY "Pharmacy admin inserts order items"
  ON pharmacy_order_items FOR INSERT WITH CHECK (
    order_id IN (
      SELECT id FROM pharmacy_orders WHERE pharmacy_id IN (
        SELECT id FROM pharmacies WHERE admin_profile_id = auth.uid()
      )
    )
  );

-- ---- PAYMENTS ----
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Patient views own payments"
  ON payments FOR SELECT USING (patient_id = auth.uid());

CREATE POLICY "Patient creates payments"
  ON payments FOR INSERT WITH CHECK (patient_id = auth.uid());

CREATE POLICY "Super admin manages payments"
  ON payments FOR ALL USING (is_super_admin());

-- ---- VITALS ----
ALTER TABLE vitals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Patient manages own vitals"
  ON vitals FOR ALL USING (patient_id = auth.uid());

CREATE POLICY "Doctor views assigned patient vitals"
  ON vitals FOR SELECT USING (
    get_user_role() = 'doctor' AND patient_id IN (
      SELECT a.patient_id FROM appointments a
      JOIN doctors d ON d.id = a.doctor_id WHERE d.profile_id = auth.uid()
    )
  );

CREATE POLICY "Super admin views vitals"
  ON vitals FOR SELECT USING (is_super_admin());

-- ---- IOT_DEVICES ----
ALTER TABLE iot_devices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Patient manages own devices"
  ON iot_devices FOR ALL USING (patient_id = auth.uid());

-- ---- NOTIFICATIONS ----
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "User views own notifications"
  ON notifications FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "System inserts notifications"
  ON notifications FOR INSERT WITH CHECK (TRUE);

CREATE POLICY "User marks own notifications read"
  ON notifications FOR UPDATE USING (user_id = auth.uid());

-- ---- AUDIT_LOGS ----
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Super admin views audit logs"
  ON audit_logs FOR SELECT USING (is_super_admin());

CREATE POLICY "System inserts audit logs"
  ON audit_logs FOR INSERT WITH CHECK (TRUE);

-- ---- CONSENT_RECORDS ----
ALTER TABLE consent_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "User manages own consent"
  ON consent_records FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Super admin views consent records"
  ON consent_records FOR SELECT USING (is_super_admin());

-- ---- REVIEWS ----
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view reviews"
  ON reviews FOR SELECT USING (TRUE);

CREATE POLICY "Patient creates review"
  ON reviews FOR INSERT WITH CHECK (patient_id = auth.uid());

CREATE POLICY "Patient manages own reviews"
  ON reviews FOR UPDATE USING (patient_id = auth.uid());

-- ============================================================================
-- STORAGE BUCKETS (via Supabase Dashboard or API)
-- ============================================================================
-- Buckets: prescriptions, lab-results, avatars, kyc-documents, clinic-logos
-- (These are created via Supabase Storage API, documented in seed script)
