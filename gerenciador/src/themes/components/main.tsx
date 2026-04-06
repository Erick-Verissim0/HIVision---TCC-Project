import React from "react";

export interface AppMainContainerProps {
    title: string;
    children?: React.ReactNode;
}

export default function AppMainContainer({title, children}: AppMainContainerProps) {
    const year = new Date().getFullYear();

    return (
         <main className="flex flex-col flex-1 gap-4 bg-gradient-to-b from-[#fff9f6] to-[#f8f6f4]">
            <div className="bg-(--background-primary) rounded-b-2xl border-b border-[#edd7ce] shadow-sm px-4 py-3 md:px-8">
                <div className="flex items-center justify-between">
                    <span className="inline-flex items-center rounded-full bg-[#fff0e8] px-4 py-1 text-[12px] md:text-[13px] font-semibold tracking-[0.08em] text-[#7a251d] uppercase border border-[#f2cfc2]">
                        HIVISION
                    </span>
                    <span className="text-[11px] md:text-[12px] text-[#8b7b75] font-medium">
                        Gerenciador Clinico
                    </span>
                </div>
            </div>

            <header className="relative overflow-hidden min-h-[110px] bg-(--background-primary) py-5 px-4 md:px-8 rounded-2xl border border-[#edd7ce] shadow-sm">
                <div className="pointer-events-none absolute right-[-55px] top-[-55px] h-[160px] w-[160px] rounded-full bg-[#ffe4d9] opacity-70" />
                <div className="pointer-events-none absolute right-[40px] bottom-[-70px] h-[140px] w-[140px] rounded-full bg-[#ffeede] opacity-70" />
                <h1 className="relative font-bold text-[28px] md:text-[32px] text-[#4f140f] leading-tight">{title}</h1>
                <p className="relative mt-1 text-[13px] md:text-[14px] text-[#8b7b75]">Painel administrativo</p>
            </header>

            <section className="relative flex-1 min-h-0 overflow-hidden rounded-2xl border border-[#edd7ce] bg-[linear-gradient(140deg,#fffdfb_0%,#fff7f2_45%,#fffefc_100%)] p-3 md:p-4 shadow-sm">
                <div className="pointer-events-none absolute left-[-40px] top-[-50px] h-[140px] w-[140px] rounded-full bg-[#ffe6dc] opacity-70" />
                <div className="pointer-events-none absolute right-[-35px] bottom-[-45px] h-[120px] w-[120px] rounded-full bg-[#ffeede] opacity-70" />

                <div className="relative h-full overflow-y-auto rounded-xl border border-[#f1ddd5] bg-white/90 p-4 md:p-5 shadow-[inset_0_1px_0_rgba(255,255,255,0.9),0_10px_25px_rgba(85,4,2,0.05)] backdrop-blur-sm">
                    {children}
                </div>
            </section>

            <footer className="mt-1 bg-(--background-primary) rounded-t-2xl border-t border-[#edd7ce] px-4 py-3 md:px-8 shadow-[0_-2px_10px_rgba(85,4,2,0.04)]">
                <div className="flex flex-col gap-1 text-[12px] md:text-[13px] text-[#7f6d67] md:flex-row md:items-center md:justify-between">
                    <p className="font-semibold text-[#6b1f18]">HIVISION</p>
                    <p>Gestao de pacientes, consultas e equipes medicas</p>
                    <p className="font-medium">{year}</p>
                </div>
            </footer>

        </main>
    )

}
