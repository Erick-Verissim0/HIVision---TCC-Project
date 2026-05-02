import { IsEmail, IsNotEmpty, IsOptional, IsString, Length } from 'class-validator';

export class CreateAdminDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @Length(6, 64)
  password: string;

  @IsEmail()
  email: string;

  @IsOptional()
  @IsString()
  image?: string;
}
