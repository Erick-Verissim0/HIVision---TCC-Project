import { AppMainContainer } from "@/themes/components";
import UserCreateForm from "./_form";

export const metadata = {
    title: 'Criar usuário'
}

// ===========================================================================
export default function UserCreatePage() {

    // ===========================================================================
    return (
        <AppMainContainer title="Novo usuário">
            <UserCreateForm/>
        </AppMainContainer>
    )
}
