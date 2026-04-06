import { ReactNode } from "react"

export interface AppModalProps {
    children: ReactNode;
    title?: string;
    onClose?: () => void;
}

export default function AppModal({children, title, onClose}: AppModalProps) {
    return (
        <div>
            <div className="fixed inset-0 z-40 bg-[rgba(54,23,18,0.45)] backdrop-blur-[2px]"/>

            <div className="fixed inset-0 z-50 overflow-y-auto px-2 py-2 md:px-8 md:py-8">
                <div className="flex min-h-full items-start justify-center sm:items-center">
                    <div className="my-auto w-full max-w-[980px] max-h-[calc(100dvh-1rem)] sm:max-h-[88vh] flex flex-col overflow-hidden rounded-2xl border border-[#efd8cf] bg-[linear-gradient(160deg,#fffdfb_0%,#fff7f2_100%)] shadow-[0_22px_50px_rgba(58,16,11,0.25)]">
                    <div className="flex items-center justify-between border-b border-[#f1ddd5] bg-white/70 px-4 py-3 md:px-7 md:py-5">
                        <p className="ff-default text-[18px] md:text-[28px] font-bold text-[#5c1711] leading-tight">{title}</p>
                        {onClose && (
                            <button
                                type="button"
                                className="h-9 w-9 rounded-full border border-[#efcbc0] bg-[#fff1ea] text-[#7a251d] flex items-center justify-center cursor-pointer hover:bg-[#ffe4d8]"
                                onClick={() => onClose()}
                            >
                                <i className="ion-close text-[20px]" />
                            </button>
                        )}
                    </div>
                    <div className="overflow-y-auto px-4 py-3 md:px-7 md:py-5">
                        {children}
                    </div>
                </div>
                </div>
            </div>
        </div>
    )
}
