"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { AppButton, AppInput, AppLoader, AppModal, AppSelect } from "@/themes/components";
import AppointmentServices from "@/services/appointment";
import { useRouter, useSearchParams } from "next/navigation";
import Link from "next/link";

type Appointment = {
  id: string;
  doctorId: string;
  patientId: string;
  appointmentDate: string;
  age?: number;
  sexualOrientation?: string;
  maritalStatus?: string;
  concordantPartner?: boolean;
  occupation?: string;
  comorbidities?: string;
  previousDiseases?: string;
  allergy?: string;
  surgeries?: string;
  medicationUse?: string;
  hivDiagnosisDate?: string;
  cardiovascularRisk?: string;
  neoplasmScreening?: string;
  coinfectionScreening?: string;
  immunizations?: string;
  notes?: string;
  zipCode?: string;
  street?: string;
  streetNumber?: string;
  neighborhood?: string;
  city?: string;
  addressComplement?: string;
  currentArt?: string;
  adherence?: string;
  lastViralLoad?: string;
  cd4Nadir?: string;
  virologicalStatus?: string;
  currentRegimen?: string;
  regimenStartDate?: string;
  previousRegimens?: string;
  changeReason?: string;
};

const maritalStatusOptions = [
  { value: "SINGLE", label: "Solteiro(a)" },
  { value: "MARRIED", label: "Casado(a)" },
  { value: "DIVORCED", label: "Divorciado(a)" },
  { value: "WIDOWED", label: "Viúvo(a)" },
  { value: "STABLE_UNION", label: "União estável" },
  { value: "OTHER", label: "Outro" },
];

const immunizationsOptions = [
  { value: "COMPLETE", label: "Completa" },
  { value: "INCOMPLETE", label: "Incompleta" },
  { value: "NOT_INFORMED", label: "Não informado" },
];

const adherenceOptions = [
  { value: "HIGH", label: "Alta" },
  { value: "MEDIUM", label: "Média" },
  { value: "LOW", label: "Baixa" },
  { value: "NOT_INFORMED", label: "Não informado" },
];

const booleanOptions = [
  { value: "true", label: "Sim" },
  { value: "false", label: "Não" },
];

const toDateTimeInputValue = (value?: string): string => {
  if (!value) {
    return "";
  }

  const date = new Date(value);
  const offset = date.getTimezoneOffset();
  const normalized = new Date(date.getTime() - offset * 60 * 1000);
  return normalized.toISOString().slice(0, 16);
};

const requiredLabel = (label: string) => (
  <>
    {label} <span className="text-[red]">*</span>
  </>
);

