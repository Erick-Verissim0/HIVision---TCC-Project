"use client";

import { useEffect, useRef, useState } from "react";
import { AppButton, AppInput, AppLoader, AppModal, AppSelect } from "@/themes/components";
import PatientServices from "@/services/patient";
import { useRouter, useSearchParams } from "next/navigation";
import Link from "next/link";

type Patient = {
  id: string;
  doctorId: string;
  name: string;
  cpf: string;
  lastAppointment?: string;
};

const maskCpf = (cpf: string): string => {
  const onlyDigits = cpf.replace(/\D/g, "");
  const normalized = (onlyDigits + "00000000000").slice(0, 11);
  const lastFive = normalized.slice(-5);
  return `***.***.${lastFive.slice(0, 3)}-${lastFive.slice(3)}`;
};

const maskName = (fullName: string): string => {
  const parts = fullName.trim().split(/\s+/).filter(Boolean);
  const blockedWords = new Set(["da", "dos", "de", "do", "das", "e"]);

  if (!parts.length) {
    return "";
  }

  const isVisibleCandidate = (word: string): boolean => {
    const normalizedWord = word.toLowerCase();
    return word.length >= 4 && !blockedWords.has(normalizedWord);
  };

  const pickVisibleIndex = (preferredIndex: number, used: Set<number>): number | null => {
    if (
      preferredIndex >= 0 &&
      preferredIndex < parts.length &&
      !used.has(preferredIndex) &&
      isVisibleCandidate(parts[preferredIndex])
    ) {
      return preferredIndex;
    }

    for (let i = preferredIndex + 1; i < parts.length; i += 1) {
      if (!used.has(i) && isVisibleCandidate(parts[i])) {
        return i;
      }
    }

    for (let i = Math.min(preferredIndex - 1, parts.length - 1); i >= 0; i -= 1) {
      if (!used.has(i) && isVisibleCandidate(parts[i])) {
        return i;
      }
    }

    return null;
  };

  const visibleIndexes = new Set<number>();
  [0, 2].forEach((preferredIndex) => {
    const selectedIndex = pickVisibleIndex(preferredIndex, visibleIndexes);
    if (selectedIndex !== null) {
      visibleIndexes.add(selectedIndex);
    }
  });

  return parts
    .map((part, index) => (visibleIndexes.has(index) ? part : "*".repeat(part.length)))
    .join(" ");
};

