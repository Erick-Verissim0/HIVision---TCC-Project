const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:3001";

type AppointmentApi = {
  id: string;
  doctorId: string;
  patientId: string;
  appointmentDate: string;
  age?: number;
  sexualOrientation?: string;
  maritalStatus?: string;
  concordantPartner?: boolean;
  occupation?: string;
  comorbidities?: string;
  previousDiseases?: string;
  allergy?: string;
  surgeries?: string;
  medicationUse?: string;
  hivDiagnosisDate?: string;
  cardiovascularRisk?: string;
  neoplasmScreening?: string;
  coinfectionScreening?: string;
  immunizations?: string;
  notes?: string;
  zipCode?: string;
  street?: string;
  streetNumber?: string;
  neighborhood?: string;
  city?: string;
  addressComplement?: string;
  currentArt?: string;
  adherence?: string;
  lastViralLoad?: string;
  cd4Nadir?: string;
  virologicalStatus?: string;
  currentRegimen?: string;
  regimenStartDate?: string;
  previousRegimens?: string;
  changeReason?: string;
  createdAt: string;
  updatedAt: string;
};

type DoctorApi = {
  id: string;
  name: string;
  type: "doctor" | "admin";
};

type PatientApi = {
  id: string;
  name: string;
};

type AppointmentPayload = {
  doctorId: string;
  patientId: string;
  appointmentDate: string;
  age?: number;
  sexualOrientation?: string;
  maritalStatus?: string;
  concordantPartner?: boolean;
  occupation?: string;
  comorbidities?: string;
  previousDiseases?: string;
  allergy?: string;
  surgeries?: string;
  medicationUse?: string;
  hivDiagnosisDate?: string;
  cardiovascularRisk?: string;
  neoplasmScreening?: string;
  coinfectionScreening?: string;
  immunizations?: string;
  notes?: string;
  zipCode?: string;
  street?: string;
  streetNumber?: string;
  neighborhood?: string;
  city?: string;
  addressComplement?: string;
  currentArt?: string;
  adherence?: string;
  lastViralLoad?: string;
  cd4Nadir?: string;
  virologicalStatus?: string;
  currentRegimen?: string;
  regimenStartDate?: string;
  previousRegimens?: string;
  changeReason?: string;
};

type PaginatedApiResponse<T> = {
  data: T[];
  pagination: {
    page: number;
    perPage: number;
    total: number;
    totalPages: number;
    firstPage: boolean;
    lastPage: boolean;
  };
};

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      ...(init?.headers ?? {}),
    },
  });

  if (!response.ok) {
    let errorMessage = "Request failed";
    try {
      const body = await response.json();
      if (Array.isArray(body?.message)) {
        errorMessage = body.message.join(", ");
      } else if (typeof body?.message === "string") {
        errorMessage = body.message;
      }
    } catch {
      errorMessage = response.statusText || errorMessage;
    }

    throw new Error(errorMessage);
  }

  if (response.status === 204) {
    return undefined as T;
  }

  return response.json() as Promise<T>;
}

const AppointmentServices = {
  getAll: async (
    filters: { doctorName?: string; patientName?: string } = {},
    page?: number,
  ): Promise<{
    success: boolean;
    appointments: AppointmentApi[];
    pagination?: PaginatedApiResponse<AppointmentApi>["pagination"];
    error?: string;
  }> => {
    try {
      const params = new URLSearchParams();

      if (filters.doctorName?.trim()) {
        params.set("doctorName", filters.doctorName.trim());
      }

      if (filters.patientName?.trim()) {
        params.set("patientName", filters.patientName.trim());
      }

      if (page !== undefined) {
        params.set("page", String(page));
        params.set("limit", "20");
      }

      const query = params.toString();
      const path = query ? `/appointments?${query}` : "/appointments";

      if (page === undefined) {
        const appointments = await request<AppointmentApi[]>(path);
        return { success: true, appointments };
      }

      const paginated =
        await request<PaginatedApiResponse<AppointmentApi>>(path);
      return {
        success: true,
        appointments: paginated.data,
        pagination: paginated.pagination,
      };
    } catch (error: any) {
      return {
        success: false,
        appointments: [],
        error: error?.message || "Erro ao buscar consultas",
      };
    }
  },

  getDoctors: async (): Promise<{
    success: boolean;
    doctors: Array<{ id: string; name: string }>;
    error?: string;
  }> => {
    try {
      const doctors = await request<DoctorApi[]>("/users?admin=0");
      return {
        success: true,
        doctors: doctors.map((doctor) => ({
          id: doctor.id,
          name: doctor.name,
        })),
      };
    } catch (error: any) {
      return {
        success: false,
        doctors: [],
        error: error?.message || "Erro ao buscar médicos",
      };
    }
  },

  getPatients: async (): Promise<{
    success: boolean;
    patients: Array<{ id: string; name: string }>;
    error?: string;
  }> => {
    try {
      const patients = await request<PatientApi[]>("/patients");
      return {
        success: true,
        patients: patients.map((patient) => ({
          id: patient.id,
          name: patient.name,
        })),
      };
    } catch (error: any) {
      return {
        success: false,
        patients: [],
        error: error?.message || "Erro ao buscar pacientes",
      };
    }
  },

  create: async (
    payload: AppointmentPayload,
  ): Promise<{ success: boolean; error?: string }> => {
    try {
      await request("/appointments", {
        method: "POST",
        body: JSON.stringify(payload),
      });
      return { success: true };
    } catch (error: any) {
      return {
        success: false,
        error: error?.message || "Erro ao criar consulta",
      };
    }
  },

  update: async (
    id: string,
    payload: AppointmentPayload,
  ): Promise<{ success: boolean; error?: string }> => {
    try {
      await request(`/appointments/${id}`, {
        method: "PATCH",
        body: JSON.stringify(payload),
      });
      return { success: true };
    } catch (error: any) {
      return {
        success: false,
        error: error?.message || "Erro ao atualizar consulta",
      };
    }
  },

  delete: async (id: string): Promise<{ success: boolean; error?: string }> => {
    try {
      await request(`/appointments/${id}`, {
        method: "DELETE",
      });
      return { success: true };
    } catch (error: any) {
      return {
        success: false,
        error: error?.message || "Erro ao remover consulta",
      };
    }
  },
};

export default AppointmentServices;
