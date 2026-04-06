"use client";
import { useEffect, useRef, useState } from "react"
import UserServices from "@/services/user";
import Link from "next/link";
import { AppButton, AppInput, AppLoader, AppModal, AppSelect } from "@/themes/components";
import { getFlashData } from "@/helpers/router";
import { useRouter, useSearchParams } from "next/navigation";

export default function UserList() {

    const router = useRouter();
    const params = useSearchParams();
    const hasOpenedFromQuery = useRef(false);
    const [users, setUsers] = useState<any[]>([]);
    const [userRemove, setUserRemove] = useState<any>(null);
    const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
    const [createError, setCreateError] = useState<string | null>(null);
    const [createForm, setCreateForm] = useState({
        name: '',
        email: '',
        password: '',
        type: 'doctor',
        cpf: '',
        crm: '',
    });
    const [success, setSuccess] = useState<string | null>(null);
    const [error, setError] = useState<string | null>(null);
    const [loading, setLoading] = useState(true);
    const [page, setPage] = useState(Number(params.get('page') ?? 1));
    const [pagination, setPagination] = useState<any>(null);
    const [jumpPage, setJumpPage] = useState("1");
    const hasInitializedFilters = useRef(false);
    const [filter, setFilter] = useState({
        name: '',
        email: '',
        admin: '-1',
    })

    const requiredLabel = (label: string) => (
        <>
            {label} <span className="text-[red]">*</span>
        </>
    );

    // ======================================================================
    const getUsers = async (page: number, currentFilter = filter) => {
        const { success, users, pagination } = await UserServices.getAll(page, currentFilter);
        if (success) {
            setUsers(users ?? []);
            setPagination(pagination);
        }
        setLoading(false);
    }
    // -----------
    const handleRemove = async (user: any) => {
        setUserRemove(user);
        setSuccess(null);
        setError(null);
    }
    // -----------
    const handleModalConfirm = async () => {
        setLoading(true);
        setUserRemove(null);
        await UserServices.delete(userRemove.id)
        setSuccess('Usuário removido com sucesso!');
        getUsers(1);
    }
    // -----------
    const handleModalCancel = async () => {
        setUserRemove(null);
    }
    // -----------
    const handleOpenCreate = () => {
        setSuccess(null);
        setError(null);
        setCreateError(null);
        setCreateForm({
            name: '',
            email: '',
            password: '',
            type: 'doctor',
            cpf: '',
            crm: '',
        });
        setIsCreateModalOpen(true);
    }
    // -----------
    const handleCloseCreate = () => {
        setIsCreateModalOpen(false);
        setCreateError(null);

        if (params.get('new') === '1') {
            router.replace('/admin/users');
        }
    }
    // -----------
    const handleSaveCreate = async () => {
        setCreateError(null);
        setSuccess(null);

        const name = createForm.name.trim();
        const email = createForm.email.trim();
        const password = createForm.password;
        const cpf = createForm.cpf.replace(/\D/g, '');
        const crm = createForm.crm.trim();

        if (!name || !email || !password) {
            setCreateError('Nome, email e senha são obrigatórios');
            return;
        }

        if (password.length < 6) {
            setCreateError('A senha deve ter no mínimo 6 caracteres');
            return;
        }

        if (createForm.type === 'doctor') {
            if (cpf.length !== 11) {
                setCreateError('CPF deve conter 11 dígitos');
                return;
            }

            if (!crm) {
                setCreateError('CRM é obrigatório para médico');
                return;
            }
        }

        setLoading(true);

        const response = await UserServices.create({
            name,
            email,
            password,
            type: createForm.type,
            ...(createForm.type === 'doctor' ? { cpf, crm } : {}),
        });

        if (!response.success) {
            setLoading(false);
            setCreateError(response.error ?? 'Erro ao criar usuário');
            return;
        }

        setIsCreateModalOpen(false);
        setSuccess('Usuário criado com sucesso!');
        setPage(1);
        setJumpPage('1');
        await getUsers(1, filter);
    }
    // -----------
    const handlePage = async (newPage: number) => {
        setPage(newPage);
        setJumpPage(String(newPage));
        getUsers(newPage);
    }
    // -----------
    const handleJumpPage = async () => {
        if (!pagination?.totalPages) {
            return;
        }

        const parsed = Number(jumpPage);
        if (!Number.isFinite(parsed)) {
            return;
        }

        const target = Math.max(1, Math.min(pagination.totalPages, Math.trunc(parsed)));
        await handlePage(target);
    }
    // -----------
    useEffect(() => {
        // Load users.
        getUsers(page);
        // Load flash message.
        (() => {
            const data = getFlashData();
            if (data?.success) setSuccess(data.success);
            if (data?.error) setError(data.error);
        })()

    }, []);

    useEffect(() => {
        if (!hasInitializedFilters.current) {
            hasInitializedFilters.current = true;
            return;
        }

        const timeout = setTimeout(() => {
            setPage(1);
            getUsers(1, filter);
        }, 300);

        return () => clearTimeout(timeout);
    }, [filter]);

    useEffect(() => {
        if (params.get('new') === '1' && !hasOpenedFromQuery.current) {
            hasOpenedFromQuery.current = true;
            handleOpenCreate();
            router.replace('/admin/users');
        }
    }, [params, router]);
    return (
        <>
            <div className="flex flex-col border-b-[2px] border-[#dedede] p-2">
                <div className="flex flex-col gap-2 sm:flex-row sm:flex-wrap sm:items-end">
                    <AppInput
                        type="text"
                        label="Nome"
                        className="w-full sm:min-w-[220px] sm:flex-1"
                        placeholder="Digite o NOME do USUÁRIO"
                        value={filter.name}
                        onChange={(e) => setFilter({ ...filter, name: e.target.value })}
                    />
                    <AppInput type="email" label="Email" className="w-full sm:min-w-[220px] sm:flex-1" value={filter.email} onChange={(e) => setFilter({ ...filter, email: e.target.value })} />

                    <AppSelect className="w-full sm:min-w-[180px] sm:flex-1" label="Administrador" value={filter.admin} onChange={(e) => setFilter({ ...filter, admin: e.target.value })}>
                        <option value="-1">Todos</option>
                        <option value="1">Sim</option>
                        <option value="0">Não</option>
                    </AppSelect>

                </div>
            </div>

            {success && <p className="bg-[#6eef01] px-5 text-center rounded-full color-[white] p-1">{success}</p>}
            {error && <p className="bg-[tomato] px-5 text-center rounded-full color-[white] p-1">{error}</p>}

            {loading && <div className="flex justify-center"><AppLoader size={50} className="self-center" /></div>}
            {!loading && <div>
                <div className="overflow-x-auto max-h-[58vh] overflow-y-auto rounded-xl border border-[#edd7ce]">
                <table className="min-w-full bg-white">
                    <thead>
                        <tr>
                            <th className="py-2 px-4 border-b border-gray-200 text-left text-sm font-semibold text-gray-600">Nome</th>
                            <th className="py-2 px-4 border-b border-gray-200 text-left text-sm font-semibold text-gray-600">Email</th>
                            <th className="py-2 px-4 border-b border-gray-200 text-left text-sm font-semibold text-gray-600">Admin</th>
                            <th className="py-2 px-4 border-b border-gray-200 text-left text-sm font-semibold text-gray-600">Ações</th>
                        </tr>
                    </thead>

                    <tbody>
                        {users.map(user => (
                            <tr key={user.id}>
                                <td className="py-2 px-4 border-b border-gray-200 text-sm">{user.name}</td>
                                <td className="py-2 px-4 border-b border-gray-200 text-sm">{user.email}</td>
                                <td className="py-2 px-4 border-b border-gray-200 text-sm">{user.admin ? 'ADMINISTRADOR' : 'MÉDICO'}</td>

                                <td className="py-2 px-4 border-b border-gray-200 text-sm">
                                    <Link href={`/admin/users/edit/${user.id}`}>
                                        <i className="ion-edit text-[20px] text-[#1aab67] mx-[10px] cursor-pointer" />
                                    </Link>
                                    <i className="ion-ios-trash text-[20px] text-[#ed1b2d]  mx-[10px] cursor-pointer" onClick={() => handleRemove(user)} />
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
                </div>

                {(pagination?.totalPages ?? 1) >= 2 && (
                    <div className="mt-[20px] flex flex-col gap-3 lg:flex-row lg:items-center">
                        <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:gap-2">
                            <p className="text-sm font-semibold text-[#550402] bg-[#f8eceb] px-3 py-1 rounded-full">Selecione a página que deseja ir</p>
                            <AppInput
                                type="number"
                                label=""
                                className="w-[90px] shrink-0"
                                value={jumpPage}
                                onChange={(e) => setJumpPage(e.target.value)}
                            />
                            <AppButton title="Ir" icon="arrow-right-a" form="round" onClick={handleJumpPage} />
                        </div>
                        <div className="flex flex-wrap items-center gap-2 lg:ml-auto">
                            <p className="text-sm text-gray-600 mr-2">Página {pagination?.page ?? 1} de {pagination?.totalPages ?? 1}</p>
                            <AppButton title="Anterior" className="mr-[10px]" icon="arrow-left-a" form="round" onClick={() => handlePage(page - 1)} disabled={Boolean(pagination?.firstPage ?? true)} />
                            <AppButton title="Próximo" className="ml-[10px]" icon="arrow-right-a" form="round" onClick={() => handlePage(page + 1)} disabled={Boolean(pagination?.lastPage ?? true)} />
                        </div>
                    </div>
                )}
            </div>}

            {userRemove && <AppModal title="Remover usuário">
                <p>Deseja realmente remover o usuário {userRemove.name} ({userRemove.email})?</p>
                <div className="flex justify-between p-[20px]">
                    <AppButton title="Sim" icon="checkmark" form="round" color="#428f01" onClick={handleModalConfirm} />
                    <AppButton title="Cancelar" icon="close" color="tomato" form="round" onClick={handleModalCancel} />
                </div>

            </AppModal>}

            {isCreateModalOpen && <AppModal title="Criar usuário" onClose={handleCloseCreate}>
                <div className="mx-auto w-[700px] max-w-full rounded-2xl border border-[#f0ddd5] bg-white/85 p-4 md:p-5">
                    <div className="mb-4 rounded-xl border border-[#f2dfd7] bg-[#fff9f5] px-4 py-3">
                        <p className="text-[18px] font-bold text-[#5c1711]">Dados do usuário</p>
                        <p className="text-[13px] text-[#8b7b75]">Preencha os dados para cadastrar um novo usuário.</p>
                        <p className="text-[12px] text-[#8b7b75]"><span className="text-[red]">*</span> indica campo obrigatório.</p>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4 md:gap-5">
                        <AppInput
                            type="text"
                            label={requiredLabel("Nome")}
                            placeholder="Digite o NOME do USUÁRIO"
                            value={createForm.name}
                            onChange={(e) => setCreateForm({ ...createForm, name: e.target.value })}
                        />

                        <AppInput
                            type="email"
                            label={requiredLabel("Email")}
                            placeholder="Digite o EMAIL"
                            value={createForm.email}
                            onChange={(e) => setCreateForm({ ...createForm, email: e.target.value })}
                        />

                        <AppInput
                            type="password"
                            label={requiredLabel("Senha")}
                            placeholder="Digite a SENHA"
                            value={createForm.password}
                            onChange={(e) => setCreateForm({ ...createForm, password: e.target.value })}
                        />

                        <AppSelect
                            label={requiredLabel("Tipo")}
                            value={createForm.type}
                            onChange={(e) => setCreateForm({ ...createForm, type: e.target.value })}
                        >
                            <option value="doctor">Doctor</option>
                            <option value="admin">Admin</option>
                        </AppSelect>
                    </div>

                    {createForm.type === 'doctor' && (
                        <div className="mt-4 grid grid-cols-1 md:grid-cols-2 gap-4 md:gap-5">
                            <AppInput
                                type="text"
                                label={requiredLabel("CPF")}
                                placeholder="Somente dígitos"
                                value={createForm.cpf}
                                onChange={(e) => setCreateForm({ ...createForm, cpf: e.target.value })}
                            />

                            <AppInput
                                type="text"
                                label={requiredLabel("CRM")}
                                placeholder="Digite o CRM"
                                value={createForm.crm}
                                onChange={(e) => setCreateForm({ ...createForm, crm: e.target.value })}
                            />
                        </div>
                    )}

                    {createError && (
                        <p className="mt-4 rounded-full bg-[tomato] px-4 py-1 text-center text-[white]">{createError}</p>
                    )}

                    <div className="mt-5 flex justify-end gap-3">
                        <AppButton title="Cancelar" icon="close" form="round" color="tomato" onClick={handleCloseCreate} />
                        <AppButton title="Salvar" icon="checkmark" form="round" onClick={handleSaveCreate} />
                    </div>
                </div>
            </AppModal>}
        </>
    )
}
