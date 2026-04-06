import Cookies from "js-cookie";

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:3001";

type DoctorApi = {
  id: string;
  name: string;
  email: string;
  cpf: string;
  crm: string;
  type: "doctor" | "admin";
  createdAt: string;
  updatedAt: string;
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

type UserModel = {
  id: string;
  name: string;
  email: string;
  cpf?: string;
  crm?: string;
  admin: boolean;
};

type UserPayload = {
  name?: string;
  email?: string;
  password?: string;
  currentPassword?: string;
  newPassword?: string;
  cpf?: string;
  crm?: string;
};

const toUserModel = (doctor: DoctorApi): UserModel => ({
  id: doctor.id,
  name: doctor.name,
  email: doctor.email,
  cpf: doctor.cpf,
  crm: doctor.crm,
  admin: doctor.type === "admin",
});

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

const UserServices = {
  login: async (
    email: string,
    password: string,
  ): Promise<{ success: boolean; message?: string }> => {
    try {
      const user = await request<{
        id: string;
        name: string;
        email: string;
        type: "doctor" | "admin";
      }>("/users/login", {
        method: "POST",
        body: JSON.stringify({ email, password }),
      });

      if (user.type === "doctor") {
        return {
          success: false,
          message: "Você não tem permissão para acessar o gerenciador",
        };
      }

      Cookies.set("user", JSON.stringify(user));
      return { success: true };
    } catch (error: any) {
      return {
        success: false,
        message: error?.message || "Login inválido",
      };
    }
  },

  getCurrentUser: () => {
    const user = Cookies.get("user");
    return user ? JSON.parse(user) : null;
  },

  resetPassword: async (email: string): Promise<{ success: boolean }> => {
    await new Promise((resolve) => setTimeout(resolve, 600));
    return { success: true };
  },

  logout: async (): Promise<{ success: boolean }> => {
    await new Promise((resolve) => setTimeout(resolve, 200));
    Cookies.remove("user");
    return { success: true };
  },

  getAll: async (
    page: number,
    filter: any = {},
  ): Promise<{ success: boolean; users?: any[]; pagination?: any }> => {
    try {
      const params = new URLSearchParams({
        page: String(page),
        limit: "20",
      });

      const name = String(filter?.name ?? "").trim();
      const email = String(filter?.email ?? "").trim();
      const admin = String(filter?.admin ?? "-1").trim();

      if (name) {
        params.set("name", name);
      }

      if (email) {
        params.set("email", email);
      }

      if (admin === "0" || admin === "1") {
        params.set("admin", admin);
      }

      const response = await request<PaginatedApiResponse<DoctorApi>>(
        `/users?${params.toString()}`,
      );
      const users = response.data.map(toUserModel);

      return {
        success: true,
        users,
        pagination: response.pagination,
      };
    } catch {
      return {
        success: false,
        users: [],
        pagination: { firstPage: true, lastPage: true },
      };
    }
  },

  getById: async (id: string): Promise<{ success: boolean; user: any }> => {
    try {
      const doctor = await request<DoctorApi>(`/users/${id}`);
      return { success: true, user: toUserModel(doctor) };
    } catch {
      return { success: false, user: null };
    }
  },

  create: async (user: any): Promise<{ success: boolean; error?: string }> => {
    const userType: "doctor" | "admin" =
      user.type === "admin" ? "admin" : "doctor";

    const adminPayload: UserPayload = {
      name: user.name,
      email: user.email,
      password: user.password,
    };

    const doctorPayload: UserPayload = {
      name: user.name,
      email: user.email,
      password: user.password,
      cpf: user.cpf,
      crm: user.crm,
    };

    try {
      await request(userType === "admin" ? "/users/admin" : "/users/doctor", {
        method: "POST",
        body: JSON.stringify(
          userType === "admin" ? adminPayload : doctorPayload,
        ),
      });
      return { success: true };
    } catch (error: any) {
      return {
        success: false,
        error: error?.message || "Error creating user",
      };
    }
  },

  update: async (
    id: string,
    user: any,
  ): Promise<{ success: boolean; error?: string }> => {
    const payload: UserPayload = {
      name: user.name,
      email: user.email,
      currentPassword: user.currentPassword,
      newPassword: user.newPassword,
      ...(user.cpf ? { cpf: user.cpf } : {}),
    };

    try {
      await request(`/users/profile/${id}`, {
        method: "PATCH",
        body: JSON.stringify(payload),
      });
      return { success: true };
    } catch (error: any) {
      return {
        success: false,
        error: error?.message || "Error updating user",
      };
    }
  },

  delete: async (id: string): Promise<{ success: boolean }> => {
    try {
      await request(`/users/${id}`, {
        method: "DELETE",
      });
      return { success: true };
    } catch {
      return { success: false };
    }
  },
};

export default UserServices;
