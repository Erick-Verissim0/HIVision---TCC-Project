import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
  OnModuleDestroy,
  OnModuleInit,
  UnauthorizedException,
} from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import * as nodemailer from 'nodemailer';
import { Pool } from 'pg';
import { CreateAdminDto } from './dto/create-admin.dto';
import { CreateDoctorDto } from './dto/create-doctor.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ForgotPasswordRequestDto } from './dto/forgot-password-request.dto';
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

type ForgotPasswordCodeEntry = {
  code: string;
  expiresAt: number;
  failedAttempts: number;
};

@Injectable()
export class UsersService implements OnModuleInit, OnModuleDestroy {
  private static readonly FORGOT_PASSWORD_CODE_TTL_MS = 15 * 60 * 1000;
  private static readonly FORGOT_PASSWORD_MAX_ATTEMPTS = 5;

  private users: User[] = [];
  private readonly pool: Pool;
  private mailTransporter: nodemailer.Transporter | null;
  private mailFromAddress = 'no-reply@hivision.local';
  private mailFromName = 'HIVision';
  private readonly forgotPasswordCodes = new Map<string, ForgotPasswordCodeEntry>();

  constructor() {
    this.pool = new Pool({
      host: process.env.DB_HOST ?? 'localhost',
      port: Number(process.env.DB_PORT ?? process.env.POSTGRES_PORT ?? 5433),
      database: process.env.DB_NAME ?? process.env.POSTGRES_DB ?? 'hivision',
      user: process.env.DB_USER ?? process.env.POSTGRES_USER ?? 'hivision',
      password: process.env.DB_PASSWORD ?? process.env.POSTGRES_PASSWORD ?? 'hivision123',
    });
    this.mailTransporter = null;
  }

  async onModuleInit(): Promise<void> {
    await this.pool.query('SELECT 1');
    await this.refreshUsersCache();
    await this.initializeMailTransporter();
  }

  async onModuleDestroy(): Promise<void> {
    await this.pool.end();
  }

