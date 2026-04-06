import { Type } from 'class-transformer';
import { IsDate, IsOptional, IsString, Matches, IsUUID, IsNotEmpty } from 'class-validator';

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
}
