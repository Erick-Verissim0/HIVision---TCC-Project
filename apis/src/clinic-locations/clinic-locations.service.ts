import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { Pool } from 'pg';
import { UsersService } from '../users/users.service';
import { CreateClinicLocationDto } from './dto/create-clinic-location.dto';
import { UpdateClinicLocationDto } from './dto/update-clinic-location.dto';
import { ClinicLocation } from './clinic-location.entity';

type ClinicLocationListFilters = {
  city?: string;
  street?: string;
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
export class ClinicLocationsService implements OnModuleInit, OnModuleDestroy {
  private readonly pool: Pool;

  constructor(private readonly doctorsService: UsersService) {
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

  async create(dto: CreateClinicLocationDto): Promise<ClinicLocation> {
    if (!this.doctorsService.exists(dto.doctorId)) {
      throw new BadRequestException('Doctor not found');
    }

    const { rows } = await this.pool.query<ClinicLocationRow>(
      `
        INSERT INTO clinic_locations (
          doctor_id,
          zip_code,
          street,
          street_number,
          neighborhood,
          city,
          address_complement,
          created_at,
          updated_at
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), NOW())
        RETURNING *
      `,
      [
        dto.doctorId,
        this.normalizeZipCode(dto.zipCode),
        dto.street,
        dto.streetNumber,
        dto.neighborhood ?? null,
        dto.city ?? null,
        dto.addressComplement ?? null,
      ],
    );

    return this.mapRowToClinicLocation(rows[0]);
  }

  async findAll(
    filters: ClinicLocationListFilters = {},
  ): Promise<ClinicLocation[] | PaginatedResponse<ClinicLocation>> {
    const values: any[] = [];
    const where: string[] = [];

    if (filters.city?.trim()) {
      values.push(`%${filters.city.trim().toLowerCase()}%`);
      where.push(`LOWER(city) LIKE $${values.length}`);
    }

    if (filters.street?.trim()) {
      values.push(`%${filters.street.trim().toLowerCase()}%`);
      where.push(`LOWER(street) LIKE $${values.length}`);
    }

    const whereClause = where.length ? `WHERE ${where.join(' AND ')}` : '';

    const hasPagination = Number.isFinite(filters.page);
    if (!hasPagination) {
      const { rows } = await this.pool.query<ClinicLocationRow>(
        `SELECT * FROM clinic_locations ${whereClause} ORDER BY created_at DESC`,
        values,
      );
      return rows.map((row) => this.mapRowToClinicLocation(row));
    }

    const page = Math.max(1, Number(filters.page ?? 1));
    const perPage = Math.max(1, Math.min(100, Number(filters.limit ?? 20)));

    const totalResult = await this.pool.query<{ total: number }>(
      `SELECT COUNT(*)::int AS total FROM clinic_locations ${whereClause}`,
      values,
    );
    const total = totalResult.rows[0]?.total ?? 0;
    const totalPages = Math.max(1, Math.ceil(total / perPage));
    const safePage = Math.min(page, totalPages);
    const offset = (safePage - 1) * perPage;

    const paginatedValues = [...values, perPage, offset];
    const limitIndex = values.length + 1;
    const offsetIndex = values.length + 2;

    const { rows } = await this.pool.query<ClinicLocationRow>(
      `
        SELECT * FROM clinic_locations
        ${whereClause}
        ORDER BY created_at DESC
        LIMIT $${limitIndex} OFFSET $${offsetIndex}
      `,
      paginatedValues,
    );

    return {
      data: rows.map((row) => this.mapRowToClinicLocation(row)),
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

  async findOne(id: string): Promise<ClinicLocation> {
    const { rows } = await this.pool.query<ClinicLocationRow>(
      'SELECT * FROM clinic_locations WHERE id = $1 LIMIT 1',
      [id],
    );

    if (!rows.length) {
      throw new NotFoundException('Clinic location not found');
    }

    return this.mapRowToClinicLocation(rows[0]);
  }

  async update(id: string, dto: UpdateClinicLocationDto): Promise<ClinicLocation> {
    await this.findOne(id);

    if (dto.doctorId && !this.doctorsService.exists(dto.doctorId)) {
      throw new BadRequestException('Doctor not found');
    }

    const updates: string[] = [];
    const values: Array<string | null> = [];

    const setUpdate = (column: string, value: string | null): void => {
      values.push(value);
      updates.push(`${column} = $${values.length}`);
    };

    if (dto.doctorId !== undefined) setUpdate('doctor_id', dto.doctorId);
    if (dto.zipCode !== undefined) setUpdate('zip_code', this.normalizeZipCode(dto.zipCode));
    if (dto.street !== undefined) setUpdate('street', dto.street);
    if (dto.streetNumber !== undefined) setUpdate('street_number', dto.streetNumber);
    if (dto.neighborhood !== undefined) setUpdate('neighborhood', dto.neighborhood ?? null);
    if (dto.city !== undefined) setUpdate('city', dto.city ?? null);
    if (dto.addressComplement !== undefined) {
      setUpdate('address_complement', dto.addressComplement ?? null);
    }

    if (!updates.length) {
      return this.findOne(id);
    }

    updates.push('updated_at = NOW()');
    values.push(id);

    const { rows } = await this.pool.query<ClinicLocationRow>(
      `UPDATE clinic_locations SET ${updates.join(', ')} WHERE id = $${values.length} RETURNING *`,
      values,
    );

    return this.mapRowToClinicLocation(rows[0]);
  }

  async remove(id: string): Promise<void> {
    const result = await this.pool.query(
      'DELETE FROM clinic_locations WHERE id = $1 RETURNING id',
      [id],
    );
    if (!result.rowCount) {
      throw new NotFoundException('Clinic location not found');
    }
  }

  private normalizeZipCode(zipCode: string): string {
    return zipCode.replace(/\D/g, '').slice(0, 8);
  }

  private mapRowToClinicLocation(row: ClinicLocationRow): ClinicLocation {
    return {
      id: row.id,
      doctorId: row.doctor_id,
      zipCode: row.zip_code,
      street: row.street,
      streetNumber: row.street_number,
      neighborhood: row.neighborhood ?? undefined,
      city: row.city ?? undefined,
      addressComplement: row.address_complement ?? undefined,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    };
  }
}

type ClinicLocationRow = {
  id: string;
  doctor_id: string;
  zip_code: string;
  street: string;
  street_number: string;
  neighborhood: string | null;
  city: string | null;
  address_complement: string | null;
  created_at: Date;
  updated_at: Date;
};
