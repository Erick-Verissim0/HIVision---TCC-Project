"use client";
import { AppButton, AppInput, AppSelect } from "@/themes/components";
import { Formik } from "formik";
import * as Yup from 'yup';
import UserServices from "@/services/user";
import { useRouter } from "next/navigation";
import { setFlashData } from "@/helpers/router";
import { useState } from "react";

// ===========================================================================
export default function UserCreateForm() {

    const router = useRouter();
    const [ error, setError ] = useState<string|null>(null);
    // ===========================================================================
    const handleOnSubmit = async (data:any) => {
        setError(null);
        const { success, error } =  await UserServices.create(data);
        if (success) {
            setFlashData({success: 'Usuário criado com sucesso'});
            router.replace('/admin/users');
        } else if (error) {
            setError(error);
        }
    }
    // ===========================================================================
    return (
        <Formik
            initialValues={{name: '', email: '', password: '', type: 'doctor', cpf: '', crm: ''}}
            validationSchema={Yup.object({
                name: Yup.string().required('Campo obrigatório'),
                email: Yup.string().required('Campo obrigatório').email('Digite um email válido'),
                password: Yup.string().required('Campo obrigatório').min(6, 'Mínimo de 6 caracteres'),
                type: Yup.string().oneOf(['doctor', 'admin']).required('Campo obrigatório'),
                cpf: Yup.string().when('type', {
                    is: 'doctor',
                    then: (schema) => schema.required('Campo obrigatório').matches(/^\d{11}$/, 'Digite exatamente 11 dígitos'),
                    otherwise: (schema) => schema.notRequired(),
                }),
                crm: Yup.string().when('type', {
                    is: 'doctor',
                    then: (schema) => schema.required('Campo obrigatório'),
                    otherwise: (schema) => schema.notRequired(),
                }),
            })}
            onSubmit={handleOnSubmit}
            >
            {({handleChange, handleSubmit, isSubmitting, isValid, errors, values}) => (
                <form className="mx-auto max-w-4xl rounded-2xl border border-[#efdcd3] bg-[linear-gradient(160deg,#fffefc_0%,#fff7f2_100%)] p-5 md:p-7 shadow-[0_16px_32px_rgba(85,4,2,0.06)]">
                        <div className="mb-5 rounded-xl border border-[#f1ddd5] bg-white/85 p-4">
                            <h2 className="text-[20px] font-bold text-[#5c1711]">Novo Usuário</h2>
                            <p className="mt-1 text-[13px] text-[#8b7b75]">Preencha os dados abaixo para criar o cadastro.</p>
                        </div>

                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 md:gap-5">
                        <AppInput placeholder="Digite o nome" label="Nome:" name="name" onChange={handleChange} icon="person" error={errors.name} />
                        <AppInput placeholder="Digite o email" label="Email:" name="email" onChange={handleChange} icon="email" error={errors.email} />
                        <AppInput placeholder="Digite a senha" label="Senha:" name="password" type="password" onChange={handleChange} icon="locked" openPassword  error={errors.password}/>
                        <AppSelect label="Tipo:" name="type" value={values.type} onChange={handleChange} error={errors.type}>
                            <option value="doctor">Doctor</option>
                            <option value="admin">Admin</option>
                        </AppSelect>
                        </div>

                        {values.type === 'doctor' && (
                            <div className="mt-1 grid grid-cols-1 md:grid-cols-2 gap-4 md:gap-5">
                                <AppInput placeholder="Somente dígitos" label="CPF:" name="cpf" onChange={handleChange} icon="card" error={errors.cpf} />
                                <AppInput placeholder="Digite o CRM" label="CRM:" name="crm" onChange={handleChange} icon="clipboard" error={errors.crm} />
                            </div>
                        )}

                        {error && <p className="my-3 text-[tomato] text-[15px]">{error}</p>}

                        <div className="mt-5 flex justify-end">
                            <AppButton title="Salvar" icon="checkmark" onClick={() => handleSubmit()} disabled={!isValid || isSubmitting}/>
                        </div>

                </form>
            )}
        </Formik>

    )
}
