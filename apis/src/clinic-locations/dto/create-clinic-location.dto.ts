import { IsNotEmpty, IsOptional, IsString, IsUUID, Matches } from 'class-validator';

export class CreateClinicLocationDto {
  @IsUUID()
  doctorId: string;

  @IsOptional()
  @IsString()
  name?: string;

  @Matches(/^\d{8}$/)
  zipCode: string;

  @IsString()
  @IsNotEmpty()
  street: string;

  @IsString()
  @IsNotEmpty()
  streetNumber: string;

  @IsOptional()
  @IsString()
  neighborhood?: string;

  @IsOptional()
  @IsString()
  city?: string;

  @IsOptional()
  @IsString()
  addressComplement?: string;
}
