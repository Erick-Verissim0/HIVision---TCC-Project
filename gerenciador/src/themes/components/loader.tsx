
export interface AppLoaderProps {
    size?: number,
    color?: string,
    className?: string
}


export default function AppLoader({size = 80, color = undefined, className = ''}: AppLoaderProps) {
    return (
        <div className={`loader ${className}`} style={{width: `${size}px`, height: `${size}px`, borderTopColor: color}}></div>
    )
}