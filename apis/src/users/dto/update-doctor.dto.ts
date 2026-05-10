import { PartialType } from '@nestjs/mapped-types';
import { IsOptional, IsString, Length } from 'class-validator';
import { CreateDoctorDto } from './create-doctor.dto';

export class UpdateDoctorDto extends PartialType(CreateDoctorDto) {
  @IsOptional()
  @IsString()
  @Length(6, 64)
  currentPassword?: string;

  @IsOptional()
  @IsString()
  @Length(6, 64)
  newPassword?: string;
}
