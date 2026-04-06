"use client";
import { ReactNode, useState } from "react";
import { Ionicons } from "../../types/ionicons";

export interface AppInputProps {
    name?: string
    type?: string;
    onChange?: (e: any) => void
    placeholder?: string;
    value?: string;
    label?: ReactNode;
    list?: string;
    icon?: Ionicons
    openPassword?: boolean;
    error?: any
    style?: any;
    className?: string
}

export default function AppInput ({type="text", name, onChange, placeholder, value, label, list, icon, openPassword = false, error = "", style = {}, className = ''}: AppInputProps ) {
    // -------------------------------------------------------------------------
    const [ showPassword, setShowPassword ] = useState(false);
    const [ touched, setTouched ] = useState(false);
    // -------------------------------------------------------------------------
    return (
        <div className={className} style={style}>
            <p className="ff-default mb-[-10px]">{label}</p>
            <div className="rounded-xl border-[2] border-[#dedede] p-2 flex bg-[#f5f5f5] my-2">
                {icon && <i className={`ion-${icon} mx-2 text-[grey]`} />}
                <input type={openPassword ? showPassword ? "text" : "password" : type} name={name} placeholder={placeholder} value={value} list={list} className="flex-1" onChange={onChange} onBlur={() => setTouched(true)}/>
                {openPassword &&<i className={`${showPassword ? "ion-eye" : "ion-eye-disabled"} mx-2 text-[grey]`} onClick={() => setShowPassword(!showPassword)} />}
            </div>
            {touched && error && <p className="text-[tomato] ff-default text-[12px] text-right mt-[-10px]">{error}</p>}
        </div>
    )
}
