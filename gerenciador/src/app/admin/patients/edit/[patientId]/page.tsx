import { AppMainContainer } from "@/themes/components";
import PatientEditForm from "./_form";

export const metadata = {
  title: "Editar paciente",
};

export default async function PatientEditPage({ params }: any) {
  const { patientId } = await params;

  return (
    <AppMainContainer title="Editar paciente">
      <PatientEditForm patientId={patientId} />
    </AppMainContainer>
  );
}
