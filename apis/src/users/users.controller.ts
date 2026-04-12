import { Body, Controller, Delete, Get, HttpCode, Param, Patch, Post, Query } from '@nestjs/common';
import { CreateAdminDto } from './dto/create-admin.dto';
import { CreateDoctorDto } from './dto/create-doctor.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ForgotPasswordRequestDto } from './dto/forgot-password-request.dto';
import { LoginUserDto } from './dto/login-doctor.dto';
import { UpdateAdminDto } from './dto/update-admin.dto';
import { UsersService } from './users.service';
import { UpdateDoctorDto } from './dto/update-doctor.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Controller('users')
export class UsersController {
  constructor(private readonly doctorsService: UsersService) {}

  @Post('doctor')
  createDoctor(@Body() dto: CreateDoctorDto) {
    return this.doctorsService.createDoctor(dto);
  }

  @Post('admin')
  createAdmin(@Body() dto: CreateAdminDto) {
    return this.doctorsService.createAdmin(dto);
  }

  @Post('login')
  @HttpCode(200)
  login(@Body() dto: LoginUserDto) {
    return this.doctorsService.login(dto);
  }

  @Post('forgot-password')
  @HttpCode(200)
  forgotPassword(@Body() dto: ForgotPasswordDto) {
    return this.doctorsService.forgotPassword(dto);
  }

  @Post('forgot-password/request-link')
  @HttpCode(200)
  requestForgotPasswordLink(@Body() dto: ForgotPasswordRequestDto) {
    return this.doctorsService.requestForgotPasswordLink(dto);
  }

  @Post('forgot-password/resend-link')
  @HttpCode(200)
  resendForgotPasswordLink(@Body() dto: ForgotPasswordRequestDto) {
    return this.doctorsService.requestForgotPasswordLink(dto);
  }

  @Get()
  findAll(
    @Query('name') name?: string,
    @Query('email') email?: string,
    @Query('admin') admin?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.doctorsService.findAll({
      name,
      email,
      admin,
      page: page !== undefined ? Number(page) : undefined,
      limit: limit !== undefined ? Number(limit) : undefined,
    });
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.doctorsService.findOne(id);
  }

  @Patch('doctor/:id')
  updateDoctor(@Param('id') id: string, @Body() dto: UpdateDoctorDto) {
    return this.doctorsService.updateDoctor(id, dto);
  }

  @Patch('admin/:id')
  updateAdmin(@Param('id') id: string, @Body() dto: UpdateAdminDto) {
    return this.doctorsService.updateAdmin(id, dto);
  }

  @Patch('profile/:id')
  updateProfile(@Param('id') id: string, @Body() dto: UpdateProfileDto) {
    return this.doctorsService.updateProfile(id, dto);
  }

  @Delete(':id')
  @HttpCode(204)
  remove(@Param('id') id: string) {
    return this.doctorsService.remove(id);
  }
}
