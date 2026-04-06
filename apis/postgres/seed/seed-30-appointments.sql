-- Seed script: create 30 appointments
-- Safe to re-run: inserts only when an equivalent appointment does not already exist.

WITH selected_pairs AS (
  SELECT
    p.doctor_id,
    p.id AS patient_id,
    row_number() OVER (ORDER BY p.created_at ASC, p.id ASC) AS rn
  FROM patients p
  LIMIT 30
), appointment_payload AS (
  SELECT
    sp.doctor_id,
    sp.patient_id,
    (NOW() - make_interval(days => sp.rn::int) + make_interval(hours => (8 + (sp.rn % 9))::int)) AS appointment_date,
    20 + (sp.rn % 40) AS age,
    CASE WHEN sp.rn % 2 = 0 THEN 'Heterossexual' ELSE 'Homossexual' END AS sexual_orientation,
    CASE
      WHEN sp.rn % 5 = 0 THEN 'MARRIED'
      WHEN sp.rn % 5 = 1 THEN 'SINGLE'
      WHEN sp.rn % 5 = 2 THEN 'DIVORCED'
      WHEN sp.rn % 5 = 3 THEN 'STABLE_UNION'
      ELSE 'OTHER'
    END AS marital_status,
    (sp.rn % 2 = 0) AS concordant_partner,
    'Ocupação ' || sp.rn AS occupation,
    'Comorbidades exemplo ' || sp.rn AS comorbidities,
    'Doenças prévias exemplo ' || sp.rn AS previous_diseases,
    'Alergia exemplo ' || sp.rn AS allergy,
    'Cirurgia exemplo ' || sp.rn AS surgeries,
    'Medicação exemplo ' || sp.rn AS medication_use,
    (NOW() - make_interval(days => (3650 + sp.rn)::int)) AS hiv_diagnosis_date,
    'Risco cardiovascular exemplo ' || sp.rn AS cardiovascular_risk,
    'Rastreamento de neoplasia ' || sp.rn AS neoplasm_screening,
    'Rastreamento de coinfecção ' || sp.rn AS coinfection_screening,
    CASE WHEN sp.rn % 3 = 0 THEN 'COMPLETE' WHEN sp.rn % 3 = 1 THEN 'INCOMPLETE' ELSE 'NOT_INFORMED' END AS immunizations,
    'Observações da consulta ' || sp.rn AS notes,
    LPAD((11000000 + sp.rn)::text, 8, '0') AS zip_code,
    'Rua Consulta ' || sp.rn AS street,
    sp.rn::text AS street_number,
    'Bairro Consulta ' || sp.rn AS neighborhood,
    'Cidade Consulta ' || sp.rn AS city,
    'Complemento Consulta ' || sp.rn AS address_complement,
    'ART atual ' || sp.rn AS current_art,
    CASE WHEN sp.rn % 4 = 0 THEN 'HIGH' WHEN sp.rn % 4 = 1 THEN 'MEDIUM' WHEN sp.rn % 4 = 2 THEN 'LOW' ELSE 'NOT_INFORMED' END AS adherence,
    (NOW() - make_interval(days => (30 + sp.rn)::int)) AS last_viral_load,
    'CD4 nadir ' || sp.rn AS cd4_nadir,
    'Status virológico ' || sp.rn AS virological_status,
    'Esquema atual ' || sp.rn AS current_regimen,
    (NOW() - make_interval(days => (180 + sp.rn)::int)) AS regimen_start_date,
    'Esquemas anteriores ' || sp.rn AS previous_regimens,
    'Motivo de mudança ' || sp.rn AS change_reason
  FROM selected_pairs sp
)
INSERT INTO appointments (
  doctor_id,
  patient_id,
  appointment_date,
  age,
  sexual_orientation,
  marital_status,
  concordant_partner,
  occupation,
  comorbidities,
  previous_diseases,
  allergy,
  surgeries,
  medication_use,
  hiv_diagnosis_date,
  cardiovascular_risk,
  neoplasm_screening,
  coinfection_screening,
  immunizations,
  notes,
  zip_code,
  street,
  street_number,
  neighborhood,
  city,
  address_complement,
  current_art,
  adherence,
  last_viral_load,
  cd4_nadir,
  virological_status,
  current_regimen,
  regimen_start_date,
  previous_regimens,
  change_reason,
  created_at,
  updated_at
)
SELECT
  ap.doctor_id,
  ap.patient_id,
  ap.appointment_date,
  ap.age,
  ap.sexual_orientation,
  ap.marital_status,
  ap.concordant_partner,
  ap.occupation,
  ap.comorbidities,
  ap.previous_diseases,
  ap.allergy,
  ap.surgeries,
  ap.medication_use,
  ap.hiv_diagnosis_date,
  ap.cardiovascular_risk,
  ap.neoplasm_screening,
  ap.coinfection_screening,
  ap.immunizations,
  ap.notes,
  ap.zip_code,
  ap.street,
  ap.street_number,
  ap.neighborhood,
  ap.city,
  ap.address_complement,
  ap.current_art,
  ap.adherence,
  ap.last_viral_load,
  ap.cd4_nadir,
  ap.virological_status,
  ap.current_regimen,
  ap.regimen_start_date,
  ap.previous_regimens,
  ap.change_reason,
  NOW(),
  NOW()
FROM appointment_payload ap
WHERE NOT EXISTS (
  SELECT 1
  FROM appointments a
  WHERE a.doctor_id = ap.doctor_id
    AND a.patient_id = ap.patient_id
    AND a.appointment_date = ap.appointment_date
);
