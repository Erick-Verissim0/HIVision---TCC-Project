import { AppMainContainer } from "@/themes/components";
import LocationEditForm from "./_form";

export const metadata = {
  title: "Editar local",
};

export default async function LocationEditPage({ params }: any) {
  const { locationId } = await params;

  return (
    <AppMainContainer title="Editar local">
      <LocationEditForm locationId={locationId} />
    </AppMainContainer>
  );
}
