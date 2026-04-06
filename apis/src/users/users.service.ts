import {
  BadRequestException,
  Injectable,
  NotFoundException,
  OnModuleDestroy,
  OnModuleInit,
  UnauthorizedException,
} from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { Pool } from 'pg';
import { CreateAdminDto } from './dto/create-admin.dto';
import { CreateDoctorDto } from './dto/create-doctor.dto';
import { LoginUserDto } from './dto/login-doctor.dto';
import { UpdateAdminDto } from './dto/update-admin.dto';
import { User } from './user.entity';
import { UpdateDoctorDto } from './dto/update-doctor.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';

type UserRow = {
  id: string;
  name: string;
  password_hash: string;
  cpf: string | null;
  email: string;
  crm: string | null;
  type: 'doctor' | 'admin';
  created_at: Date;
  updated_at: Date;
};

type UserListFilters = {
  name?: string;
  email?: string;
  admin?: string;
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
export class UsersService implements OnModuleInit, OnModuleDestroy {
  private users: User[] = [];
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
    await this.refreshUsersCache();
  }

  async onModuleDestroy(): Promise<void> {
    await this.pool.end();
  }

  async createDoctor(dto: CreateDoctorDto): Promise<Omit<User, 'passwordHash'>> {
    const normalizedCpf = this.normalizeCpf(dto.cpf);
    const email = dto.email.toLowerCase();
    const passwordHash = await bcrypt.hash(dto.password, 10);

    try {
      const { rows } = await this.pool.query<UserRow>(
        `
          INSERT INTO users (name, password_hash, cpf, email, crm, type, created_at, updated_at)
          VALUES ($1, $2, $3, $4, $5, 'doctor', NOW(), NOW())
          RETURNING *
        `,
        [dto.name, passwordHash, normalizedCpf, email, dto.crm],
      );

      const doctor = this.mapRowToUser(rows[0]);
      this.users.push(doctor);
      return this.sanitize(doctor);
    } catch (error: any) {
      throw this.mapDatabaseError(error);
    }
  }

  async createAdmin(dto: CreateAdminDto): Promise<Omit<User, 'passwordHash'>> {
    const email = dto.email.toLowerCase();
    const passwordHash = await bcrypt.hash(dto.password, 10);

    try {
      const { rows } = await this.pool.query<UserRow>(
        `
          INSERT INTO users (name, password_hash, email, type, created_at, updated_at)
          VALUES ($1, $2, $3, 'admin', NOW(), NOW())
          RETURNING *
        `,
        [dto.name, passwordHash, email],
      );

      const admin = this.mapRowToUser(rows[0]);
      this.users.push(admin);
      return this.sanitize(admin);
    } catch (error: any) {
      throw this.mapDatabaseError(error);
    }
  }

  async findAll(
    filters: UserListFilters = {},
  ): Promise<Omit<User, 'passwordHash'>[] | PaginatedResponse<Omit<User, 'passwordHash'>>> {
    const values: any[] = [];
    const where: string[] = [];

    if (filters.name?.trim()) {
      values.push(`%${filters.name.trim().toLowerCase()}%`);
      where.push(`LOWER(name) LIKE $${values.length}`);
    }

    if (filters.email?.trim()) {
      values.push(`%${filters.email.trim().toLowerCase()}%`);
      where.push(`LOWER(email) LIKE $${values.length}`);
    }

    if (filters.admin === '1') {
      values.push('admin');
      where.push(`type = $${values.length}`);
    }

    if (filters.admin === '0') {
      values.push('doctor');
      where.push(`type = $${values.length}`);
    }

    const whereClause = where.length ? `WHERE ${where.join(' AND ')}` : '';
    const hasPagination = Number.isFinite(filters.page);

    if (!hasPagination) {
      const { rows } = await this.pool.query<UserRow>(
        `SELECT * FROM users ${whereClause} ORDER BY LOWER(name) ASC, created_at DESC`,
        values,
      );

      return rows.map((row) => this.sanitize(this.mapRowToUser(row)));
    }

    const page = Math.max(1, Number(filters.page ?? 1));
    const perPage = Math.max(1, Math.min(100, Number(filters.limit ?? 20)));

    const totalResult = await this.pool.query<{ total: number }>(
      `SELECT COUNT(*)::int AS total FROM users ${whereClause}`,
      values,
    );
    const total = totalResult.rows[0]?.total ?? 0;
    const totalPages = Math.max(1, Math.ceil(total / perPage));
    const safePage = Math.min(page, totalPages);
    const offset = (safePage - 1) * perPage;

    const paginatedValues = [...values, perPage, offset];
    const limitIndex = values.length + 1;
    const offsetIndex = values.length + 2;

    const { rows } = await this.pool.query<UserRow>(
      `
        SELECT * FROM users
        ${whereClause}
        ORDER BY LOWER(name) ASC, created_at DESC
        LIMIT $${limitIndex} OFFSET $${offsetIndex}
      `,
      paginatedValues,
    );

    return {
      data: rows.map((row) => this.sanitize(this.mapRowToUser(row))),
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

  async findOne(id: string): Promise<Omit<User, 'passwordHash'>> {
    const user = await this.findById(id);
    return this.sanitize(user);
  }

  async updateDoctor(id: string, dto: UpdateDoctorDto): Promise<Omit<User, 'passwordHash'>> {
    const doctor = await this.findById(id);

    if (doctor.type !== 'doctor') {
      throw new BadRequestException('User is not a doctor');
    }

    const updates: string[] = [];
    const values: any[] = [];

    if (dto.name !== undefined) {
      values.push(dto.name);
      updates.push(`name = $${values.length}`);
    }

    if (dto.email !== undefined) {
      values.push(dto.email.toLowerCase());
      updates.push(`email = $${values.length}`);
    }

    if (dto.cpf !== undefined) {
      values.push(this.normalizeCpf(dto.cpf));
      updates.push(`cpf = $${values.length}`);
    }

    if (dto.crm !== undefined) {
      values.push(dto.crm);
      updates.push(`crm = $${values.length}`);
    }

    if (dto.password !== undefined) {
      values.push(await bcrypt.hash(dto.password, 10));
      updates.push(`password_hash = $${values.length}`);
    }

    if (!updates.length) {
      return this.sanitize(doctor);
    }

    updates.push('updated_at = NOW()');
    values.push(id);

    try {
      const { rows } = await this.pool.query<UserRow>(
        `UPDATE users SET ${updates.join(', ')} WHERE id = $${values.length} RETURNING *`,
        values,
      );

      const updatedDoctor = this.mapRowToUser(rows[0]);
      this.replaceCachedUser(updatedDoctor);
      return this.sanitize(updatedDoctor);
    } catch (error: any) {
      throw this.mapDatabaseError(error);
    }
  }

  async updateAdmin(id: string, dto: UpdateAdminDto): Promise<Omit<User, 'passwordHash'>> {
    const admin = await this.findById(id);

    if (admin.type !== 'admin') {
      throw new BadRequestException('User is not an admin');
    }

    const updates: string[] = [];
    const values: any[] = [];

    if (dto.name !== undefined) {
      values.push(dto.name);
      updates.push(`name = $${values.length}`);
    }

    if (dto.email !== undefined) {
      values.push(dto.email.toLowerCase());
      updates.push(`email = $${values.length}`);
    }

    if (dto.password !== undefined) {
      values.push(await bcrypt.hash(dto.password, 10));
      updates.push(`password_hash = $${values.length}`);
    }

    if (!updates.length) {
      return this.sanitize(admin);
    }

    updates.push('updated_at = NOW()');
    values.push(id);

    try {
      const { rows } = await this.pool.query<UserRow>(
        `UPDATE users SET ${updates.join(', ')} WHERE id = $${values.length} RETURNING *`,
        values,
      );

      const updatedAdmin = this.mapRowToUser(rows[0]);
      this.replaceCachedUser(updatedAdmin);
      return this.sanitize(updatedAdmin);
    } catch (error: any) {
      throw this.mapDatabaseError(error);
    }
  }

  async updateProfile(id: string, dto: UpdateProfileDto): Promise<Omit<User, 'passwordHash'>> {
    const user = await this.findById(id);

    const isValidPassword = await bcrypt.compare(dto.currentPassword, user.passwordHash);
    if (!isValidPassword) {
      throw new UnauthorizedException('Senha atual inválida');
    }

    const updates: string[] = [];
    const values: any[] = [];

    if (dto.name !== undefined) {
      values.push(dto.name);
      updates.push(`name = $${values.length}`);
    }

    if (dto.email !== undefined) {
      values.push(dto.email.toLowerCase());
      updates.push(`email = $${values.length}`);
    }

    if (dto.cpf !== undefined && dto.cpf.trim() !== '') {
      values.push(this.normalizeCpf(dto.cpf));
      updates.push(`cpf = $${values.length}`);
    }

    values.push(await bcrypt.hash(dto.newPassword, 10));
    updates.push(`password_hash = $${values.length}`);

    updates.push('updated_at = NOW()');
    values.push(id);

    try {
      const { rows } = await this.pool.query<UserRow>(
        `UPDATE users SET ${updates.join(', ')} WHERE id = $${values.length} RETURNING *`,
        values,
      );

      const updatedUser = this.mapRowToUser(rows[0]);
      this.replaceCachedUser(updatedUser);
      return this.sanitize(updatedUser);
    } catch (error: any) {
      throw this.mapDatabaseError(error);
    }
  }

  async remove(id: string): Promise<void> {
    const result = await this.pool.query('DELETE FROM users WHERE id = $1 RETURNING id', [id]);

    if (!result.rowCount) {
      throw new NotFoundException('User not found');
    }

    this.users = this.users.filter((user) => user.id !== id);
  }

  async login(
    dto: LoginUserDto,
  ): Promise<{ id: string; name: string; email: string; type: 'doctor' | 'admin' }> {
    const { rows } = await this.pool.query<UserRow>(
      'SELECT * FROM users WHERE email = $1 LIMIT 1',
      [dto.email.toLowerCase()],
    );

    const user = rows.length ? this.mapRowToUser(rows[0]) : null;

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const isValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    return {
      id: user.id,
      name: user.name,
      email: user.email,
      type: user.type,
    };
  }

  exists(id: string): boolean {
    return this.users.some((user) => user.id === id);
  }

  private async findById(id: string): Promise<User> {
    const { rows } = await this.pool.query<UserRow>('SELECT * FROM users WHERE id = $1 LIMIT 1', [
      id,
    ]);
    const user = rows.length ? this.mapRowToUser(rows[0]) : null;

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  private async refreshUsersCache(): Promise<void> {
    const { rows } = await this.pool.query<UserRow>('SELECT * FROM users');
    this.users = rows.map((row) => this.mapRowToUser(row));
  }

  private replaceCachedUser(updatedUser: User): void {
    const index = this.users.findIndex((user) => user.id === updatedUser.id);
    if (index >= 0) {
      this.users[index] = updatedUser;
      return;
    }

    this.users.push(updatedUser);
  }

  private mapRowToUser(row: UserRow): User {
    return {
      id: row.id,
      name: row.name,
      passwordHash: row.password_hash,
      cpf: row.cpf ?? undefined,
      email: row.email,
      crm: row.crm ?? undefined,
      type: row.type,
      createdAt: new Date(row.created_at),
      updatedAt: new Date(row.updated_at),
    };
  }

  private mapDatabaseError(error: any): BadRequestException {
    if (error?.code !== '23505') {
      return new BadRequestException(error?.message ?? 'Database error');
    }

    const constraint = String(error?.constraint ?? '');

    if (constraint.includes('users_email_key')) {
      return new BadRequestException('Email already in use');
    }

    if (constraint.includes('users_cpf_key')) {
      return new BadRequestException('CPF already in use');
    }

    if (constraint.includes('users_crm_key')) {
      return new BadRequestException('CRM already in use');
    }

    return new BadRequestException('Unique field already in use');
  }

  private normalizeCpf(cpf: string): string {
    const onlyDigits = cpf.replace(/\D/g, '');
    return onlyDigits.replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, '$1.$2.$3-$4');
  }

  private sanitize(user: User): Omit<User, 'passwordHash'> {
    const { passwordHash, ...safe } = user;
    return safe;
  }
}
