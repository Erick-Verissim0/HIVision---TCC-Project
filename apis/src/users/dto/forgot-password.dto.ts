import { IsEmail, IsString, Length, Matches } from 'class-validator';

export class ForgotPasswordDto {
  @IsEmail()
  email: string;

  @IsString()
  @Matches(/^\d{6}$/)
  resetCode: string;

  @IsString()
  @Length(6, 64)
  newPassword: string;
}
