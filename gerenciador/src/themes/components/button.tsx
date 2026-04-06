import Link from "next/link"
import { Ionicons } from "@/types/ionicons"

export interface AppButtonProps {
    title: string
    color?: string
    textColor?: string
    onClick?: () => void
    href?: string
    form?: 'square'|'round'
    type?: 'solid'|'outline'
    disabled?: boolean
    icon?: Ionicons;
    style?: any;
    className?: string
}
// ==========================================================================
export default function AppButton({title, onClick, color='--primary-color', textColor='white', form='square', type='solid', disabled, icon, href, style = {}, className = ''}: AppButtonProps) {

    let tailwind = className + ' flex justify-center py-[5px] px-[15px] text-[15px] flex border';
    let dynamicStyle = {
        ...style,
        background: color.startsWith('--') ? `var(${color})` : color,
        borderColor: color.startsWith('--') ? `var(${color})` : color,
        color: textColor.startsWith('--') ? `var(${textColor})` : textColor
    }

    //Tipo
    if (type == 'outline') {
        dynamicStyle['background'] = 'transparent';
        dynamicStyle['color'] = color.startsWith('--') ? `var(${color})` : color;
    }

    //Forma
    if (form == 'round') tailwind += ' rounded-full'

    //Habilitado
    if (disabled) tailwind += ' opacity-50'
    else tailwind += ' cursor-pointer'



    // ==========================================================================
    // ------------------------
    // ==========================================================================
    return (
        <Link href={href ? href : '#'}>
            <div className={tailwind} style={dynamicStyle} onClick={disabled ? () => {} : onClick}>
                {icon && <i className={`ion-${icon} mr-[5px]`} />}
                <p className="ff-default">{title}</p>
            </div>
        </Link>
    )
}
