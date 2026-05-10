import {
  BadRequestException,
  Injectable,
  NotFoundException,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { Pool } from 'pg';
import { PatientsService } from '../patients/patients.service';
import { Appointment } from './appointment.entity';
import { CreateAppointmentDto } from './dto/create-appointment.dto';
import { UpdateAppointmentDto } from './dto/update-appointment.dto';

type AppointmentListFilters = {
  doctorName?: string;
  doctorId?: string;
  patientName?: string;
  patientId?: string;
  page?: number;
  limit?: number;
};

type PaginatedResponse<T> = {
  data: T[];
  pagination: {
    page: number;
    perPage: number;
    total: number;
    totalPages: number;
    firstPage: boolean;
    lastPage: boolean;
  };
};

@Injectable()
export class AppointmentsService implements OnModuleInit, OnModuleDestroy {
  private readonly pool: Pool;

  constructor(private readonly patientsService: PatientsService) {
    this.pool = new Pool({
      host: process.env.DB_HOST ?? 'localhost',
      port: Number(process.env.DB_PORT ?? process.env.POSTGRES_PORT ?? 5433),
      database: process.env.DB_NAME ?? process.env.POSTGRES_DB ?? 'hivision',
      user: process.env.DB_USER ?? process.env.POSTGRES_USER ?? 'hivision',
      password: process.env.DB_PASSWORD ?? process.env.POSTGRES_PASSWORD ?? 'hivision123',
    });
  }

  async onModuleInit(): Promise<void> {
    await this.pool.query(`
      ALTER TABLE appointments
      ADD COLUMN IF NOT EXISTS bone_health TEXT,
      ADD COLUMN IF NOT EXISTS clinic_location_id UUID REFERENCES clinic_locations(id)
    `);
    await this.pool.query(`
      INSERT INTO clinic_locations (
        doctor_id,
        name,
        zip_code,
        street,
        street_number,
        neighborhood,
        city,
        address_complement,
        created_at,
        updated_at
      )
      SELECT DISTINCT
        a.doctor_id,
        'Local padrão',
        '00000000',
        'Endereço não informado',
        'S/N',
        NULL,
        COALESCE(NULLIF(a.city, ''), 'Não informado'),
        NULL,
        NOW(),
        NOW()
      FROM appointments a
      WHERE NOT EXISTS (
        SELECT 1
        FROM clinic_locations cl
        WHERE cl.doctor_id = a.doctor_id
      )
    `);
    await this.pool.query(`
      UPDATE appointments a
      SET clinic_location_id = loc.id
      FROM (
        SELECT DISTINCT ON (cl.doctor_id)
          cl.doctor_id,
          cl.id
        FROM clinic_locations cl
        ORDER BY cl.doctor_id, cl.created_at ASC
      ) AS loc
      WHERE a.doctor_id = loc.doctor_id
        AND a.clinic_location_id IS NULL
    `);
    await this.pool.query('SELECT 1');
  }

  async onModuleDestroy(): Promise<void> {
    await this.pool.end();
  }

  async create(dto: CreateAppointmentDto): Promise<Appointment> {
    await this.validateReferences(dto.doctorId, dto.patientId, dto.clinicLocationId);

    const { rows } = await this.pool.query<AppointmentRow>(
      `
        INSERT INTO appointments (
          doctor_id,
          patient_id,
          clinic_location_id,
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
        VALUES (
          $1, $2, $3, $4, $5, $6, $7, $8, $9, $10,
          $11, $12, $13, $14, $15, $16, $17, $18, $19, $20,
          $21, $22, $23, $24, $25, $26, $27, $28, $29, $30,
          $31, $32, $33, $34, $35, $36, NOW(), NOW()
        )
        RETURNING *
      `,
      [
        dto.doctorId,
        dto.patientId,
        dto.clinicLocationId,
        dto.appointmentDate,
        dto.age ?? null,
        dto.sexualOrientation ?? null,
        dto.maritalStatus ?? null,
        dto.concordantPartner ?? null,
        dto.occupation ?? null,
        dto.comorbidities ?? null,
        dto.previousDiseases ?? null,
        dto.allergy ?? null,
        dto.surgeries ?? null,
        dto.medicationUse ?? null,
        dto.hivDiagnosisDate ?? null,
        dto.cardiovascularRisk ?? null,
        dto.neoplasmScreening ?? null,
        dto.coinfectionScreening ?? null,
        dto.immunizations ?? null,
        dto.boneHealth ?? null,
        dto.notes ?? null,
        dto.zipCode ?? null,
        dto.street ?? null,
        dto.streetNumber ?? null,
        dto.neighborhood ?? null,
        dto.city ?? null,
        dto.addressComplement ?? null,
        dto.currentArt ?? null,
        dto.adherence ?? null,
        dto.lastViralLoad ?? null,
        dto.cd4Nadir ?? null,
        dto.virologicalStatus ?? null,
        dto.currentRegimen ?? null,
        dto.regimenStartDate ?? null,
        dto.previousRegimens ?? null,
        dto.changeReason ?? null,
      ],
    );

    return this.mapRowToAppointment(rows[0]);
  }

  async findAll(
    filters: AppointmentListFilters = {},
  ): Promise<Appointment[] | PaginatedResponse<Appointment>> {
    const values: any[] = [];
    const where: string[] = [];

    if (filters.doctorName?.trim()) {
      values.push(`%${filters.doctorName.trim().toLowerCase()}%`);
      where.push(
        `EXISTS (SELECT 1 FROM users u WHERE u.id = appointments.doctor_id AND LOWER(u.name) LIKE $${values.length})`,
      );
    }

    if (filters.doctorId?.trim()) {
      values.push(filters.doctorId.trim());
      where.push(`appointments.doctor_id = $${values.length}`);
    }

    if (filters.patientName?.trim()) {
      values.push(`%${filters.patientName.trim().toLowerCase()}%`);
      where.push(
        `EXISTS (SELECT 1 FROM patients p WHERE p.id = appointments.patient_id AND LOWER(p.name) LIKE $${values.length})`,
      );
    }

    if (filters.patientId?.trim()) {
      values.push(filters.patientId.trim());
      where.push(`appointments.patient_id = $${values.length}`);
    }

    const whereClause = where.length ? `WHERE ${where.join(' AND ')}` : '';
    const orderBy = 'ORDER BY appointment_date DESC, created_at DESC';
    const hasPagination = Number.isFinite(filters.page);

    if (!hasPagination) {
      const { rows } = await this.pool.query<AppointmentRow>(
        `SELECT * FROM appointments ${whereClause} ${orderBy}`,
        values,
      );
      return rows.map((row) => this.mapRowToAppointment(row));
    }

    const page = Math.max(1, Number(filters.page ?? 1));
    const perPage = Math.max(1, Math.min(100, Number(filters.limit ?? 20)));

    const totalResult = await this.pool.query<{ total: number }>(
      `SELECT COUNT(*)::int AS total FROM appointments ${whereClause}`,
      values,
    );
    const total = totalResult.rows[0]?.total ?? 0;
    const totalPages = Math.max(1, Math.ceil(total / perPage));
    const safePage = Math.min(page, totalPages);
    const offset = (safePage - 1) * perPage;

    const paginatedValues = [...values, perPage, offset];
    const limitIndex = values.length + 1;
    const offsetIndex = values.length + 2;

    const { rows } = await this.pool.query<AppointmentRow>(
      `
        SELECT * FROM appointments
        ${whereClause}
        ${orderBy}
        LIMIT $${limitIndex} OFFSET $${offsetIndex}
      `,
      paginatedValues,
    );

    return {
      data: rows.map((row) => this.mapRowToAppointment(row)),
      pagination: {
        page: safePage,
        perPage,
        total,
        totalPages,
        firstPage: safePage <= 1,
        lastPage: safePage >= totalPages,
      },
    };
  }

  async findOne(id: string): Promise<Appointment> {
    const { rows } = await this.pool.query<AppointmentRow>(
      'SELECT * FROM appointments WHERE id = $1 LIMIT 1',
      [id],
    );

    if (!rows.length) {
      throw new NotFoundException('Appointment not found');
    }

    return this.mapRowToAppointment(rows[0]);
  }

  async update(id: string, dto: UpdateAppointmentDto): Promise<Appointment> {
    const appointment = await this.findOne(id);

    if (dto.doctorId || dto.patientId || dto.clinicLocationId) {
      const doctorId = dto.doctorId ?? appointment.doctorId;
      const patientId = dto.patientId ?? appointment.patientId;
      const clinicLocationId = dto.clinicLocationId ?? appointment.clinicLocationId;
      await this.validateReferences(doctorId, patientId, clinicLocationId);
    }

    const updates: string[] = [];
    const values: Array<string | number | boolean | Date | null> = [];

    const setUpdate = (column: string, value: string | number | boolean | Date | null): void => {
      values.push(value);
      updates.push(`${column} = $${values.length}`);
    };

    if (dto.doctorId !== undefined) setUpdate('doctor_id', dto.doctorId);
    if (dto.patientId !== undefined) setUpdate('patient_id', dto.patientId);
    if (dto.clinicLocationId !== undefined) setUpdate('clinic_location_id', dto.clinicLocationId);
    if (dto.appointmentDate !== undefined) setUpdate('appointment_date', dto.appointmentDate);
    if (dto.age !== undefined) setUpdate('age', dto.age);
    if (dto.sexualOrientation !== undefined) setUpdate('sexual_orientation', dto.sexualOrientation);
    if (dto.maritalStatus !== undefined) setUpdate('marital_status', dto.maritalStatus);
    if (dto.concordantPartner !== undefined) setUpdate('concordant_partner', dto.concordantPartner);
    if (dto.occupation !== undefined) setUpdate('occupation', dto.occupation);
    if (dto.comorbidities !== undefined) setUpdate('comorbidities', dto.comorbidities);
    if (dto.previousDiseases !== undefined) setUpdate('previous_diseases', dto.previousDiseases);
    if (dto.allergy !== undefined) setUpdate('allergy', dto.allergy);
    if (dto.surgeries !== undefined) setUpdate('surgeries', dto.surgeries);
    if (dto.medicationUse !== undefined) setUpdate('medication_use', dto.medicationUse);
    if (dto.hivDiagnosisDate !== undefined) setUpdate('hiv_diagnosis_date', dto.hivDiagnosisDate);
    if (dto.cardiovascularRisk !== undefined)
      setUpdate('cardiovascular_risk', dto.cardiovascularRisk);
    if (dto.neoplasmScreening !== undefined) setUpdate('neoplasm_screening', dto.neoplasmScreening);
    if (dto.coinfectionScreening !== undefined)
      setUpdate('coinfection_screening', dto.coinfectionScreening);
    if (dto.immunizations !== undefined) setUpdate('immunizations', dto.immunizations);
    if (dto.boneHealth !== undefined) setUpdate('bone_health', dto.boneHealth);
    if (dto.notes !== undefined) setUpdate('notes', dto.notes);
    if (dto.zipCode !== undefined) setUpdate('zip_code', dto.zipCode);
    if (dto.street !== undefined) setUpdate('street', dto.street);
    if (dto.streetNumber !== undefined) setUpdate('street_number', dto.streetNumber);
    if (dto.neighborhood !== undefined) setUpdate('neighborhood', dto.neighborhood);
    if (dto.city !== undefined) setUpdate('city', dto.city);
    if (dto.addressComplement !== undefined) setUpdate('address_complement', dto.addressComplement);
    if (dto.currentArt !== undefined) setUpdate('current_art', dto.currentArt);
    if (dto.adherence !== undefined) setUpdate('adherence', dto.adherence);
    if (dto.lastViralLoad !== undefined) setUpdate('last_viral_load', dto.lastViralLoad);
    if (dto.cd4Nadir !== undefined) setUpdate('cd4_nadir', dto.cd4Nadir);
    if (dto.virologicalStatus !== undefined) setUpdate('virological_status', dto.virologicalStatus);
    if (dto.currentRegimen !== undefined) setUpdate('current_regimen', dto.currentRegimen);
    if (dto.regimenStartDate !== undefined) setUpdate('regimen_start_date', dto.regimenStartDate);
    if (dto.previousRegimens !== undefined) setUpdate('previous_regimens', dto.previousRegimens);
    if (dto.changeReason !== undefined) setUpdate('change_reason', dto.changeReason);

    if (!updates.length) {
      return appointment;
    }

    updates.push('updated_at = NOW()');
    values.push(id);

    const { rows } = await this.pool.query<AppointmentRow>(
      `UPDATE appointments SET ${updates.join(', ')} WHERE id = $${values.length} RETURNING *`,
      values,
    );

    return this.mapRowToAppointment(rows[0]);
  }

  async remove(id: string): Promise<void> {
    const result = await this.pool.query('DELETE FROM appointments WHERE id = $1 RETURNING id', [
      id,
    ]);

    if (!result.rowCount) {
      throw new NotFoundException('Appointment not found');
    }
  }

  private async validateReferences(
    doctorId: string,
    patientId: string,
    clinicLocationId: string,
  ): Promise<void> {
    const doctorResult = await this.pool.query<{ exists: boolean }>(
      `SELECT EXISTS(SELECT 1 FROM users WHERE id = $1 AND type = 'doctor') AS exists`,
      [doctorId],
    );

    if (!(doctorResult.rows[0]?.exists ?? false)) {
      throw new BadRequestException('Doctor not found');
    }

    if (!(await this.patientsService.exists(patientId))) {
      throw new BadRequestException('Patient not found');
    }

    const clinicLocationResult = await this.pool.query<{ exists: boolean }>(
      `
        SELECT EXISTS(
          SELECT 1
          FROM clinic_locations
          WHERE id = $1 AND doctor_id = $2
        ) AS exists
      `,
      [clinicLocationId, doctorId],
    );

    if (!(clinicLocationResult.rows[0]?.exists ?? false)) {
      throw new BadRequestException('Clinic location not found for this doctor');
    }
  }

  private mapRowToAppointment(row: AppointmentRow): Appointment {
    return {
      id: row.id,
      doctorId: row.doctor_id,
      patientId: row.patient_id,
      clinicLocationId: row.clinic_location_id,
      appointmentDate: row.appointment_date,
      age: row.age ?? undefined,
      sexualOrientation: row.sexual_orientation ?? undefined,
      maritalStatus: row.marital_status ?? undefined,
      concordantPartner: row.concordant_partner ?? undefined,
      occupation: row.occupation ?? undefined,
      comorbidities: row.comorbidities ?? undefined,
      previousDiseases: row.previous_diseases ?? undefined,
      allergy: row.allergy ?? undefined,
      surgeries: row.surgeries ?? undefined,
      medicationUse: row.medication_use ?? undefined,
      hivDiagnosisDate: row.hiv_diagnosis_date ?? undefined,
      cardiovascularRisk: row.cardiovascular_risk ?? undefined,
      neoplasmScreening: row.neoplasm_screening ?? undefined,
      coinfectionScreening: row.coinfection_screening ?? undefined,
      immunizations: row.immunizations ?? undefined,
      boneHealth: row.bone_health ?? undefined,
      notes: row.notes ?? undefined,
      zipCode: row.zip_code ?? undefined,
      street: row.street ?? undefined,
      streetNumber: row.street_number ?? undefined,
      neighborhood: row.neighborhood ?? undefined,
      city: row.city ?? undefined,
      addressComplement: row.address_complement ?? undefined,
      currentArt: row.current_art ?? undefined,
      adherence: row.adherence ?? undefined,
      lastViralLoad: row.last_viral_load ?? undefined,
      cd4Nadir: row.cd4_nadir ?? undefined,
      virologicalStatus: row.virological_status ?? undefined,
      currentRegimen: row.current_regimen ?? undefined,
      regimenStartDate: row.regimen_start_date ?? undefined,
      previousRegimens: row.previous_regimens ?? undefined,
      changeReason: row.change_reason ?? undefined,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    };
  }
}

type AppointmentRow = {
  id: string;
  doctor_id: string;
  patient_id: string;
  clinic_location_id: string;
  appointment_date: Date;
  age: number | null;
  sexual_orientation: string | null;
  marital_status: Appointment['maritalStatus'] | null;
  concordant_partner: boolean | null;
  occupation: string | null;
  comorbidities: string | null;
  previous_diseases: string | null;
  allergy: string | null;
  surgeries: string | null;
  medication_use: string | null;
  hiv_diagnosis_date: Date | null;
  cardiovascular_risk: string | null;
  neoplasm_screening: string | null;
  coinfection_screening: string | null;
  immunizations: Appointment['immunizations'] | null;
  bone_health: Appointment['boneHealth'] | null;
  notes: string | null;
  zip_code: string | null;
  street: string | null;
  street_number: string | null;
  neighborhood: string | null;
  city: string | null;
  address_complement: string | null;
  current_art: string | null;
  adherence: Appointment['adherence'] | null;
  last_viral_load: Date | null;
  cd4_nadir: string | null;
  virological_status: string | null;
  current_regimen: string | null;
  regimen_start_date: Date | null;
  previous_regimens: string | null;
  change_reason: string | null;
  created_at: Date;
  updated_at: Date;
};
