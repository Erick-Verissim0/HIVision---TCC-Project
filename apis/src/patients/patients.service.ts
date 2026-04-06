import {
  BadRequestException,
  Injectable,
  NotFoundException,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { Pool } from 'pg';
import { CreatePatientDto } from './dto/create-patient.dto';
import { UpdatePatientDto } from './dto/update-patient.dto';
import { Patient } from './patient.entity';

type PatientRow = {
  id: string;
  doctor_id: string;
  name: string;
  cpf: string;
  last_appointment: Date | null;
  created_at: Date;
  updated_at: Date;
};

type PatientListFilters = {
  name?: string;
  cpf?: string;
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
export class PatientsService implements OnModuleInit, OnModuleDestroy {
  private readonly pool: Pool;

  constructor() {
    this.pool = new Pool({
      host: process.env.DB_HOST ?? 'localhost',
      port: Number(process.env.DB_PORT ?? process.env.POSTGRES_PORT ?? 5433),
      database: process.env.DB_NAME ?? process.env.POSTGRES_DB ?? 'hivision',
      user: process.env.DB_USER ?? process.env.POSTGRES_USER ?? 'hivision',
      password: process.env.DB_PASSWORD ?? process.env.POSTGRES_PASSWORD ?? 'hivision123',
    });
  }

  async onModuleInit(): Promise<void> {
    await this.pool.query('SELECT 1');
  }

  async onModuleDestroy(): Promise<void> {
    await this.pool.end();
  }

  async create(dto: CreatePatientDto): Promise<Patient> {
    const cpf = this.normalizeCpf(dto.cpf);
    try {
      const { rows } = await this.pool.query<PatientRow>(
        `
          INSERT INTO patients (doctor_id, name, cpf, last_appointment, created_at, updated_at)
          VALUES ($1, $2, $3, $4, NOW(), NOW())
          RETURNING *
        `,
        [dto.doctorId, dto.name, cpf, dto.lastAppointment ?? null],
      );
      return this.mapRowToPatient(rows[0]);
    } catch (error: any) {
      if (error.code === '23503') throw new BadRequestException('Doctor not found');
      if (error.code === '23505')
        throw new BadRequestException(
          'A patient with this CPF is already registered for this doctor',
        );
      throw error;
    }
  }

  async findAll(filters: PatientListFilters = {}): Promise<Patient[] | PaginatedResponse<Patient>> {
    const values: any[] = [];
    const where: string[] = [];

    if (filters.name?.trim()) {
      values.push(`%${filters.name.trim().toLowerCase()}%`);
      where.push(`LOWER(name) LIKE $${values.length}`);
    }

    if (filters.cpf?.trim()) {
      const normalizedCpf = this.normalizeCpf(filters.cpf);
      if (normalizedCpf) {
        values.push(`%${normalizedCpf}%`);
        where.push(`cpf LIKE $${values.length}`);
      }
    }

    const whereClause = where.length ? `WHERE ${where.join(' AND ')}` : '';
    const hasPagination = Number.isFinite(filters.page);

    if (!hasPagination) {
      const { rows } = await this.pool.query<PatientRow>(
        `SELECT * FROM patients ${whereClause} ORDER BY LOWER(name) ASC, created_at DESC`,
        values,
      );
      return rows.map((row) => this.mapRowToPatient(row));
    }

    const page = Math.max(1, Number(filters.page ?? 1));
    const perPage = Math.max(1, Math.min(100, Number(filters.limit ?? 20)));

    const totalResult = await this.pool.query<{ total: number }>(
      `SELECT COUNT(*)::int AS total FROM patients ${whereClause}`,
      values,
    );
    const total = totalResult.rows[0]?.total ?? 0;
    const totalPages = Math.max(1, Math.ceil(total / perPage));
    const safePage = Math.min(page, totalPages);
    const offset = (safePage - 1) * perPage;

    const paginatedValues = [...values, perPage, offset];
    const limitIndex = values.length + 1;
    const offsetIndex = values.length + 2;

    const { rows } = await this.pool.query<PatientRow>(
      `
        SELECT * FROM patients
        ${whereClause}
        ORDER BY LOWER(name) ASC, created_at DESC
        LIMIT $${limitIndex} OFFSET $${offsetIndex}
      `,
      paginatedValues,
    );

    return {
      data: rows.map((row) => this.mapRowToPatient(row)),
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

  async findOne(id: string): Promise<Patient> {
    const { rows } = await this.pool.query<PatientRow>(
      'SELECT * FROM patients WHERE id = $1 LIMIT 1',
      [id],
    );
    if (!rows.length) throw new NotFoundException('Patient not found');
    return this.mapRowToPatient(rows[0]);
  }

  async update(id: string, dto: UpdatePatientDto): Promise<Patient> {
    const updates: string[] = [];
    const values: any[] = [];

    if (dto.name !== undefined) {
      values.push(dto.name);
      updates.push(`name = $${values.length}`);
    }
    if (dto.cpf !== undefined) {
      values.push(this.normalizeCpf(dto.cpf));
      updates.push(`cpf = $${values.length}`);
    }
    if (dto.doctorId !== undefined) {
      values.push(dto.doctorId);
      updates.push(`doctor_id = $${values.length}`);
    }
    if (dto.lastAppointment !== undefined) {
      values.push(dto.lastAppointment ?? null);
      updates.push(`last_appointment = $${values.length}`);
    }

    if (!updates.length) return this.findOne(id);

    updates.push('updated_at = NOW()');
    values.push(id);

    try {
      const { rows } = await this.pool.query<PatientRow>(
        `UPDATE patients SET ${updates.join(', ')} WHERE id = $${values.length} RETURNING *`,
        values,
      );
      if (!rows.length) throw new NotFoundException('Patient not found');
      return this.mapRowToPatient(rows[0]);
    } catch (error: any) {
      if (error.code === '23503') throw new BadRequestException('Doctor not found');
      if (error.code === '23505')
        throw new BadRequestException(
          'A patient with this CPF is already registered for this doctor',
        );
      throw error;
    }
  }

  async remove(id: string): Promise<void> {
    const result = await this.pool.query('DELETE FROM patients WHERE id = $1 RETURNING id', [id]);
    if (!result.rowCount) throw new NotFoundException('Patient not found');
  }

  async exists(id: string): Promise<boolean> {
    const { rows } = await this.pool.query<{ exists: boolean }>(
      'SELECT EXISTS(SELECT 1 FROM patients WHERE id = $1) AS exists',
      [id],
    );
    return rows[0]?.exists ?? false;
  }

  private normalizeCpf(cpf: string): string {
    return cpf.replace(/\D/g, '');
  }

  private mapRowToPatient(row: PatientRow): Patient {
    return {
      id: row.id,
      doctorId: row.doctor_id,
      name: row.name,
      cpf: row.cpf,
      lastAppointment: row.last_appointment ?? undefined,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    };
  }
}
