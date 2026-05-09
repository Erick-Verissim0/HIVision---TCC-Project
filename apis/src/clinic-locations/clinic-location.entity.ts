export interface ClinicLocation {
  id: string;
  doctorId: string;
  name?: string;
  zipCode: string;
  street: string;
  streetNumber: string;
  neighborhood?: string;
  city?: string;
  addressComplement?: string;
  createdAt: Date;
  updatedAt: Date;
}
