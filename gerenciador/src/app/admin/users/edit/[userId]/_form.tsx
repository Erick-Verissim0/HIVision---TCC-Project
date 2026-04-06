"use client";
import { AppButton, AppInput } from "@/themes/components";
import { Formik } from "formik";
import * as Yup from 'yup';
import UserServices from "@/services/user";
import { useRouter } from "next/navigation";
import { setFlashData } from "@/helpers/router";
import { useEffect, useState } from "react";

export interface UserFormProps {
    userId: string
}
// ===========================================================================
export default function UserEditForm({ userId }: UserFormProps) {

    const router = useRouter();
    const [ user, setUser ] = useState({name: '', email: '', cpf: '', currentPassword: '', newPassword: ''});
    const [ error, setError ] = useState<string|null>(null);
    const [ formError, setFormError ] = useState<string|null>(null);
    // ===========================================================================
    const handleOnSubmit = async (data:any) => {
        setError(null);
        setFormError(null);
        const { success, error } =  await UserServices.update(userId, data);
        if (success) {
            setFlashData({success: 'Usuário atualizado com sucesso'});
            router.replace('/admin/users');
        } else if (error) {
            setError(error);
        }
    }
    // -----------------------
    useEffect(() => {
        (async() => {
            const { success, user } = await UserServices.getById(userId);
            if (success) {
                setUser({
                    name: user.name ?? '',
                    email: user.email ?? '',
                    cpf: user.cpf ?? '',
                    currentPassword: '',
                    newPassword: '',
                });
            }
            else {
                setFlashData({error: 'Usuário não encontrado'});
                router.replace('/admin/users');
            }
        })();
    }, [])
    // ===========================================================================
    return (
        <Formik
            initialValues={user}
            enableReinitialize
            validationSchema={Yup.object({
                name: Yup.string().required('Campo obrigatório'),
                email: Yup.string().required('Campo obrigatório').email('Digite um email válido'),
                currentPassword: Yup.string().required('Campo obrigatório'),
                newPassword: Yup.string().required('Campo obrigatório').min(6, 'Mínimo de 6 caracteres'),
                cpf: Yup.string().test('cpf-format', 'Digite exatamente 11 dígitos', (value) => {
                    if (!value || !value.trim()) return true;
                    return /^(\d{11}|\d{3}\.\d{3}\.\d{3}-\d{2})$/.test(value);
                }),
            })}
            onSubmit={handleOnSubmit}
            >
            {({handleChange, handleSubmit, isSubmitting, isValid, errors, values}) => (
                <form className="mx-auto max-w-4xl rounded-2xl border border-[#efdcd3] bg-[linear-gradient(160deg,#fffefc_0%,#fff7f2_100%)] p-5 md:p-7 shadow-[0_16px_32px_rgba(85,4,2,0.06)]">
                        <div className="mb-5 rounded-xl border border-[#f1ddd5] bg-white/85 p-4">
                            <h2 className="text-[20px] font-bold text-[#5c1711]">Dados do Usuário</h2>
                            <p className="mt-1 text-[13px] text-[#8b7b75]">Atualize as informações abaixo para manter o cadastro sempre correto.</p>
                            <p className="mt-1 text-[12px] text-[#8b7b75]"><span className="text-[red]">*</span> indica campo obrigatório.</p>
                        </div>

                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 md:gap-5">
                            <AppInput placeholder="Digite o nome" label={<><span>Nome:</span> <span className="text-[red]">*</span></>} name="name" onChange={handleChange} icon="person" error={errors.name} value={values.name} />
                            <AppInput placeholder="Digite o email" label={<><span>Email:</span> <span className="text-[red]">*</span></>} name="email" onChange={handleChange} icon="email" error={errors.email} value={values.email} />
                            <AppInput placeholder="Somente dígitos" label="CPF:" name="cpf" onChange={handleChange} icon="card" error={errors.cpf} value={values.cpf} />
                            <AppInput placeholder="Digite a senha atual" label={<><span>Senha atual:</span> <span className="text-[red]">*</span></>} name="currentPassword" type="password" onChange={handleChange} icon="locked" openPassword  error={errors.currentPassword} value={values.currentPassword} />
                            <AppInput placeholder="Digite a nova senha" label={<><span>Nova senha:</span> <span className="text-[red]">*</span></>} name="newPassword" type="password" onChange={handleChange} icon="locked" openPassword  error={errors.newPassword} value={values.newPassword} />
                        </div>

                        {formError && <p className="my-3 rounded-full bg-[tomato] p-1 text-center text-[15px] text-[white]">{formError}</p>}
                        {error && <p className="my-3 text-[tomato] text-[15px]">{error}</p>}

                        <div className="mt-5 flex justify-end">
                            <AppButton
                                title="Atualizar"
                                icon="checkmark"
                                onClick={async () => {
                                    setFormError(null);
                                    const missingRequired: string[] = [];

                                    if (!values.name?.trim()) {
                                        missingRequired.push("Nome");
                                    }

                                    if (!values.email?.trim()) {
                                        missingRequired.push("Email");
                                    }

                                    if (!values.currentPassword?.trim()) {
                                        missingRequired.push("Senha atual");
                                    }

                                    if (!values.newPassword?.trim()) {
                                        missingRequired.push("Nova senha");
                                    }

                                    if (missingRequired.length > 0) {
                                        setFormError(`Preencha os campos obrigatórios: ${missingRequired.join(", ")}.`);
                                        return;
                                    }

                                    handleSubmit();
                                }}
                                disabled={isSubmitting}
                            />
                        </div>
                </form>
            )}
        </Formik>

    )
}
