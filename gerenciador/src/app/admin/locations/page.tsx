import { AppButton, AppMainContainer } from "@/themes/components";
import LocationList from "./_list";

export const metadata = {
  title: "Locais",
};

export default function LocationsPage() {
  return (
    <AppMainContainer title="Locais">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <h1 className="font-bold text-[20px]">Lista de Locais</h1>
        <AppButton
          title='Novo local'
          form="round"
          type="outline"
          icon="person-add"
          href="/admin/locations/new"
          className="w-full sm:w-auto transition-all duration-200 hover:brightness-125 hover:shadow-md"
        />
      </div>

      <LocationList />
    </AppMainContainer>
  );
}
