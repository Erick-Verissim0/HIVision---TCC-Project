export interface Patient {
  id: string;
  doctorId: string;
  name: string;
  cpf: string;
  createdAt: Date;
  updatedAt: Date;
  lastAppointment?: Date;
}
