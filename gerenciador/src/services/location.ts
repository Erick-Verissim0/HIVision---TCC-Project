const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:3001";

type LocationApi = {
  id: string;
  doctorId: string;
  zipCode: string;
  street: string;
  streetNumber: string;
  neighborhood?: string;
  city?: string;
  addressComplement?: string;
  createdAt: string;
  updatedAt: string;
};

type DoctorApi = {
  id: string;
  name: string;
  type: "doctor" | "admin";
};

type LocationPayload = {
  doctorId: string;
  zipCode: string;
  street: string;
  streetNumber: string;
  neighborhood?: string;
  city?: string;
  addressComplement?: string;
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

const LocationServices = {
  getAll: async (
    filters: { city?: string; street?: string } = {},
    page?: number,
  ): Promise<{
    success: boolean;
    locations: LocationApi[];
    pagination?: PaginatedApiResponse<LocationApi>["pagination"];
    error?: string;
  }> => {
    try {
      const params = new URLSearchParams();

      if (filters.city?.trim()) {
        params.set("city", filters.city.trim());
      }

      if (filters.street?.trim()) {
        params.set("street", filters.street.trim());
      }

      if (page !== undefined) {
        params.set("page", String(page));
        params.set("limit", "20");
      }

      const query = params.toString();
      const path = query ? `/clinic-locations?${query}` : "/clinic-locations";

      if (page === undefined) {
        const locations = await request<LocationApi[]>(path);
        return { success: true, locations };
      }

      const paginated = await request<PaginatedApiResponse<LocationApi>>(path);
      return {
        success: true,
        locations: paginated.data,
        pagination: paginated.pagination,
      };
    } catch (error: any) {
      return {
        success: false,
        locations: [],
        error: error?.message || "Erro ao buscar locais",
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
    payload: LocationPayload,
  ): Promise<{ success: boolean; error?: string }> => {
    try {
      await request("/clinic-locations", {
        method: "POST",
        body: JSON.stringify(payload),
      });

      return { success: true };
    } catch (error: any) {
      return {
        success: false,
        error: error?.message || "Erro ao criar local",
      };
    }
  },

  update: async (
    id: string,
    payload: LocationPayload,
  ): Promise<{ success: boolean; error?: string }> => {
    try {
      await request(`/clinic-locations/${id}`, {
        method: "PATCH",
        body: JSON.stringify(payload),
      });

      return { success: true };
    } catch (error: any) {
      return {
        success: false,
        error: error?.message || "Erro ao atualizar local",
      };
    }
  },

  delete: async (id: string): Promise<{ success: boolean; error?: string }> => {
    try {
      await request(`/clinic-locations/${id}`, {
        method: "DELETE",
      });

      return { success: true };
    } catch (error: any) {
      return {
        success: false,
        error: error?.message || "Erro ao remover local",
      };
    }
  },
};

export default LocationServices;
