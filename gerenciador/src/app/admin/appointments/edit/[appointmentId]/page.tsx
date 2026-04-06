import { AppMainContainer } from "@/themes/components";
import AppointmentEditForm from "./_form";

export const metadata = {
  title: "Editar consulta",
};

export default async function AppointmentEditPage({ params }: any) {
  const { appointmentId } = await params;

  return (
    <AppMainContainer title="Editar consulta">
      <AppointmentEditForm appointmentId={appointmentId} />
    </AppMainContainer>
  );
}
