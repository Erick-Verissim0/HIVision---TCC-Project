import { AppMainContainer } from "@/themes/components";
import PatientCreateForm from "./_form";

export const metadata = {
  title: "Criar paciente",
};

export default function PatientCreatePage() {
  return (
    <AppMainContainer title="Novo paciente">
      <PatientCreateForm />
    </AppMainContainer>
  );
}
