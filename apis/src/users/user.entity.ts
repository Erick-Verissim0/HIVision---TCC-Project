export type UserType = 'doctor' | 'admin';

export interface User {
  id: string;
  name: string;
  passwordHash: string;
  cpf?: string;
  email: string;
  crm?: string;
  type: UserType;
  createdAt: Date;
  updatedAt: Date;
}
