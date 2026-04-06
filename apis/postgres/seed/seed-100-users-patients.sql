-- Seed script: create 100 users and 100 patients
-- Safe to re-run because it uses ON CONFLICT DO NOTHING.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1) Create 100 users (all as doctors, so they can be used by patients.doctor_id)
INSERT INTO users (name, password_hash, cpf, email, crm, type, created_at, updated_at)
SELECT
  'User ' || gs AS name,
  crypt('123456', gen_salt('bf')) AS password_hash,
  LPAD((10000000000 + gs)::text, 11, '0') AS cpf,
  'seed_user_' || gs || '@example.com' AS email,
  'CRM' || LPAD(gs::text, 6, '0') AS crm,
  'doctor' AS type,
  NOW(),
  NOW()
FROM generate_series(1, 100) AS gs
ON CONFLICT DO NOTHING;

-- 2) Create 100 patients linked to seeded doctor users
WITH doctor_ids AS (
  SELECT array_agg(id ORDER BY email) AS ids
  FROM users
  WHERE type = 'doctor' AND email LIKE 'seed_user_%@example.com'
), generated_patients AS (
  SELECT
    gs AS n,
    (
      SELECT ids[((gs - 1) % array_length(ids, 1)) + 1]
      FROM doctor_ids
    ) AS doctor_id,
    'Patient ' || gs AS name,
    LPAD((20000000000 + gs)::text, 11, '0') AS cpf,
    (NOW() - make_interval(days => gs)) AS last_appointment
  FROM generate_series(1, 100) AS gs
)
INSERT INTO patients (doctor_id, name, cpf, last_appointment, created_at, updated_at)
SELECT
  gp.doctor_id,
  gp.name,
  gp.cpf,
  gp.last_appointment,
  NOW(),
  NOW()
FROM generated_patients gp
WHERE gp.doctor_id IS NOT NULL
ON CONFLICT DO NOTHING;
