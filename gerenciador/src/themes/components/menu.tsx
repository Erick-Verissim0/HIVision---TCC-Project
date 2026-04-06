"use client";
import { useRouter } from "next/navigation";
import AppMenuItem from "./menu-item";
import UserServices from "@/services/user";
import { useEffect, useState } from "react";
import Link from "next/link";

export default function AppMenu() {
    const router = useRouter();
    const [ user, setUser ] = useState<any>(null);
    // ==============================================================================
    const handleLogout = async () => {
        UserServices.logout();
        router.replace('/');
    }
    // --------------------------
    useEffect(() => {
        setUser(UserServices.getCurrentUser());
    }, []);

    const userDisplayName = user?.name ?? "Administrador";
    const userDisplayEmail = user?.email ?? "admin@admin.com";
    // ==============================================================================
    return (
         <div className="w-[72px] md:w-[320px] bg-[linear-gradient(180deg,#fffdfc_0%,#fff6f0_100%)] border-r border-[#ead7cf] shadow-[3px_0_20px_rgba(85,4,2,0.06)] flex flex-col px-2 md:px-4 py-5">
            <div className="flex justify-center md:hidden mb-3">
                <div className="h-11 w-11 rounded-2xl bg-[#fff0e8] border border-[#f0cdc0] text-[#7a251d] flex items-center justify-center shadow-sm">
                    <i className="ion-heart text-[20px]" />
                </div>
            </div>

            <div className="hidden md:flex flex-col rounded-2xl border border-[#f0ddd5] bg-white/85 px-4 py-4 shadow-sm">
                <h1 className="text-[20px] font-extrabold tracking-[0.04em] text-[#5c1711] leading-tight">
                    GERENCIADOR WEB
                </h1>
                <h2 className="text-[13px] text-[#8c7a74] mt-1">Bem-vindo!</h2>
                <h2 className="text-[14px] font-semibold text-[#6f211a] mt-2 break-words">
                    {userDisplayName} ({userDisplayEmail})
                </h2>
                <Link href={`/admin/users/edit/${user?.id}`}>
                    <p className="mt-3 inline-flex items-center justify-center rounded-full border border-[#efcfc3] bg-[#fff3ec] px-3 py-1 text-[13px] font-semibold text-[#7a251d] transition-colors hover:bg-[#ffe6db]">
                        Editar perfil
                    </p>
                </Link>
            </div>

            <div className="mt-4 md:mt-6 flex-1 space-y-1 px-1 md:px-0">
                <AppMenuItem title="Usuários" icon="ios-people" url="/admin/users"/>
                <AppMenuItem title="Pacientes" icon="person" url="/admin/patients"/>
                <AppMenuItem title="Consultas" icon="calendar" url="/admin/appointments"/>
                <AppMenuItem title="Locais" icon="pin" url="/admin/locations"/>
            </div>

            <div className="mt-3 mb-2">
                <button
                    type="button"
                    className="w-full rounded-xl border border-[#f2c7bc] bg-[#fff1ec] py-2 text-[16px] md:text-[17px] text-[#9b1717] cursor-pointer font-bold flex items-center justify-center gap-2 transition-colors hover:bg-[#ffe1d8]"
                    onClick={handleLogout}
                >
                    <i className="ion-log-out"/>
                    <span className="hidden md:inline">Sair</span>
                </button>
            </div>
        </div>
    )
}