  async createDoctor(dto: CreateDoctorDto): Promise<Omit<User, 'passwordHash'>> {
    const normalizedCpf = this.normalizeCpf(dto.cpf);
    const email = dto.email.toLowerCase();
    await this.assertEmailAndCpfAreUnique({ email, cpf: normalizedCpf });
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
    await this.assertEmailAndCpfAreUnique({ email });
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

    if (!dto.currentPassword?.trim() || !dto.newPassword?.trim()) {
      throw new BadRequestException('Senha atual e nova senha são obrigatórias');
    }

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

  async forgotPassword(
    dto: ForgotPasswordDto,
  ): Promise<{ id: string; name: string; email: string; type: 'doctor' | 'admin' }> {
    const email = dto.email.toLowerCase();
    const resetCode = this.normalizeResetCode(dto.resetCode);
    const { rows } = await this.pool.query<UserRow>(
      'SELECT * FROM users WHERE email = $1 LIMIT 1',
      [email],
    );
    const user = rows.length ? this.mapRowToUser(rows[0]) : null;

    if (!user) {
      throw new NotFoundException('User not found');
    }

    this.validateForgotPasswordCode(email, resetCode);

    const hashedPassword = await bcrypt.hash(dto.newPassword, 10);
    const result = await this.pool.query<UserRow>(
      `UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2 RETURNING *`,
      [hashedPassword, user.id],
    );

    this.forgotPasswordCodes.delete(email);

    const updatedUser = this.mapRowToUser(result.rows[0]);
    this.replaceCachedUser(updatedUser);

    return {
      id: updatedUser.id,
      name: updatedUser.name,
      email: updatedUser.email,
      type: updatedUser.type,
    };
  }

  async requestForgotPasswordLink(
    dto: ForgotPasswordRequestDto,
  ): Promise<{ message: string; email: string }> {
    const email = dto.email.toLowerCase();
    const { rows } = await this.pool.query<UserRow>(
      'SELECT * FROM users WHERE email = $1 LIMIT 1',
      [email],
    );

    if (!rows.length) {
      throw new NotFoundException('User not found');
    }

    const user = this.mapRowToUser(rows[0]);
    const resetCode = this.issueForgotPasswordCode(email);
    await this.sendForgotPasswordEmail(user.name, email, resetCode);

    return {
      message: 'Password reset link requested',
      email,
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

  private async initializeMailTransporter(): Promise<void> {
    if (this.mailTransporter) {
      return;
    }

    const configuredTransporter = this.createConfiguredMailTransporter();
    if (configuredTransporter != null) {
      this.mailTransporter = configuredTransporter;
      this.mailFromAddress =
        process.env.SMTP_FROM_EMAIL ?? process.env.SMTP_USER ?? this.mailFromAddress;
      this.mailFromName = process.env.SMTP_FROM_NAME ?? this.mailFromName;
      return;
    }

    const allowEthereal =
      String(process.env.ALLOW_ETHEREAL_TEST ?? 'false').toLowerCase() === 'true';
    if (!allowEthereal) {
      console.warn(
        '[mail] SMTP não configurado. Defina SMTP_HOST, SMTP_PORT, SMTP_USER e SMTP_PASSWORD para envio real. ' +
          'Se quiser usar Ethereal para testes, defina ALLOW_ETHEREAL_TEST=true.',
      );
      return;
    }

    const testAccount = await nodemailer.createTestAccount();
    this.mailTransporter = nodemailer.createTransport({
      host: testAccount.smtp.host,
      port: testAccount.smtp.port,
      secure: testAccount.smtp.secure,
      auth: {
        user: testAccount.user,
        pass: testAccount.pass,
      },
    });
    this.mailFromAddress = testAccount.user;
    this.mailFromName = 'HIVision Test';
    console.log('[mail] SMTP não configurado. Usando conta de teste Ethereal:', testAccount.user);
  }

  private createConfiguredMailTransporter(): nodemailer.Transporter | null {
    const service = process.env.SMTP_SERVICE;
    const host = process.env.SMTP_HOST;
    const port = Number(process.env.SMTP_PORT ?? 587);
    const user = process.env.SMTP_USER;
    const password = process.env.SMTP_PASSWORD;

    if (!user || !password) {
      return null;
    }

    if (service) {
      return nodemailer.createTransport({
        service,
        auth: {
          user,
          pass: password,
        },
      });
    }

    if (!host) {
      return null;
    }

    return nodemailer.createTransport({
      host,
      port,
      secure: String(process.env.SMTP_SECURE ?? 'false').toLowerCase() === 'true',
      auth: {
        user,
        pass: password,
      },
    });
  }

  private async sendForgotPasswordEmail(
    name: string,
    email: string,
    resetCode: string,
  ): Promise<void> {
    await this.initializeMailTransporter();

    if (!this.mailTransporter) {
      throw new BadRequestException(
        'Serviço de e-mail não configurado. Defina SMTP_HOST/SMTP_PORT/SMTP_USER/SMTP_PASSWORD ' +
          'ou SMTP_SERVICE/SMTP_USER/SMTP_PASSWORD (ex.: Gmail).',
      );
    }

    const info = await this.mailTransporter.sendMail({
      from: `"${this.mailFromName}" <${this.mailFromAddress}>`,
      to: email,
      subject: 'Recuperação de senha - HIVision',
      text: this.buildForgotPasswordText(name, resetCode),
      html: this.buildForgotPasswordHtml(name, resetCode),
    });

    const previewUrl = nodemailer.getTestMessageUrl(info);
    if (previewUrl) {
      console.log('[mail] Preview URL:', previewUrl);
    }
  }

  private buildForgotPasswordText(name: string, resetCode: string): string {
    return [
      `Olá, ${name}.`,
      '',
      'Recebemos uma solicitação para redefinir sua senha no HIVision.',
      `Código de recuperação: ${resetCode}`,
      '',
      'Insira este código na tela do aplicativo para definir sua nova senha.',
      '',
      'Se você não fez essa solicitação, ignore este e-mail.',
    ].join('\n');
  }

  private buildForgotPasswordHtml(name: string, resetCode: string): string {
    return `
      <div style="font-family: Arial, sans-serif; color: #222; line-height: 1.5;">
        <h2 style="color: #760000;">Recuperação de senha</h2>
        <p>Olá, <strong>${this.escapeHtml(name)}</strong>.</p>
        <p>Recebemos uma solicitação para redefinir sua senha no HIVision.</p>
        <p><strong>Código de recuperação:</strong> ${this.escapeHtml(resetCode)}</p>
        <p>Insira este código na tela do aplicativo para definir sua nova senha.</p>
        <p>Se você não fez essa solicitação, ignore este e-mail.</p>
      </div>
    `;
  }

  private issueForgotPasswordCode(email: string): string {
    const code = this.generateResetCode();
    const expiresAt = Date.now() + UsersService.FORGOT_PASSWORD_CODE_TTL_MS;
    this.forgotPasswordCodes.set(email.toLowerCase(), { code, expiresAt, failedAttempts: 0 });
    return code;
  }

  private validateForgotPasswordCode(email: string, providedCode: string): void {
    const normalizedEmail = email.toLowerCase();
    const codeEntry = this.forgotPasswordCodes.get(normalizedEmail);

    if (!codeEntry) {
      throw new BadRequestException('Solicite um novo código de recuperação');
    }

    if (codeEntry.expiresAt < Date.now()) {
      this.forgotPasswordCodes.delete(normalizedEmail);
      throw new BadRequestException('Código de recuperação inválido ou expirado');
    }

    if (codeEntry.code !== providedCode) {
      codeEntry.failedAttempts += 1;

      if (codeEntry.failedAttempts >= UsersService.FORGOT_PASSWORD_MAX_ATTEMPTS) {
        this.forgotPasswordCodes.delete(normalizedEmail);
        throw new BadRequestException(
          'Número de tentativas excedido. Solicite um novo código de recuperação',
        );
      }

      this.forgotPasswordCodes.set(normalizedEmail, codeEntry);
      throw new BadRequestException('Código de recuperação inválido ou expirado');
    }
  }

  private generateResetCode(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  private normalizeResetCode(rawCode: string): string {
    return rawCode.replace(/\D/g, '');
  }

  private escapeHtml(value: string): string {
    return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
  }

  private async assertEmailAndCpfAreUnique(params: { email: string; cpf?: string }): Promise<void> {
    const email = params.email.toLowerCase();
    const values: string[] = [email];
    const filters = ['LOWER(email) = $1'];

    if (params.cpf) {
      values.push(params.cpf);
      filters.push(`cpf = $${values.length}`);
    }

    const { rows } = await this.pool.query<{ email: string; cpf: string | null }>(
      `SELECT email, cpf FROM users WHERE ${filters.join(' OR ')}`,
      values,
    );

    const emailExists = rows.some((row) => row.email.toLowerCase() === email);
    if (emailExists) {
      throw new ConflictException({
        message: 'Email já existe',
        field: 'email',
      });
    }

    if (params.cpf) {
      const cpfExists = rows.some((row) => row.cpf === params.cpf);
      if (cpfExists) {
        throw new ConflictException({
          message: 'CPF já existe',
          field: 'cpf',
        });
      }
    }
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

  private mapDatabaseError(error: any): BadRequestException | ConflictException {
    if (error?.code !== '23505') {
      return new BadRequestException(error?.message ?? 'Database error');
    }

    const constraint = String(error?.constraint ?? '');

    if (constraint.includes('users_email_key')) {
      return new ConflictException({
        message: 'Email já existe',
        field: 'email',
      });
    }

    if (constraint.includes('users_cpf_key')) {
      return new ConflictException({
        message: 'CPF já existe',
        field: 'cpf',
      });
    }

    if (constraint.includes('users_crm_key')) {
      return new ConflictException({
        message: 'CRM já existe',
        field: 'crm',
      });
    }

    return new ConflictException('Campo único já existe');
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
