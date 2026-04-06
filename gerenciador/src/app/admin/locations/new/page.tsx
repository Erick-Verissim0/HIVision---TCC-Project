import { AppMainContainer } from "@/themes/components";
import LocationCreateForm from "./_form";

export const metadata = {
  title: "Criar local",
};

export default function LocationCreatePage() {
  return (
    <AppMainContainer title="Novo local">
      <LocationCreateForm />
    </AppMainContainer>
  );
}
