"use client";
import { AppButton, AppInput, AppModal } from "@/themes/components";
import { Formik } from "formik";
import Image from "next/image";
import { useState } from "react";
import * as Yup from 'yup';
import UserServices from "@/services/user";
import { useRouter } from "next/navigation";

export default function LoginForm() {
    const [ showResetPasswordModal, setShowResetPasswordModal ] = useState(false);
    const [ email, setEmail ] = useState('');
    const [ errorLogin, setErrorLogin ] = useState<string|null>(null);
    const [ messageResetPassword, setMessageResetPassword ] = useState<{success: boolean, message: string}|null>(null);
    const router = useRouter();
    // ======================================================
    const onSubmitLogin = async ({email, password}: any) => {

        setErrorLogin(null);
        const { success, message } = await UserServices.login(email, password);
        if (success)
            router.push('/admin/users');
        else
            setErrorLogin(message ?? 'Email ou senha inválidos');
    }
    // -------
    const onSubmitResetPassword = async () => {

        setErrorLogin(null);
        setEmail('');
        const { success } = await UserServices.resetPassword(email);
        if (success)
            setMessageResetPassword({success: true, message: 'Verifique sua caixa de entrada para redefinir a senha'});
        else
            setMessageResetPassword({success: false, message: 'Não foi possível redefinir a senha'});
    }
    // --------
    const closeModal = () => {
        setEmail('');
        setShowResetPasswordModal(false);
    }
    // ======================================================
    return (
        <>
            <Formik
                initialValues={{email: '', password: ''}}
                validationSchema={Yup.object({
                    email: Yup.string().required('Campo obrigatório').email('Digite um email válido'),
                    password: Yup.string().required('Campo obrigatório').min(6, 'Mínimo de 6 caracteres')
                })}
                onSubmit={onSubmitLogin}
                >
                {({handleChange, handleSubmit, isSubmitting, isValid, errors}) => (
                    <form onSubmit={handleSubmit}>
                        <div className="w-[336px] flex flex-col">

                            <h1 className="ff-default text-[37px] text-center">Entrar</h1>
                            <AppInput placeholder="EMAIL" name="email" onChange={handleChange} icon="ios-email" error={errors.email} />
                            <AppInput placeholder="SENHA" name="password" type="password" onChange={handleChange} icon="locked" openPassword  error={errors.password}/>

                            <p className="cursor-pointer text-[11px] ff-default text-[#550402]" onClick={() => setShowResetPasswordModal(true)}>Esqueci minha senha</p>

                            {errorLogin && <p className="text-[tomato] ff-default text-[20px] text-center mt-3">{errorLogin}</p>}


                            <AppButton title="Entrar" onClick={handleSubmit} disabled={isSubmitting || !isValid} form="round" />

                            <p className="ff-default text-center">Não tem uma conta? Contate o desenvolvedor</p>
                        </div>
                    </form>
                )}
            </Formik>

            {showResetPasswordModal && <AppModal title="Esqueci a senha" onClose={() => closeModal()}>
                <div className="flex-col flex items-stretch">

                    <Image className="self-center my-10" src="/assets/img/icons/reset-password.png" alt="reset password icon" width={120} height={120} />

                    <p className="text-center ff-default text-[16px]">Digite seu email e clique em &quot;Enviar&quot; para receber as instruções de redefinição de senha.</p>

                    <AppInput placeholder="Digite seu email" icon="android-mail" value={email} onChange={(e) => setEmail(e.target.value)}/>

                    {messageResetPassword?.success == false && <p className="text-[tomato] ff-default text-[20px] text-center mt-3">{messageResetPassword.message}</p>}
                    {messageResetPassword?.success == true && <p className="text-[green] ff-default text-[20px] text-center mt-3">{messageResetPassword.message}</p>}

                    <div className="flex justify-between">
                        <button className="bg-white border border-[red] text-[red] rounded-full w-[170px] py-2 mt-5 cursor-pointer" onClick={closeModal}>Cancelar</button>
                        <button className="bg-(--primary-color) text-white rounded-full w-[170px] py-2 mt-5  cursor-pointer" onClick={onSubmitResetPassword}>Enviar</button>
                    </div>
                </div>
            </AppModal>}
        </>
    )
}
