"use client";
import { ReactNode, useState } from "react";

export interface AppInputProps {
    name?: string
    children: ReactNode;
    onChange?: (e: any) => void
    value?: string;
    label?: ReactNode;
    error?: string
    style?: any;
    className?: string
}

export default function AppSelect ({children, name, onChange, value, label, error = "", style = {}, className = ''}: AppInputProps ) {
    // -------------------------------------------------------------------------
    const [ showPassword, setShowPassword ] = useState(false);
    const [ touched, setTouched ] = useState(false);
    // -------------------------------------------------------------------------
    return (
        <div className={className} style={style}>
            <p className="ff-default ml-3 mb-[-10px]">{label}</p>
            <div className="rounded-xl border-[2] border-[#dedede] p-2 flex bg-[#f5f5f5] my-2">
                <select className="w-[100%]" onChange={onChange} onBlur={() => setTouched(true)} name={name} value={value}>
                    {children}
                </select>
            </div>
            {touched && error && <p className="text-[tomato] ff-default text-[12px] text-right mt-[-10px]">{error}</p>}
        </div>
    )
}
