CREATE EXTENSION IF NOT EXISTS pgcrypto;

WITH upsert_doctor AS (
  INSERT INTO users (name, password_hash, cpf, email, crm, type, created_at, updated_at)
  VALUES (
    'Jorge Ferreira',
    crypt('123456', gen_salt('bf')),
    '999.888.777-66',
    'jorge.ferreira@hivision.local',
    'CRM1234567',
    'doctor',
    NOW(),
    NOW()
  )
  ON CONFLICT (email)
  DO UPDATE SET
    name = EXCLUDED.name,
    crm = EXCLUDED.crm,
    type = 'doctor',
    updated_at = NOW()
  RETURNING id
), doctor_row AS (
  SELECT id FROM upsert_doctor
  UNION ALL
  SELECT id FROM users WHERE email = 'jorge.ferreira@hivision.local' LIMIT 1
), generated_patients AS (
  SELECT
    (SELECT id FROM doctor_row LIMIT 1) AS doctor_id,
    gs AS n,
    (
      (ARRAY[
        'Ana', 'Bruno', 'Carla', 'Daniel', 'Eduarda', 'Felipe', 'Gabriela', 'Henrique',
        'Isabela', 'Joao', 'Karina', 'Lucas', 'Mariana', 'Nicolas', 'Patricia', 'Rafael',
        'Sabrina', 'Thiago', 'Vanessa', 'William', 'Yasmin', 'Caio', 'Bianca', 'Leandro',
        'Renata'
      ])[((gs - 1) % 25) + 1]
      || ' ' ||
      (ARRAY[
        'Almeida', 'Barbosa', 'Cardoso', 'Dias', 'Esteves', 'Ferreira', 'Gomes', 'Lima',
        'Mendes', 'Nogueira', 'Oliveira', 'Pereira', 'Queiroz', 'Ribeiro', 'Silva', 'Souza'
      ])[((gs * 5 - 1) % 16) + 1]
      || ' ' ||
      (ARRAY[
        'da Silva', 'dos Santos', 'de Oliveira', 'de Souza', 'de Lima', 'de Almeida',
        'de Araujo', 'de Carvalho', 'de Castro', 'de Moraes', 'de Barros', 'de Freitas',
        'de Melo', 'de Andrade', 'de Queiroz', 'de Farias', 'de Miranda', 'de Moura',
        'de Matos'
      ])[((gs * 3 - 1) % 17) + 1]
    ) AS name,
    LPAD((70000000000 + gs)::text, 11, '0') AS cpf,
    (NOW() - make_interval(days => gs::int)) AS last_appointment,
    18 + (gs % 63) AS age,
    (NOW() - make_interval(days => (7000 + gs)::int)) AS birth_date,
    CASE
      WHEN gs % 5 = 0 THEN 'Casado(a)'
      WHEN gs % 5 = 1 THEN 'Solteiro(a)'
      WHEN gs % 5 = 2 THEN 'Divorciado(a)'
      WHEN gs % 5 = 3 THEN 'União estável'
      ELSE 'Outro'
    END AS marital_status,
    'Ocupação ' || gs AS profession,
    'Histórico prévio ' || gs AS previous_diseases,
    'Alergia ' || gs AS allergies,
    'Medicamento em uso ' || gs AS medications,
    'Saúde óssea paciente ' || gs AS bone_health
  FROM generate_series(1, 200) AS gs
), upsert_patients AS (
  INSERT INTO patients (
    doctor_id, name, cpf, last_appointment, age, birth_date, marital_status,
    profession, previous_diseases, allergies, medications, bone_health, created_at, updated_at
  )
  SELECT
    gp.doctor_id,
    gp.name,
    gp.cpf,
    gp.last_appointment,
    gp.age,
    gp.birth_date,
    gp.marital_status,
    gp.profession,
    gp.previous_diseases,
    gp.allergies,
    gp.medications,
    gp.bone_health,
    NOW(),
    NOW()
  FROM generated_patients gp
  ON CONFLICT (doctor_id, cpf)
  DO UPDATE SET
    name = EXCLUDED.name,
    last_appointment = EXCLUDED.last_appointment,
    age = EXCLUDED.age,
    birth_date = EXCLUDED.birth_date,
    marital_status = EXCLUDED.marital_status,
    profession = EXCLUDED.profession,
    previous_diseases = EXCLUDED.previous_diseases,
    allergies = EXCLUDED.allergies,
    medications = EXCLUDED.medications,
    bone_health = EXCLUDED.bone_health,
    updated_at = NOW()
  RETURNING id
), doctor_patients AS (
  SELECT id, row_number() OVER (ORDER BY cpf) AS rn
  FROM patients
  WHERE doctor_id = (SELECT id FROM doctor_row LIMIT 1)
), appointment_payload AS (
  SELECT
    (SELECT id FROM doctor_row LIMIT 1) AS doctor_id,
    (SELECT id FROM doctor_patients WHERE rn = ((gs - 1) % 200) + 1) AS patient_id,
    (NOW() - make_interval(days => ((gs - 1) / 5)::int) + make_interval(mins => gs::int)) AS appointment_date,
    18 + (gs % 63) AS age,
    CASE WHEN gs % 2 = 0 THEN 'Heterossexual' ELSE 'Homossexual' END AS sexual_orientation,
    CASE
      WHEN gs % 5 = 0 THEN 'Casado(a)'
      WHEN gs % 5 = 1 THEN 'Solteiro(a)'
      WHEN gs % 5 = 2 THEN 'Divorciado(a)'
      WHEN gs % 5 = 3 THEN 'União estável'
      ELSE 'Outro'
    END AS marital_status,
    (gs % 2 = 0) AS concordant_partner,
    'Ocupação consulta ' || gs AS occupation,
    'Comorbidades consulta ' || gs AS comorbidities,
    'Doenças prévias consulta ' || gs AS previous_diseases,
    'Alergia consulta ' || gs AS allergy,
    'Cirurgia consulta ' || gs AS surgeries,
    'Medicação consulta ' || gs AS medication_use,
    (NOW() - make_interval(days => (4500 + gs)::int)) AS hiv_diagnosis_date,
    'Risco cardiovascular ' || gs AS cardiovascular_risk,
    'Rastreamento de neoplasias ' || gs AS neoplasm_screening,
    'Rastreamento de coinfecções ' || gs AS coinfection_screening,
    CASE WHEN gs % 3 = 0 THEN 'Completo' WHEN gs % 3 = 1 THEN 'Incompleto' ELSE 'Não informado' END AS immunizations,
    'Saúde óssea consulta ' || gs AS bone_health,
    'Observações da consulta ' || gs AS notes,
    LPAD((12000000 + (gs % 1000))::text, 8, '0') AS zip_code,
    'Rua Consulta ' || gs AS street,
    ((gs % 999) + 1)::text AS street_number,
    'Bairro Consulta ' || gs AS neighborhood,
    'Cidade Consulta' AS city,
    'Complemento ' || gs AS address_complement,
    'ART atual ' || gs AS current_art,
    CASE WHEN gs % 4 = 0 THEN 'Alta' WHEN gs % 4 = 1 THEN 'Média' WHEN gs % 4 = 2 THEN 'Baixa' ELSE 'Não informada' END AS adherence,
    (NOW() - make_interval(days => (30 + (gs % 365))::int)) AS last_viral_load,
    'CD4 nadir ' || gs AS cd4_nadir,
    'Status virológico ' || gs AS virological_status,
    'Esquema atual ' || gs AS current_regimen,
    (NOW() - make_interval(days => (180 + (gs % 365))::int)) AS regimen_start_date,
    'Esquemas anteriores ' || gs AS previous_regimens,
    'Motivo de mudança ' || gs AS change_reason
  FROM generate_series(1, 1000) AS gs
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
  bone_health,
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
  ap.bone_health,
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
WHERE ap.patient_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1
    FROM appointments a
    WHERE a.doctor_id = ap.doctor_id
      AND a.patient_id = ap.patient_id
      AND a.appointment_date = ap.appointment_date
  );
