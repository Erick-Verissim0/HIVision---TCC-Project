export enum MaritalStatus {
  SINGLE = 'SINGLE',
  MARRIED = 'MARRIED',
  DIVORCED = 'DIVORCED',
  WIDOWED = 'WIDOWED',
  STABLE_UNION = 'STABLE_UNION',
  OTHER = 'OTHER',
}

export enum Immunizations {
  COMPLETE = 'COMPLETE',
  INCOMPLETE = 'INCOMPLETE',
  NOT_INFORMED = 'NOT_INFORMED',
}

export enum ArtAdherence {
  HIGH = 'HIGH',
  MEDIUM = 'MEDIUM',
  LOW = 'LOW',
  NOT_INFORMED = 'NOT_INFORMED',
}

export interface Appointment {
  id: string;
  doctorId: string;
  patientId: string;
  appointmentDate: Date;
  age?: number;
  sexualOrientation?: string;
  maritalStatus?: MaritalStatus;
  concordantPartner?: boolean;
  occupation?: string;
  comorbidities?: string;
  previousDiseases?: string;
  allergy?: string;
  surgeries?: string;
  medicationUse?: string;
  hivDiagnosisDate?: Date;
  cardiovascularRisk?: string;
  neoplasmScreening?: string;
  coinfectionScreening?: string;
  immunizations?: Immunizations;
  notes?: string;
  zipCode?: string;
  street?: string;
  streetNumber?: string;
  neighborhood?: string;
  city?: string;
  addressComplement?: string;
  currentArt?: string;
  adherence?: ArtAdherence;
  lastViralLoad?: Date;
  cd4Nadir?: string;
  virologicalStatus?: string;
  currentRegimen?: string;
  regimenStartDate?: Date;
  previousRegimens?: string;
  changeReason?: string;
  createdAt: Date;
  updatedAt: Date;
}
