import { AppButton, AppMainContainer } from "@/themes/components";
import AppointmentsList from "@/app/admin/appointments/_list";

export const metadata = {
  title: "Consultas",
};

export default function AppointmentsPage() {
  return (
    <AppMainContainer title="Consultas">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <h1 className="font-bold text-[20px]">Lista de Consultas</h1>
        <AppButton
          title='Nova consulta'
          form="round"
          type="outline"
          icon="person-add"
          href="/admin/appointments/new"
          className="w-full sm:w-auto transition-all duration-200 hover:brightness-125 hover:shadow-md"
        />
      </div>

      <AppointmentsList />
    </AppMainContainer>
  );
}
