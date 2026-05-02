CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  password_hash TEXT NOT NULL,
  cpf VARCHAR(14) UNIQUE,
  email VARCHAR(255) NOT NULL UNIQUE,
  crm VARCHAR(50) UNIQUE,
  image TEXT,
  type VARCHAR(20) NOT NULL CHECK (type IN ('doctor', 'admin')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE users ADD COLUMN IF NOT EXISTS image TEXT;

CREATE TABLE IF NOT EXISTS patients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  cpf VARCHAR(14) NOT NULL,
  last_appointment TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_patients_doctor_cpf UNIQUE (doctor_id, cpf)
);

CREATE TABLE IF NOT EXISTS appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  appointment_date TIMESTAMPTZ NOT NULL,
  age INT,
  sexual_orientation TEXT,
  marital_status TEXT CHECK (marital_status IN ('SINGLE', 'MARRIED', 'DIVORCED', 'WIDOWED', 'STABLE_UNION', 'OTHER')),
  concordant_partner BOOLEAN,
  occupation TEXT,
  comorbidities TEXT,
  previous_diseases TEXT,
  allergy TEXT,
  surgeries TEXT,
  medication_use TEXT,
  hiv_diagnosis_date TIMESTAMPTZ,
  cardiovascular_risk TEXT,
  neoplasm_screening TEXT,
  coinfection_screening TEXT,
  immunizations TEXT CHECK (immunizations IN ('COMPLETE', 'INCOMPLETE', 'NOT_INFORMED')),
  notes TEXT,
  zip_code VARCHAR(8),
  street TEXT,
  street_number TEXT,
  neighborhood TEXT,
  city TEXT,
  address_complement TEXT,
  current_art TEXT,
  adherence TEXT CHECK (adherence IN ('HIGH', 'MEDIUM', 'LOW', 'NOT_INFORMED')),
  last_viral_load TIMESTAMPTZ,
  cd4_nadir TEXT,
  virological_status TEXT,
  current_regimen TEXT,
  regimen_start_date TIMESTAMPTZ,
  previous_regimens TEXT,
  change_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS clinic_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  zip_code VARCHAR(8) NOT NULL,
  street TEXT NOT NULL,
  street_number TEXT NOT NULL,
  neighborhood TEXT,
  city TEXT,
  address_complement TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_patients_doctor_id ON patients(doctor_id);
CREATE INDEX IF NOT EXISTS idx_appointments_doctor_id ON appointments(doctor_id);
CREATE INDEX IF NOT EXISTS idx_appointments_patient_id ON appointments(patient_id);
CREATE INDEX IF NOT EXISTS idx_clinic_locations_doctor_id ON clinic_locations(doctor_id);
