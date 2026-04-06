import { AppMainContainer } from "@/themes/components";
import UserEditForm from "./_form";

export const metadata = {
    title: 'Editar usuário'
}

// ===========================================================================
export default async function UserEditPage({params}: any) {

    const { userId } = await params;

    // ===========================================================================
    return (
        <AppMainContainer title="Editar usuário">
            <UserEditForm userId={userId}/>
        </AppMainContainer>
    )
}
