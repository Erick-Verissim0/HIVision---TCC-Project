const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:3001";

type PatientApi = {
  id: string;
  doctorId: string;
  name: string;
  cpf: string;
  createdAt: string;
  updatedAt: string;
  lastAppointment?: string;
};

type DoctorApi = {
  id: string;
  name: string;
  type: "doctor" | "admin";
};

type PatientPayload = {
  doctorId: string;
  name: string;
  cpf: string;
  lastAppointment?: string;
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

const PatientServices = {
  getAll: async (
    filters: { name?: string; cpf?: string } = {},
    page?: number,
  ): Promise<{
    success: boolean;
    patients: PatientApi[];
    pagination?: PaginatedApiResponse<PatientApi>["pagination"];
    error?: string;
  }> => {
    try {
      const params = new URLSearchParams();
      if (filters.name?.trim()) {
        params.set("name", filters.name.trim());
      }

      if (filters.cpf?.trim()) {
        params.set("cpf", filters.cpf.replace(/\D/g, ""));
      }

      if (page !== undefined) {
        params.set("page", String(page));
        params.set("limit", "20");
      }

      const query = params.toString();
      const path = query ? `/patients?${query}` : "/patients";

      if (page === undefined) {
        const patients = await request<PatientApi[]>(path);
        return { success: true, patients };
      }

      const paginated = await request<PaginatedApiResponse<PatientApi>>(path);
      return {
        success: true,
        patients: paginated.data,
        pagination: paginated.pagination,
      };
    } catch (error: any) {
      return {
        success: false,
        patients: [],
        error: error?.message || "Erro ao buscar pacientes",
      };
    }
  },

  getDoctors: async (): Promise<{
    success: boolean;
    doctors: Array<{ id: string; name: string }>;
    error?: string;
  }> => {
    try {
      const users = await request<DoctorApi[]>("/users");
      const doctors = users
        .filter((user) => user.type === "doctor")
        .map((doctor) => ({ id: doctor.id, name: doctor.name }));

      return { success: true, doctors };
    } catch (error: any) {
      return {
        success: false,
        doctors: [],
        error: error?.message || "Erro ao buscar médicos",
      };
    }
  },

  create: async (
    payload: PatientPayload,
  ): Promise<{ success: boolean; error?: string }> => {
    try {
      await request("/patients", {
        method: "POST",
        body: JSON.stringify(payload),
      });

      return { success: true };
    } catch (error: any) {
      return {
        success: false,
        error: error?.message || "Erro ao criar paciente",
      };
    }
  },

  update: async (
    id: string,
    payload: PatientPayload,
  ): Promise<{ success: boolean; error?: string }> => {
    try {
      await request(`/patients/${id}`, {
        method: "PATCH",
        body: JSON.stringify(payload),
      });

      return { success: true };
    } catch (error: any) {
      return {
        success: false,
        error: error?.message || "Erro ao atualizar paciente",
      };
    }
  },

  delete: async (id: string): Promise<{ success: boolean; error?: string }> => {
    try {
      await request(`/patients/${id}`, {
        method: "DELETE",
      });

      return { success: true };
    } catch (error: any) {
      return {
        success: false,
        error: error?.message || "Erro ao remover paciente",
      };
    }
  },
};

export default PatientServices;
