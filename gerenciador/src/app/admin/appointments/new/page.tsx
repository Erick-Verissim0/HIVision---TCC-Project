import { AppMainContainer } from "@/themes/components";
import AppointmentCreateForm from "./_form";

export const metadata = {
  title: "Criar consulta",
};

export default function AppointmentCreatePage() {
  return (
    <AppMainContainer title="Nova consulta">
      <AppointmentCreateForm />
    </AppMainContainer>
  );
}
