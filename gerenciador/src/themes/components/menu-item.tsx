"use client"
import Link from "next/link"
import { Ionicons } from "../../types/ionicons"
import { usePathname } from "next/navigation";


export interface AppMenuItemProps {
    title: string,
    icon: Ionicons
    url: string
}

export default function AppMenuItem ({title, icon, url}: AppMenuItemProps) {

    const path = usePathname();
    const isActive = path.startsWith(url);

    return (
        <Link href={url}>
            <h1 className={`group flex items-center gap-2 md:gap-3 px-2 md:px-3 py-2 cursor-pointer rounded-xl text-[16px] md:text-[17px] border transition-all duration-200 ${isActive ?  'text-white bg-(--primary-color) border-[#550402] shadow-md' : 'text-[#402321] border-transparent hover:border-[#eed0c5] hover:bg-[#fff1ea]' }`}>
                <span className={`h-8 w-8 rounded-lg flex items-center justify-center text-[18px] ${isActive ? 'bg-white/15' : 'bg-[#fff6f2] text-[#7a251d] group-hover:bg-[#ffe8df]'}`}>
                    <i className={`ion-${icon}`} />
                </span>
                <span className="hidden md:flex font-semibold tracking-[0.01em]">{title}</span>
            </h1>
        </Link>
    )
}
