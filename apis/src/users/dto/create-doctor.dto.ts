import { IsEmail, IsNotEmpty, IsString, Length, Matches } from 'class-validator';

export class CreateDoctorDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @Length(6, 64)
  password: string;

  @IsString()
  @Matches(/^\d{11}$/)
  cpf: string;

  @IsEmail()
  email: string;

  @IsString()
  @IsNotEmpty()
  crm: string;
}
