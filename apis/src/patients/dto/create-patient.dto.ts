import { Type } from 'class-transformer';
import {
  IsDate,
  IsOptional,
  IsString,
  Matches,
  IsUUID,
  IsNotEmpty,
  IsNumber,
} from 'class-validator';

export class CreatePatientDto {
  @IsUUID()
  doctorId: string;

  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @Matches(/^\d{11}$/)
  cpf: string;

  @IsOptional()
  @Type(() => Date)
  @IsDate()
  lastAppointment?: Date;

  @IsOptional()
  @IsString()
  zipCode?: string;

  @IsOptional()
  @IsString()
  street?: string;

  @IsOptional()
  @IsString()
  streetNumber?: string;

  @IsOptional()
  @IsString()
  neighborhood?: string;

  @IsOptional()
  @IsString()
  city?: string;

  @IsOptional()
  @IsString()
  addressComplement?: string;

  @IsOptional()
  @IsNumber()
  age?: number;

  @IsOptional()
  @Type(() => Date)
  @IsDate()
  birthDate?: Date;

  @IsOptional()
  @IsString()
  maritalStatus?: string;

  @IsOptional()
  @IsString()
  profession?: string;

  @IsOptional()
  @IsString()
  previousDiseases?: string;

  @IsOptional()
  @IsString()
  allergies?: string;

  @IsOptional()
  @IsString()
  medications?: string;

  @IsOptional()
  @IsString()
  boneHealth?: string;
}
