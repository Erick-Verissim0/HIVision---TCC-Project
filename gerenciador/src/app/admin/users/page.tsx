import { AppButton, AppMainContainer } from "@/themes/components";
import UserList from "./_list";

export const metadata = {
    title:'Lista de usuários'
}
// ==========================================================
export default function UsersPage() {

    // ==========================================================
    return (
        <AppMainContainer title="Usuários">
            <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                <h1 className="font-bold text-[20px]">Lista de Usuários</h1>

                <AppButton title='Novo usuário' form="round" type="outline" icon="person-add" href="/admin/users?new=1" className="w-full sm:w-auto transition-all duration-200 hover:brightness-125 hover:shadow-md" />
            </div>

            <UserList />
        </AppMainContainer>
    )
}