export default function AppointmentsList() {
  const router = useRouter();
  const params = useSearchParams();
  const hasOpenedFromQuery = useRef(false);
  const hasOpenedEditFromQuery = useRef(false);
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [doctors, setDoctors] = useState<Array<{ id: string; name: string }>>([]);
  const [patients, setPatients] = useState<Array<{ id: string; name: string }>>([]);
  const hasInitializedFilters = useRef(false);
  const [doctorFilter, setDoctorFilter] = useState("");
  const [patientFilter, setPatientFilter] = useState("");
  const [page, setPage] = useState(1);
  const [pagination, setPagination] = useState<any>(null);
  const [jumpPage, setJumpPage] = useState("1");
  const [modalMode, setModalMode] = useState<"create" | "edit" | null>(null);
  const [appointmentForm, setAppointmentForm] = useState({
    id: "",
    doctorId: "",
    patientId: "",
    appointmentDate: "",
    age: "",
    sexualOrientation: "",
    maritalStatus: "",
    concordantPartner: "",
    occupation: "",
    comorbidities: "",
    previousDiseases: "",
    allergy: "",
    surgeries: "",
    medicationUse: "",
    hivDiagnosisDate: "",
    cardiovascularRisk: "",
    neoplasmScreening: "",
    coinfectionScreening: "",
    immunizations: "",
    notes: "",
    zipCode: "",
    street: "",
    streetNumber: "",
    neighborhood: "",
    city: "",
    addressComplement: "",
    currentArt: "",
    adherence: "",
    lastViralLoad: "",
    cd4Nadir: "",
    virologicalStatus: "",
    currentRegimen: "",
    regimenStartDate: "",
    previousRegimens: "",
    changeReason: "",
  });
  const [appointmentRemove, setAppointmentRemove] = useState<Appointment | null>(null);
  const [createError, setCreateError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const doctorById = useMemo(() => {
    const map = new Map<string, string>();
    doctors.forEach((doctor) => map.set(doctor.id, doctor.name));
    return map;
  }, [doctors]);

  const patientById = useMemo(() => {
    const map = new Map<string, string>();
    patients.forEach((patient) => map.set(patient.id, patient.name));
    return map;
  }, [patients]);

  const normalizeZipCode = (value: string): string => value.replace(/\D/g, "").slice(0, 8);

  const withOptionalString = (value: string): string | undefined => {
    const trimmed = value.trim();
    return trimmed ? trimmed : undefined;
  };

  const withOptionalDate = (value: string): string | undefined => {
    return value ? new Date(value).toISOString() : undefined;
  };

  const loadAppointments = async (
    filters: { doctorName?: string; patientName?: string } = {},
    pageNumber = 1,
  ) => {
    setLoading(true);
    setError(null);

    const response = await AppointmentServices.getAll(filters, pageNumber);
    if (!response.success) {
      setAppointments([]);
      setPagination(null);
      setError(response.error ?? "Erro ao carregar consultas");
      setLoading(false);
      return;
    }

    setAppointments(response.appointments);
    setPagination(response.pagination ?? null);
    setLoading(false);
  };

  const loadReferences = async () => {
    const [doctorsResponse, patientsResponse] = await Promise.all([
      AppointmentServices.getDoctors(),
      AppointmentServices.getPatients(),
    ]);

    if (!doctorsResponse.success) {
      setError(doctorsResponse.error ?? "Erro ao carregar médicos");
    } else {
      setDoctors(doctorsResponse.doctors);
    }

    if (!patientsResponse.success) {
      setError(patientsResponse.error ?? "Erro ao carregar pacientes");
    } else {
      setPatients(patientsResponse.patients);
    }
  };

  const handleOpenCreate = () => {
    setSuccess(null);
    setError(null);
    setCreateError(null);
    setAppointmentForm({
      id: "",
      doctorId: "",
      patientId: "",
      appointmentDate: "",
      age: "",
      sexualOrientation: "",
      maritalStatus: "",
      concordantPartner: "",
      occupation: "",
      comorbidities: "",
      previousDiseases: "",
      allergy: "",
      surgeries: "",
      medicationUse: "",
      hivDiagnosisDate: "",
      cardiovascularRisk: "",
      neoplasmScreening: "",
      coinfectionScreening: "",
      immunizations: "",
      notes: "",
      zipCode: "",
      street: "",
      streetNumber: "",
      neighborhood: "",
      city: "",
      addressComplement: "",
      currentArt: "",
      adherence: "",
      lastViralLoad: "",
      cd4Nadir: "",
      virologicalStatus: "",
      currentRegimen: "",
      regimenStartDate: "",
      previousRegimens: "",
      changeReason: "",
    });
    setModalMode("create");
  };

  const handleOpenEdit = (appointment: Appointment) => {
    setSuccess(null);
    setError(null);
    setCreateError(null);
    setAppointmentForm({
      id: appointment.id,
      doctorId: appointment.doctorId,
      patientId: appointment.patientId,
      appointmentDate: toDateTimeInputValue(appointment.appointmentDate),
      age: appointment.age !== undefined ? String(appointment.age) : "",
      sexualOrientation: appointment.sexualOrientation ?? "",
      maritalStatus: appointment.maritalStatus ?? "",
      concordantPartner:
        appointment.concordantPartner === undefined ? "" : String(appointment.concordantPartner),
      occupation: appointment.occupation ?? "",
      comorbidities: appointment.comorbidities ?? "",
      previousDiseases: appointment.previousDiseases ?? "",
      allergy: appointment.allergy ?? "",
      surgeries: appointment.surgeries ?? "",
      medicationUse: appointment.medicationUse ?? "",
      hivDiagnosisDate: toDateTimeInputValue(appointment.hivDiagnosisDate),
      cardiovascularRisk: appointment.cardiovascularRisk ?? "",
      neoplasmScreening: appointment.neoplasmScreening ?? "",
      coinfectionScreening: appointment.coinfectionScreening ?? "",
      immunizations: appointment.immunizations ?? "",
      notes: appointment.notes ?? "",
      zipCode: appointment.zipCode ?? "",
      street: appointment.street ?? "",
      streetNumber: appointment.streetNumber ?? "",
      neighborhood: appointment.neighborhood ?? "",
      city: appointment.city ?? "",
      addressComplement: appointment.addressComplement ?? "",
      currentArt: appointment.currentArt ?? "",
      adherence: appointment.adherence ?? "",
      lastViralLoad: toDateTimeInputValue(appointment.lastViralLoad),
      cd4Nadir: appointment.cd4Nadir ?? "",
      virologicalStatus: appointment.virologicalStatus ?? "",
      currentRegimen: appointment.currentRegimen ?? "",
      regimenStartDate: toDateTimeInputValue(appointment.regimenStartDate),
      previousRegimens: appointment.previousRegimens ?? "",
      changeReason: appointment.changeReason ?? "",
    });
    setModalMode("edit");
  };

  const handleCloseModal = () => {
    const shouldCleanNewQuery = modalMode === "create" && params.get("new") === "1";
    setModalMode(null);
    setCreateError(null);

    if (shouldCleanNewQuery) {
      router.replace("/admin/appointments");
    }
  };

  const handleSave = async () => {
    setError(null);
    setCreateError(null);
    setSuccess(null);

    if (!appointmentForm.doctorId || !appointmentForm.patientId) {
      if (modalMode === "create") {
        setCreateError("Selecione médico e paciente");
      } else {
        setError("Selecione médico e paciente");
      }
      return;
    }

    if (!appointmentForm.appointmentDate) {
      if (modalMode === "create") {
        setCreateError("Data da consulta é obrigatória");
      } else {
        setError("Data da consulta é obrigatória");
      }
      return;
    }

    if (appointmentForm.zipCode && normalizeZipCode(appointmentForm.zipCode).length !== 8) {
      if (modalMode === "create") {
        setCreateError("CEP deve conter 8 dígitos");
      } else {
        setError("CEP deve conter 8 dígitos");
      }
      return;
    }

    setLoading(true);

    const payload = {
      doctorId: appointmentForm.doctorId,
      patientId: appointmentForm.patientId,
      appointmentDate: new Date(appointmentForm.appointmentDate).toISOString(),
      age: appointmentForm.age ? Number(appointmentForm.age) : undefined,
      sexualOrientation: withOptionalString(appointmentForm.sexualOrientation),
      maritalStatus: appointmentForm.maritalStatus || undefined,
      concordantPartner:
        appointmentForm.concordantPartner === ""
          ? undefined
          : appointmentForm.concordantPartner === "true",
      occupation: withOptionalString(appointmentForm.occupation),
      comorbidities: withOptionalString(appointmentForm.comorbidities),
      previousDiseases: withOptionalString(appointmentForm.previousDiseases),
      allergy: withOptionalString(appointmentForm.allergy),
      surgeries: withOptionalString(appointmentForm.surgeries),
      medicationUse: withOptionalString(appointmentForm.medicationUse),
      hivDiagnosisDate: withOptionalDate(appointmentForm.hivDiagnosisDate),
      cardiovascularRisk: withOptionalString(appointmentForm.cardiovascularRisk),
      neoplasmScreening: withOptionalString(appointmentForm.neoplasmScreening),
      coinfectionScreening: withOptionalString(appointmentForm.coinfectionScreening),
      immunizations: appointmentForm.immunizations || undefined,
      notes: withOptionalString(appointmentForm.notes),
      zipCode: appointmentForm.zipCode ? normalizeZipCode(appointmentForm.zipCode) : undefined,
      street: withOptionalString(appointmentForm.street),
      streetNumber: withOptionalString(appointmentForm.streetNumber),
      neighborhood: withOptionalString(appointmentForm.neighborhood),
      city: withOptionalString(appointmentForm.city),
      addressComplement: withOptionalString(appointmentForm.addressComplement),
      currentArt: withOptionalString(appointmentForm.currentArt),
      adherence: appointmentForm.adherence || undefined,
      lastViralLoad: withOptionalDate(appointmentForm.lastViralLoad),
      cd4Nadir: withOptionalString(appointmentForm.cd4Nadir),
      virologicalStatus: withOptionalString(appointmentForm.virologicalStatus),
      currentRegimen: withOptionalString(appointmentForm.currentRegimen),
      regimenStartDate: withOptionalDate(appointmentForm.regimenStartDate),
      previousRegimens: withOptionalString(appointmentForm.previousRegimens),
      changeReason: withOptionalString(appointmentForm.changeReason),
    };

    const response =
      modalMode === "create"
        ? await AppointmentServices.create(payload)
        : await AppointmentServices.update(appointmentForm.id, payload);

    if (!response.success) {
      setLoading(false);
      if (modalMode === "create") {
        setCreateError(response.error ?? "Erro ao salvar consulta");
      } else {
        setError(response.error ?? "Erro ao salvar consulta");
      }
      return;
    }

    setModalMode(null);
    setSuccess(modalMode === "create" ? "Consulta criada com sucesso!" : "Consulta atualizada com sucesso!");
    setPage(1);
    setJumpPage("1");
    await loadAppointments({ doctorName: doctorFilter, patientName: patientFilter }, 1);
  };

  const handleConfirmRemove = async () => {
    if (!appointmentRemove) {
      return;
    }

    setLoading(true);
    setError(null);
    setSuccess(null);

    const response = await AppointmentServices.delete(appointmentRemove.id);
    if (!response.success) {
      setLoading(false);
      setError(response.error ?? "Erro ao remover consulta");
      return;
    }

    setAppointmentRemove(null);
    setSuccess("Consulta removida com sucesso!");
    await loadAppointments({ doctorName: doctorFilter, patientName: patientFilter }, page);
  };

  const handlePage = async (newPage: number) => {
    setPage(newPage);
    setJumpPage(String(newPage));
    await loadAppointments({ doctorName: doctorFilter, patientName: patientFilter }, newPage);
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
    loadAppointments({ doctorName: doctorFilter, patientName: patientFilter }, page);
    loadReferences();
  }, []);

  useEffect(() => {
    if (!hasInitializedFilters.current) {
      hasInitializedFilters.current = true;
      return;
    }

    setPage(1);
    setJumpPage("1");
    loadAppointments({ doctorName: doctorFilter, patientName: patientFilter }, 1);
  }, [doctorFilter, patientFilter]);

  useEffect(() => {
    if (params.get("new") === "1" && !hasOpenedFromQuery.current) {
      hasOpenedFromQuery.current = true;
      handleOpenCreate();
      router.replace("/admin/appointments");
    }
  }, [params, doctors.length, patients.length, router]);

  useEffect(() => {
    const editId = params.get("edit");
    if (!editId || hasOpenedEditFromQuery.current || loading) {
      return;
    }

    const targetAppointment = appointments.find((appointment) => appointment.id === editId);
    if (!targetAppointment) {
      return;
    }

    hasOpenedEditFromQuery.current = true;
    handleOpenEdit(targetAppointment);
  }, [params, appointments, loading]);

  return (
    <>
      <div className="flex flex-col border-b-[2px] border-[#dedede] p-2">
        <div className="flex flex-col gap-2 sm:flex-row sm:flex-wrap sm:items-end">
          <AppInput
            type="text"
            label="Doutor"
            className="w-full sm:min-w-[220px] sm:flex-1"
            value={doctorFilter}
            onChange={(e) => setDoctorFilter(e.target.value)}
            placeholder="Digite o NOME do DOUTOR"
          />

          <AppInput
            type="text"
            label="Paciente"
            className="w-full sm:min-w-[220px] sm:flex-1"
            value={patientFilter}
            onChange={(e) => setPatientFilter(e.target.value)}
            placeholder="Digite o NOME do PACIENTE"
          />
        </div>
      </div>

      {success && <p className="bg-[#6eef01] px-5 text-center rounded-full color-[white] p-1">{success}</p>}
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
                <th className="py-2 px-4 border-b border-gray-200 text-left text-sm font-semibold text-gray-600">Médico</th>
                <th className="py-2 px-4 border-b border-gray-200 text-left text-sm font-semibold text-gray-600">Paciente</th>
                <th className="py-2 px-4 border-b border-gray-200 text-left text-sm font-semibold text-gray-600">Data</th>
                <th className="py-2 px-4 border-b border-gray-200 text-left text-sm font-semibold text-gray-600">Observações</th>
                <th className="py-2 px-4 border-b border-gray-200 text-left text-sm font-semibold text-gray-600">Ações</th>
              </tr>
            </thead>
            <tbody>
              {appointments.map((appointment) => (
                <tr key={appointment.id}>
                  <td className="py-2 px-4 border-b border-gray-200 text-sm">{doctorById.get(appointment.doctorId) ?? "-"}</td>
                  <td className="py-2 px-4 border-b border-gray-200 text-sm">{patientById.get(appointment.patientId) ?? "-"}</td>
                  <td className="py-2 px-4 border-b border-gray-200 text-sm">{new Date(appointment.appointmentDate).toLocaleString("pt-BR")}</td>
                  <td className="py-2 px-4 border-b border-gray-200 text-sm">{appointment.notes?.trim() || "-"}</td>
                  <td className="py-2 px-4 border-b border-gray-200 text-sm">
                    <Link href={`/admin/appointments/edit/${appointment.id}`}>
                      <i className="ion-edit text-[20px] text-[#1aab67] mx-[10px] cursor-pointer" />
                    </Link>
                    <i className="ion-ios-trash text-[20px] text-[#ed1b2d] mx-[10px] cursor-pointer" onClick={() => setAppointmentRemove(appointment)} />
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
                <AppInput type="number" label="" className="w-[90px] shrink-0" value={jumpPage} onChange={(e) => setJumpPage(e.target.value)} />
                <AppButton title="Ir" icon="arrow-right-a" form="round" onClick={handleJumpPage} />
              </div>
              <div className="flex flex-wrap items-center gap-2 lg:ml-auto">
                <p className="text-sm text-gray-600 mr-2">Página {pagination?.page ?? 1} de {pagination?.totalPages ?? 1}</p>
                <AppButton title="Anterior" className="mr-[10px]" icon="arrow-left-a" form="round" onClick={() => handlePage(page - 1)} disabled={Boolean(pagination?.firstPage ?? true)} />
                <AppButton title="Próximo" className="ml-[10px]" icon="arrow-right-a" form="round" onClick={() => handlePage(page + 1)} disabled={Boolean(pagination?.lastPage ?? true)} />
              </div>
            </div>
          )}

          {!appointments.length && <p className="text-center py-6">Nenhuma consulta encontrada.</p>}
        </div>
      )}

      {modalMode && (
        <AppModal title={modalMode === "create" ? "Criar consulta" : "Editar consulta"} onClose={handleCloseModal}>
          <div className="mx-auto w-[900px] max-w-full rounded-2xl border border-[#f0ddd5] bg-white/85 p-4 md:p-5">
            <div className="mb-4 rounded-xl border border-[#f2dfd7] bg-[#fff9f5] px-4 py-3">
              <p className="text-[18px] font-bold text-[#5c1711]">Dados da consulta</p>
              <p className="text-[13px] text-[#8b7b75]">Preencha os campos obrigatórios e complete os dados clínicos conforme necessário.</p>
              <p className="text-[12px] text-[#8b7b75]"><span className="text-[red]">*</span> indica campo obrigatório.</p>
            </div>

            <AppInput
              type="text"
              label={requiredLabel("Médico")}
              value={appointmentForm.doctorId}
              onChange={(e) => setAppointmentForm({ ...appointmentForm, doctorId: e.target.value })}
              placeholder="Digite o ID do DOUTOR"
            />

            <AppInput
              type="text"
              label={requiredLabel("Paciente")}
              value={appointmentForm.patientId}
              onChange={(e) => setAppointmentForm({ ...appointmentForm, patientId: e.target.value })}
              placeholder="Digite o ID do PACIENTE"
            />

            <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
              <AppInput type="datetime-local" label={requiredLabel("Data da consulta")} value={appointmentForm.appointmentDate} onChange={(e) => setAppointmentForm({ ...appointmentForm, appointmentDate: e.target.value })} />
              <AppInput type="number" label="Idade" value={appointmentForm.age} onChange={(e) => setAppointmentForm({ ...appointmentForm, age: e.target.value })} />
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
              <AppInput type="text" label="Orientação sexual" value={appointmentForm.sexualOrientation} onChange={(e) => setAppointmentForm({ ...appointmentForm, sexualOrientation: e.target.value })} />
              <AppSelect label="Estado civil" value={appointmentForm.maritalStatus} onChange={(e) => setAppointmentForm({ ...appointmentForm, maritalStatus: e.target.value })}>
                <option value="">Selecione</option>
                {maritalStatusOptions.map((option) => (
                  <option key={option.value} value={option.value}>{option.label}</option>
                ))}
              </AppSelect>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
              <AppSelect label="Parceiro concordante" value={appointmentForm.concordantPartner} onChange={(e) => setAppointmentForm({ ...appointmentForm, concordantPartner: e.target.value })}>
                <option value="">Selecione</option>
                {booleanOptions.map((option) => (
                  <option key={option.value} value={option.value}>{option.label}</option>
                ))}
              </AppSelect>
              <AppInput type="text" label="Ocupação" value={appointmentForm.occupation} onChange={(e) => setAppointmentForm({ ...appointmentForm, occupation: e.target.value })} />
            </div>

            <AppInput type="text" label="Comorbidades" value={appointmentForm.comorbidities} onChange={(e) => setAppointmentForm({ ...appointmentForm, comorbidities: e.target.value })} />
            <AppInput type="text" label="Doenças prévias" value={appointmentForm.previousDiseases} onChange={(e) => setAppointmentForm({ ...appointmentForm, previousDiseases: e.target.value })} />
            <AppInput type="text" label="Alergia" value={appointmentForm.allergy} onChange={(e) => setAppointmentForm({ ...appointmentForm, allergy: e.target.value })} />
            <AppInput type="text" label="Cirurgias" value={appointmentForm.surgeries} onChange={(e) => setAppointmentForm({ ...appointmentForm, surgeries: e.target.value })} />
            <AppInput type="text" label="Uso de medicação" value={appointmentForm.medicationUse} onChange={(e) => setAppointmentForm({ ...appointmentForm, medicationUse: e.target.value })} />

            <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
              <AppInput type="datetime-local" label="Diagnóstico de HIV" value={appointmentForm.hivDiagnosisDate} onChange={(e) => setAppointmentForm({ ...appointmentForm, hivDiagnosisDate: e.target.value })} />
              <AppInput type="datetime-local" label="Última carga viral" value={appointmentForm.lastViralLoad} onChange={(e) => setAppointmentForm({ ...appointmentForm, lastViralLoad: e.target.value })} />
            </div>

            <AppInput type="text" label="Risco cardiovascular" value={appointmentForm.cardiovascularRisk} onChange={(e) => setAppointmentForm({ ...appointmentForm, cardiovascularRisk: e.target.value })} />
            <AppInput type="text" label="Rastreamento de neoplasia" value={appointmentForm.neoplasmScreening} onChange={(e) => setAppointmentForm({ ...appointmentForm, neoplasmScreening: e.target.value })} />
            <AppInput type="text" label="Rastreamento de coinfecção" value={appointmentForm.coinfectionScreening} onChange={(e) => setAppointmentForm({ ...appointmentForm, coinfectionScreening: e.target.value })} />

            <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
              <AppSelect label="Imunizações" value={appointmentForm.immunizations} onChange={(e) => setAppointmentForm({ ...appointmentForm, immunizations: e.target.value })}>
                <option value="">Selecione</option>
                {immunizationsOptions.map((option) => (
                  <option key={option.value} value={option.value}>{option.label}</option>
                ))}
              </AppSelect>
              <AppSelect label="Adesão" value={appointmentForm.adherence} onChange={(e) => setAppointmentForm({ ...appointmentForm, adherence: e.target.value })}>
                <option value="">Selecione</option>
                {adherenceOptions.map((option) => (
                  <option key={option.value} value={option.value}>{option.label}</option>
                ))}
              </AppSelect>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
              <AppInput type="text" label="ART atual" value={appointmentForm.currentArt} onChange={(e) => setAppointmentForm({ ...appointmentForm, currentArt: e.target.value })} />
              <AppInput type="text" label="CD4 nadir" value={appointmentForm.cd4Nadir} onChange={(e) => setAppointmentForm({ ...appointmentForm, cd4Nadir: e.target.value })} />
            </div>

            <AppInput type="text" label="Status virológico" value={appointmentForm.virologicalStatus} onChange={(e) => setAppointmentForm({ ...appointmentForm, virologicalStatus: e.target.value })} />
            <AppInput type="text" label="Esquema atual" value={appointmentForm.currentRegimen} onChange={(e) => setAppointmentForm({ ...appointmentForm, currentRegimen: e.target.value })} />

            <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
              <AppInput type="datetime-local" label="Início do esquema" value={appointmentForm.regimenStartDate} onChange={(e) => setAppointmentForm({ ...appointmentForm, regimenStartDate: e.target.value })} />
              <AppInput type="text" label="Esquemas anteriores" value={appointmentForm.previousRegimens} onChange={(e) => setAppointmentForm({ ...appointmentForm, previousRegimens: e.target.value })} />
            </div>

            <AppInput type="text" label="Motivo da mudança" value={appointmentForm.changeReason} onChange={(e) => setAppointmentForm({ ...appointmentForm, changeReason: e.target.value })} />

            <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
              <AppInput type="text" label="CEP" value={appointmentForm.zipCode} onChange={(e) => setAppointmentForm({ ...appointmentForm, zipCode: normalizeZipCode(e.target.value) })} />
              <AppInput type="text" label="Rua" value={appointmentForm.street} onChange={(e) => setAppointmentForm({ ...appointmentForm, street: e.target.value })} />
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
              <AppInput type="text" label="Número" value={appointmentForm.streetNumber} onChange={(e) => setAppointmentForm({ ...appointmentForm, streetNumber: e.target.value })} />
              <AppInput type="text" label="Bairro" value={appointmentForm.neighborhood} onChange={(e) => setAppointmentForm({ ...appointmentForm, neighborhood: e.target.value })} />
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
              <AppInput type="text" label="Cidade" value={appointmentForm.city} onChange={(e) => setAppointmentForm({ ...appointmentForm, city: e.target.value })} />
              <AppInput type="text" label="Complemento" value={appointmentForm.addressComplement} onChange={(e) => setAppointmentForm({ ...appointmentForm, addressComplement: e.target.value })} />
            </div>

            <AppInput type="text" label="Observações" value={appointmentForm.notes} onChange={(e) => setAppointmentForm({ ...appointmentForm, notes: e.target.value })} />

            {modalMode === "create" && createError && (
              <p className="mt-4 rounded-full bg-[tomato] px-4 py-1 text-center text-[white]">{createError}</p>
            )}

            <div className="mt-4 flex justify-end gap-3 border-t border-[#f1ddd5] pt-4">
              <AppButton title="Cancelar" icon="close" color="tomato" form="round" onClick={handleCloseModal} />
              <AppButton title="Salvar" icon="checkmark" form="round" color="#428f01" onClick={handleSave} />
            </div>
          </div>
        </AppModal>
      )}

      {appointmentRemove && (
        <AppModal title="Remover consulta" onClose={() => setAppointmentRemove(null)}>
          <p>Deseja realmente remover esta consulta?</p>
          <div className="flex justify-between p-[20px]">
            <AppButton title="Sim" icon="checkmark" form="round" color="#428f01" onClick={handleConfirmRemove} />
            <AppButton title="Cancelar" icon="close" color="tomato" form="round" onClick={() => setAppointmentRemove(null)} />
          </div>
        </AppModal>
      )}
    </>
  );
}
