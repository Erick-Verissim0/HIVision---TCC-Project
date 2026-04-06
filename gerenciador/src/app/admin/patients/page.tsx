import { AppButton, AppMainContainer } from "@/themes/components";
import PatientList from "./_list";

export const metadata = {
    title: 'Pacientes'
}

export default function PatientsPage() {
    return (
        <AppMainContainer title="Pacientes">
            <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                <h1 className="font-bold text-[20px]">Lista de Pacientes</h1>
                <AppButton
                    title='Novo paciente'
                    form="round"
                    type="outline"
                    icon="person-add"
                    href="/admin/patients/new"
                    className="w-full sm:w-auto transition-all duration-200 hover:brightness-125 hover:shadow-md"
                />
            </div>

            <PatientList />
        </AppMainContainer>
    )
}