export default function PatientList() {
  const router = useRouter();
  const params = useSearchParams();
  const hasOpenedFromQuery = useRef(false);
  const hasOpenedEditFromQuery = useRef(false);
  const [patients, setPatients] = useState<Patient[]>([]);
  const [doctors, setDoctors] = useState<Array<{ id: string; name: string }>>([]);
  const hasInitializedFilters = useRef(false);
  const [name, setName] = useState("");
  const [cpfFilter, setCpfFilter] = useState("");
  const [page, setPage] = useState(1);
  const [pagination, setPagination] = useState<any>(null);
  const [jumpPage, setJumpPage] = useState("1");
  const [modalMode, setModalMode] = useState<"create" | "edit" | null>(null);
  const [patientForm, setPatientForm] = useState({
    id: "",
    doctorId: "",
    name: "",
    cpf: "",
    lastAppointment: "",
  });
  const [patientRemove, setPatientRemove] = useState<Patient | null>(null);
  const [createError, setCreateError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const requiredLabel = (label: string) => {
    if (modalMode !== "create") {
      return label;
    }

    return (
      <>
        {label} <span className="text-[red]">*</span>
      </>
    );
  };

  const normalizeCpf = (value: string): string => value.replace(/\D/g, "").slice(0, 11);

  const formatCpf = (value: string): string => {
    const digits = value.replace(/\D/g, "").slice(0, 11);
    if (digits.length <= 3) return digits;
    if (digits.length <= 6) return `${digits.slice(0, 3)}.${digits.slice(3)}`;
    if (digits.length <= 9) return `${digits.slice(0, 3)}.${digits.slice(3, 6)}.${digits.slice(6)}`;
    return `${digits.slice(0, 3)}.${digits.slice(3, 6)}.${digits.slice(6, 9)}-${digits.slice(9)}`;
  };

  const toDateInputValue = (value?: string): string => {
    if (!value) {
      return "";
    }

    return new Date(value).toISOString().slice(0, 10);
  };

  const loadPatients = async (
    filters: { name?: string; cpf?: string } = {},
    pageNumber = 1,
  ) => {
    setLoading(true);
    setError(null);

    const { success, patients, pagination, error } = await PatientServices.getAll(
      filters,
      pageNumber,
    );
    if (success) {
      setPatients(patients);
      setPagination(pagination ?? null);
    } else {
      setPatients([]);
      setPagination(null);
      setError(error ?? "Erro ao carregar pacientes");
    }

    setLoading(false);
  };

  const loadDoctors = async () => {
    const { success, doctors, error } = await PatientServices.getDoctors();
    if (success) {
      setDoctors(doctors);
      return;
    }

    setError(error ?? "Erro ao carregar médicos");
  };

  const handleOpenCreate = () => {
    setSuccess(null);
    setError(null);
    setCreateError(null);
    setPatientForm({
      id: "",
      doctorId: doctors[0]?.id ?? "",
      name: "",
      cpf: "",
      lastAppointment: "",
    });
    setModalMode("create");
  };

  const handleOpenEdit = (patient: Patient) => {
    setSuccess(null);
    setError(null);
    setCreateError(null);
    setPatientForm({
      id: patient.id,
      doctorId: patient.doctorId,
      name: patient.name,
      cpf: formatCpf(patient.cpf),
      lastAppointment: toDateInputValue(patient.lastAppointment),
    });
    setModalMode("edit");
  };

  const handleCloseModal = () => {
    const shouldCleanNewQuery = modalMode === "create" && params.get("new") === "1";
    setModalMode(null);
    setCreateError(null);

    if (shouldCleanNewQuery) {
      router.replace("/admin/patients");
    }
  };

  const handleSavePatient = async () => {
    setError(null);
    setCreateError(null);
    setSuccess(null);

    const trimmedName = patientForm.name.trim();
    const cpfDigits = normalizeCpf(patientForm.cpf);

    if (!patientForm.doctorId) {
      if (modalMode === "create") {
        setCreateError("Selecione um médico");
      } else {
        setError("Selecione um médico");
      }
      return;
    }

    if (!trimmedName) {
      if (modalMode === "create") {
        setCreateError("Informe o nome do paciente");
      } else {
        setError("Informe o nome do paciente");
      }
      return;
    }

    if (cpfDigits.length !== 11) {
      if (modalMode === "create") {
        setCreateError("CPF deve conter 11 dígitos");
      } else {
        setError("CPF deve conter 11 dígitos");
      }
      return;
    }

    setLoading(true);

    const payload = {
      doctorId: patientForm.doctorId,
      name: trimmedName,
      cpf: cpfDigits,
      ...(patientForm.lastAppointment
        ? { lastAppointment: new Date(patientForm.lastAppointment).toISOString() }
        : {}),
    };

    const response =
      modalMode === "create"
        ? await PatientServices.create(payload)
        : await PatientServices.update(patientForm.id, payload);

    if (!response.success) {
      setLoading(false);
      if (modalMode === "create") {
        setCreateError(response.error ?? "Erro ao salvar paciente");
      } else {
        setError(response.error ?? "Erro ao salvar paciente");
      }
      return;
    }

    setModalMode(null);
    setSuccess(
      modalMode === "create"
        ? "Paciente criado com sucesso!"
        : "Paciente atualizado com sucesso!",
    );
    setPage(1);
    await loadPatients({ name, cpf: cpfFilter }, 1);
  };

  const handleOpenRemove = (patient: Patient) => {
    setSuccess(null);
    setError(null);
    setPatientRemove(patient);
  };

  const handleConfirmRemove = async () => {
    if (!patientRemove) {
      return;
    }

    setLoading(true);
    setError(null);
    setSuccess(null);

    const response = await PatientServices.delete(patientRemove.id);
    if (!response.success) {
      setLoading(false);
      setError(response.error ?? "Erro ao remover paciente");
      return;
    }

    setPatientRemove(null);
    setSuccess("Paciente removido com sucesso!");
    await loadPatients({ name, cpf: cpfFilter }, page);
  };

  const handlePage = async (newPage: number) => {
    setPage(newPage);
    setJumpPage(String(newPage));
    await loadPatients({ name, cpf: cpfFilter }, newPage);
  };

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
  };

  useEffect(() => {
    loadPatients({ name: "", cpf: "" }, page);
    loadDoctors();
  }, []);

  useEffect(() => {
    if (!hasInitializedFilters.current) {
      hasInitializedFilters.current = true;
      return;
    }

    const timeout = setTimeout(() => {
      setPage(1);
      loadPatients({ name, cpf: cpfFilter }, 1);
    }, 300);

    return () => clearTimeout(timeout);
  }, [name, cpfFilter]);

  useEffect(() => {
    if (params.get("new") === "1" && !hasOpenedFromQuery.current) {
      hasOpenedFromQuery.current = true;
      handleOpenCreate();
      router.replace("/admin/patients");
    }
  }, [params, doctors.length, router]);

  useEffect(() => {
    const editId = params.get("edit");
    if (!editId || hasOpenedEditFromQuery.current || loading) {
      return;
    }

    const targetPatient = patients.find((patient) => patient.id === editId);
    if (!targetPatient) {
      return;
    }

    hasOpenedEditFromQuery.current = true;
    handleOpenEdit(targetPatient);
  }, [params, patients, loading]);

  return (
    <>
      <div className="flex flex-col border-b-[2px] border-[#dedede] p-2">
        <div className="flex flex-col gap-2 sm:flex-row sm:flex-wrap sm:items-end">
          <AppInput
            type="text"
            label="Nome"
            className="w-full sm:min-w-[220px] sm:flex-1"
            placeholder="Digite o NOME do PACIENTE"
            value={name}
            onChange={(e) => setName(e.target.value)}
          />
          <AppInput
            type="text"
            label="CPF"
            className="w-full sm:min-w-[220px] sm:flex-1"
            placeholder="Digite o CPF"
            value={cpfFilter}
            onChange={(e) => setCpfFilter(e.target.value)}
          />
        </div>
      </div>

      {success && (
        <p className="bg-[#6eef01] px-5 text-center rounded-full color-[white] p-1">{success}</p>
      )}
      {error && <p className="bg-[tomato] px-5 text-center rounded-full color-[white] p-1">{error}</p>}

      {loading && (
        <div className="flex justify-center">
          <AppLoader size={50} className="self-center" />
        </div>
      )}

      {!loading && (
        <div>
          <div className="overflow-x-auto max-h-[55vh] overflow-y-auto rounded-xl border border-[#edd7ce]">
          <table className="min-w-full bg-white">
            <thead>
              <tr>
                <th className="py-2 px-4 border-b border-gray-200 text-left text-sm font-semibold text-gray-600">Nome</th>
                <th className="py-2 px-4 border-b border-gray-200 text-left text-sm font-semibold text-gray-600">CPF</th>
                <th className="py-2 px-4 border-b border-gray-200 text-left text-sm font-semibold text-gray-600">Última consulta</th>
                <th className="py-2 px-4 border-b border-gray-200 text-left text-sm font-semibold text-gray-600">Ações</th>
              </tr>
            </thead>
            <tbody>
              {patients.map((patient) => (
                <tr key={patient.id}>
                  <td className="py-2 px-4 border-b border-gray-200 text-sm">{maskName(patient.name)}</td>
                  <td className="py-2 px-4 border-b border-gray-200 text-sm">{maskCpf(patient.cpf)}</td>
                  <td className="py-2 px-4 border-b border-gray-200 text-sm">
                    {patient.lastAppointment
                      ? new Date(patient.lastAppointment).toLocaleDateString("pt-BR")
                      : "-"}
                  </td>
                  <td className="py-2 px-4 border-b border-gray-200 text-sm">
                    <Link href={`/admin/patients/edit/${patient.id}`}>
                      <i
                        className="ion-edit text-[20px] text-[#1aab67] mx-[10px] cursor-pointer"
                      />
                    </Link>
                    <i
                      className="ion-ios-trash text-[20px] text-[#ed1b2d] mx-[10px] cursor-pointer"
                      onClick={() => handleOpenRemove(patient)}
                    />
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
                <AppButton
                  title="Anterior"
                  className="mr-[10px]"
                  icon="arrow-left-a"
                  form="round"
                  onClick={() => handlePage(page - 1)}
                  disabled={Boolean(pagination?.firstPage ?? true)}
                />
                <AppButton
                  title="Próximo"
                  className="ml-[10px]"
                  icon="arrow-right-a"
                  form="round"
                  onClick={() => handlePage(page + 1)}
                  disabled={Boolean(pagination?.lastPage ?? true)}
                />
              </div>
            </div>
          )}

          {!patients.length && <p className="text-center py-6">Nenhum paciente encontrado.</p>}
        </div>
      )}

      {modalMode && (
        <AppModal
          title={modalMode === "create" ? "Criar paciente" : "Editar paciente"}
          onClose={handleCloseModal}
        >
          <div className="mx-auto w-[680px] max-w-full rounded-2xl border border-[#f0ddd5] bg-white/85 p-4 md:p-5">
            <div className="mb-4 rounded-xl border border-[#f2dfd7] bg-[#fff9f5] px-4 py-3">
              <p className="text-[18px] font-bold text-[#5c1711]">Dados do paciente</p>
              <p className="text-[13px] text-[#8b7b75]">Preencha os campos para concluir o cadastro.</p>
              <p className="text-[12px] text-[#8b7b75]"><span className="text-[red]">*</span> indica campo obrigatório.</p>
            </div>

            <AppSelect
              label={requiredLabel("Médico")}
              value={patientForm.doctorId}
              onChange={(e) => setPatientForm({ ...patientForm, doctorId: e.target.value })}
            >
              <option value="">Selecione</option>
              {doctors.map((doctor) => (
                <option key={doctor.id} value={doctor.id}>
                  {doctor.name}
                </option>
              ))}
            </AppSelect>

            <AppInput
              type="text"
              label={requiredLabel("Nome")}
              value={patientForm.name}
              onChange={(e) => setPatientForm({ ...patientForm, name: e.target.value })}
            />

            <AppInput
              type="text"
              label={requiredLabel("CPF")}
              value={patientForm.cpf}
              onChange={(e) => setPatientForm({ ...patientForm, cpf: formatCpf(e.target.value) })}
              placeholder="000.000.000-00"
            />

            <AppInput
              type="date"
              label="Última consulta"
              value={patientForm.lastAppointment}
              onChange={(e) =>
                setPatientForm({ ...patientForm, lastAppointment: e.target.value })
              }
            />

            {modalMode === "create" && createError && (
              <p className="mt-4 rounded-full bg-[tomato] px-4 py-1 text-center text-[white]">{createError}</p>
            )}

            <div className="mt-4 flex justify-end gap-3 border-t border-[#f1ddd5] pt-4">
              <AppButton title="Cancelar" icon="close" color="tomato" form="round" onClick={handleCloseModal} />
              <AppButton title="Salvar" icon="checkmark" form="round" color="#428f01" onClick={handleSavePatient} />
            </div>
          </div>
        </AppModal>
      )}

      {patientRemove && (
        <AppModal title="Remover paciente" onClose={() => setPatientRemove(null)}>
          <p>Deseja realmente remover o paciente {patientRemove.name}?</p>
          <div className="flex justify-between p-[20px]">
            <AppButton title="Sim" icon="checkmark" form="round" color="#428f01" onClick={handleConfirmRemove} />
            <AppButton title="Cancelar" icon="close" color="tomato" form="round" onClick={() => setPatientRemove(null)} />
          </div>
        </AppModal>
      )}
    </>
  );
}
