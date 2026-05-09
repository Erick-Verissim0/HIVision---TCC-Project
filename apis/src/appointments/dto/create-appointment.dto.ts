import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsDate,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  Min,
} from 'class-validator';

export class CreateAppointmentDto {
  @IsUUID()
  doctorId: string;

  @IsUUID()
  patientId: string;

  @IsUUID()
  clinicLocationId: string;

  @Type(() => Date)
  @IsDate()
  appointmentDate: Date;

  @IsOptional()
  @IsInt()
  @Min(0)
  age?: number;

  @IsOptional()
  @IsString()
  sexualOrientation?: string;

  @IsOptional()
  @IsString()
  maritalStatus?: string;

  @IsOptional()
  @IsBoolean()
  concordantPartner?: boolean;

  @IsOptional()
  @IsString()
  occupation?: string;

  @IsOptional()
  @IsString()
  comorbidities?: string;

  @IsOptional()
  @IsString()
  previousDiseases?: string;

  @IsOptional()
  @IsString()
  allergy?: string;

  @IsOptional()
  @IsString()
  surgeries?: string;

  @IsOptional()
  @IsString()
  medicationUse?: string;

  @IsOptional()
  @Type(() => Date)
  @IsDate()
  hivDiagnosisDate?: Date;

  @IsOptional()
  @IsString()
  cardiovascularRisk?: string;

  @IsOptional()
  @IsString()
  neoplasmScreening?: string;

  @IsOptional()
  @IsString()
  coinfectionScreening?: string;

  @IsOptional()
  @IsString()
  immunizations?: string;

  @IsOptional()
  @IsString()
  boneHealth?: string;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @Matches(/^\d{8}$/)
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
  @IsString()
  currentArt?: string;

  @IsOptional()
  @IsString()
  adherence?: string;

  @IsOptional()
  @Type(() => Date)
  @IsDate()
  lastViralLoad?: Date;

  @IsOptional()
  @IsString()
  cd4Nadir?: string;

  @IsOptional()
  @IsString()
  virologicalStatus?: string;

  @IsOptional()
  @IsString()
  @IsNotEmpty()
  currentRegimen?: string;

  @IsOptional()
  @Type(() => Date)
  @IsDate()
  regimenStartDate?: Date;

  @IsOptional()
  @IsString()
  previousRegimens?: string;

  @IsOptional()
  @IsString()
  changeReason?: string;
}
