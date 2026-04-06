"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { AppButton, AppInput, AppLoader, AppModal, AppSelect } from "@/themes/components";
import LocationServices from "@/services/location";
import { useRouter, useSearchParams } from "next/navigation";
import Link from "next/link";

type Location = {
  id: string;
  doctorId: string;
  zipCode: string;
  street: string;
  streetNumber: string;
  neighborhood?: string;
  city?: string;
  addressComplement?: string;
};

export default function LocationList() {
  const router = useRouter();
  const params = useSearchParams();
  const hasOpenedFromQuery = useRef(false);
  const hasOpenedEditFromQuery = useRef(false);
  const [locations, setLocations] = useState<Location[]>([]);
  const [doctors, setDoctors] = useState<Array<{ id: string; name: string }>>([]);
  const hasInitializedFilters = useRef(false);
  const [cityFilter, setCityFilter] = useState("");
  const [streetFilter, setStreetFilter] = useState("");
  const [page, setPage] = useState(1);
  const [pagination, setPagination] = useState<any>(null);
  const [jumpPage, setJumpPage] = useState("1");
  const [modalMode, setModalMode] = useState<"create" | "edit" | null>(null);
  const [locationForm, setLocationForm] = useState({
    id: "",
    doctorId: "",
    zipCode: "",
    street: "",
    streetNumber: "",
    neighborhood: "",
    city: "",
    addressComplement: "",
  });
  const [locationRemove, setLocationRemove] = useState<Location | null>(null);
  const [createError, setCreateError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

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

  const normalizeZipCode = (value: string): string => value.replace(/\D/g, "").slice(0, 8);

  const doctorById = useMemo(() => {
    const map = new Map<string, string>();
    doctors.forEach((doctor) => map.set(doctor.id, doctor.name));
    return map;
  }, [doctors]);

  const loadLocations = async (
    filters: { city?: string; street?: string } = {},
    pageNumber = 1,
  ) => {
    setLoading(true);
    setError(null);

    const response = await LocationServices.getAll(filters, pageNumber);
    if (!response.success) {
      setLocations([]);
      setPagination(null);
      setError(response.error ?? "Erro ao carregar locais");
      setLoading(false);
      return;
    }

    setLocations(response.locations);
    setPagination(response.pagination ?? null);
    setLoading(false);
  };

  const loadDoctors = async () => {
    const response = await LocationServices.getDoctors();
    if (!response.success) {
      setError(response.error ?? "Erro ao carregar médicos");
      return;
    }

    setDoctors(response.doctors);
  };

  const handleOpenCreate = () => {
    setSuccess(null);
    setError(null);
    setCreateError(null);
    setLocationForm({
      id: "",
      doctorId: doctors[0]?.id ?? "",
      zipCode: "",
      street: "",
      streetNumber: "",
      neighborhood: "",
      city: "",
      addressComplement: "",
    });
    setModalMode("create");
  };

  const handleOpenEdit = (location: Location) => {
    setSuccess(null);
    setError(null);
    setCreateError(null);
    setLocationForm({
      id: location.id,
      doctorId: location.doctorId,
      zipCode: normalizeZipCode(location.zipCode),
      street: location.street,
      streetNumber: location.streetNumber,
      neighborhood: location.neighborhood ?? "",
      city: location.city ?? "",
      addressComplement: location.addressComplement ?? "",
    });
    setModalMode("edit");
  };

  const handleCloseModal = () => {
    const shouldCleanNewQuery = modalMode === "create" && params.get("new") === "1";
    setModalMode(null);
    setCreateError(null);

    if (shouldCleanNewQuery) {
      router.replace("/admin/locations");
    }
  };

  const handleSave = async () => {
    setError(null);
    setCreateError(null);
    setSuccess(null);

    if (!locationForm.doctorId) {
      if (modalMode === "create") {
        setCreateError("Selecione um médico");
      } else {
        setError("Selecione um médico");
      }
      return;
    }

    if (locationForm.zipCode.length !== 8) {
      if (modalMode === "create") {
        setCreateError("CEP deve conter 8 dígitos");
      } else {
        setError("CEP deve conter 8 dígitos");
      }
      return;
    }

    if (!locationForm.street.trim() || !locationForm.streetNumber.trim()) {
      if (modalMode === "create") {
        setCreateError("Rua e número são obrigatórios");
      } else {
        setError("Rua e número são obrigatórios");
      }
      return;
    }

    setLoading(true);

    const payload = {
      doctorId: locationForm.doctorId,
      zipCode: locationForm.zipCode,
      street: locationForm.street.trim(),
      streetNumber: locationForm.streetNumber.trim(),
      neighborhood: locationForm.neighborhood.trim() || undefined,
      city: locationForm.city.trim() || undefined,
      addressComplement: locationForm.addressComplement.trim() || undefined,
    };

    const response =
      modalMode === "create"
        ? await LocationServices.create(payload)
        : await LocationServices.update(locationForm.id, payload);

    if (!response.success) {
      setLoading(false);
      if (modalMode === "create") {
        setCreateError(response.error ?? "Erro ao salvar local");
      } else {
        setError(response.error ?? "Erro ao salvar local");
      }
      return;
    }

    setModalMode(null);
    setSuccess(modalMode === "create" ? "Local criado com sucesso!" : "Local atualizado com sucesso!");
    setPage(1);
    await loadLocations({ city: cityFilter, street: streetFilter }, 1);
  };

  const handleConfirmRemove = async () => {
    if (!locationRemove) {
      return;
    }

    setLoading(true);
    setError(null);
    setSuccess(null);

    const response = await LocationServices.delete(locationRemove.id);
    if (!response.success) {
      setLoading(false);
      setError(response.error ?? "Erro ao remover local");
      return;
    }

    setLocationRemove(null);
    setSuccess("Local removido com sucesso!");
    await loadLocations({ city: cityFilter, street: streetFilter }, page);
  };

  const handlePage = async (newPage: number) => {
    setPage(newPage);
    setJumpPage(String(newPage));
    await loadLocations({ city: cityFilter, street: streetFilter }, newPage);
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
    loadLocations({ city: cityFilter, street: streetFilter }, page);
    loadDoctors();
  }, []);

  useEffect(() => {
    if (!hasInitializedFilters.current) {
      hasInitializedFilters.current = true;
      return;
    }

    const timeout = setTimeout(() => {
      setPage(1);
      loadLocations({ city: cityFilter, street: streetFilter }, 1);
    }, 300);

    return () => clearTimeout(timeout);
  }, [cityFilter, streetFilter]);

  useEffect(() => {
    if (params.get("new") === "1" && !hasOpenedFromQuery.current) {
      hasOpenedFromQuery.current = true;
      handleOpenCreate();
      router.replace("/admin/locations");
    }
  }, [params, doctors.length, router]);

  useEffect(() => {
    const editId = params.get("edit");
    if (!editId || hasOpenedEditFromQuery.current || loading) {
      return;
    }

    const targetLocation = locations.find((location) => location.id === editId);
    if (!targetLocation) {
      return;
    }

    hasOpenedEditFromQuery.current = true;
    handleOpenEdit(targetLocation);
  }, [params, locations, loading]);

  return (
    <>
      <div className="flex flex-col border-b-[2px] border-[#dedede] p-2">
        <div className="flex flex-col gap-2 sm:flex-row sm:flex-wrap sm:items-end">
          <AppInput type="text" label="Cidade" className="w-full sm:min-w-[220px] sm:flex-1" placeholder="Digite o NOME da CIDADE" value={cityFilter} onChange={(e) => setCityFilter(e.target.value)} />
          <AppInput type="text" label="Rua" className="w-full sm:min-w-[220px] sm:flex-1" placeholder="Digite o NOME da RUA" value={streetFilter} onChange={(e) => setStreetFilter(e.target.value)} />
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
                <th className="py-2 px-4 border-b border-gray-200 text-left text-sm font-semibold text-gray-600">CEP</th>
                <th className="py-2 px-4 border-b border-gray-200 text-left text-sm font-semibold text-gray-600">Endereço</th>
                <th className="py-2 px-4 border-b border-gray-200 text-left text-sm font-semibold text-gray-600">Cidade</th>
                <th className="py-2 px-4 border-b border-gray-200 text-left text-sm font-semibold text-gray-600">Ações</th>
              </tr>
            </thead>
            <tbody>
              {locations.map((location) => (
                <tr key={location.id}>
                  <td className="py-2 px-4 border-b border-gray-200 text-sm">{doctorById.get(location.doctorId) ?? "-"}</td>
                  <td className="py-2 px-4 border-b border-gray-200 text-sm">{location.zipCode}</td>
                  <td className="py-2 px-4 border-b border-gray-200 text-sm">{location.street}, {location.streetNumber}</td>
                  <td className="py-2 px-4 border-b border-gray-200 text-sm">{location.city ?? "-"}</td>
                  <td className="py-2 px-4 border-b border-gray-200 text-sm">
                    <Link href={`/admin/locations/edit/${location.id}`}>
                      <i className="ion-edit text-[20px] text-[#1aab67] mx-[10px] cursor-pointer" />
                    </Link>
                    <i className="ion-ios-trash text-[20px] text-[#ed1b2d] mx-[10px] cursor-pointer" onClick={() => setLocationRemove(location)} />
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

          {!locations.length && <p className="text-center py-6">Nenhum local encontrado.</p>}
        </div>
      )}

      {modalMode && (
        <AppModal title={modalMode === "create" ? "Criar local" : "Editar local"} onClose={handleCloseModal}>
          <div className="mx-auto w-[700px] max-w-full rounded-2xl border border-[#f0ddd5] bg-white/85 p-4 md:p-5">
            <div className="mb-4 rounded-xl border border-[#f2dfd7] bg-[#fff9f5] px-4 py-3">
              <p className="text-[18px] font-bold text-[#5c1711]">Dados do local</p>
              <p className="text-[13px] text-[#8b7b75]">Informe o endereço vinculado ao profissional selecionado.</p>
              <p className="text-[12px] text-[#8b7b75]"><span className="text-[red]">*</span> indica campo obrigatório.</p>
            </div>

            <AppSelect label={requiredLabel("Médico")} value={locationForm.doctorId} onChange={(e) => setLocationForm({ ...locationForm, doctorId: e.target.value })}>
              <option value="">Selecione</option>
              {doctors.map((doctor) => (
                <option key={doctor.id} value={doctor.id}>
                  {doctor.name}
                </option>
              ))}
            </AppSelect>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
              <AppInput type="text" label={requiredLabel("CEP")} value={locationForm.zipCode} onChange={(e) => setLocationForm({ ...locationForm, zipCode: normalizeZipCode(e.target.value) })} />
              <AppInput type="text" label={requiredLabel("Número")} value={locationForm.streetNumber} onChange={(e) => setLocationForm({ ...locationForm, streetNumber: e.target.value })} />
            </div>

            <AppInput type="text" label={requiredLabel("Rua")} value={locationForm.street} onChange={(e) => setLocationForm({ ...locationForm, street: e.target.value })} />

            <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
              <AppInput type="text" label="Bairro" value={locationForm.neighborhood} onChange={(e) => setLocationForm({ ...locationForm, neighborhood: e.target.value })} />
              <AppInput type="text" label="Cidade" value={locationForm.city} onChange={(e) => setLocationForm({ ...locationForm, city: e.target.value })} />
            </div>

            <AppInput type="text" label="Complemento" value={locationForm.addressComplement} onChange={(e) => setLocationForm({ ...locationForm, addressComplement: e.target.value })} />

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

      {locationRemove && (
        <AppModal title="Remover local" onClose={() => setLocationRemove(null)}>
          <p>Deseja realmente remover este local?</p>
          <div className="flex justify-between p-[20px]">
            <AppButton title="Sim" icon="checkmark" form="round" color="#428f01" onClick={handleConfirmRemove} />
            <AppButton title="Cancelar" icon="close" color="tomato" form="round" onClick={() => setLocationRemove(null)} />
          </div>
        </AppModal>
      )}
    </>
  );
}
