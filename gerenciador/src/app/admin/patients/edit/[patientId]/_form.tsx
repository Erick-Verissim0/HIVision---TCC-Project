"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";

type Props = {
  patientId: string;
};

export default function PatientEditForm({ patientId }: Props) {
  const router = useRouter();

  useEffect(() => {
    router.replace(`/admin/patients?edit=${encodeURIComponent(patientId)}`);
  }, [patientId, router]);

  return <p className="text-[14px] text-[#8b7b75]">Redirecionando para a edição...</p>;
}
