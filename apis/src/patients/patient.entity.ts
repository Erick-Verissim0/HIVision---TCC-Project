export interface Patient {
  id: string;
  doctorId: string;
  name: string;
  cpf: string;
  createdAt: Date;
  updatedAt: Date;
  lastAppointment?: Date;
  zipCode?: string;
  street?: string;
  streetNumber?: string;
  neighborhood?: string;
  city?: string;
  addressComplement?: string;
  age?: number;
  birthDate?: Date;
  maritalStatus?: string;
  profession?: string;
  previousDiseases?: string;
  allergies?: string;
  medications?: string;
  boneHealth?: string;
}
