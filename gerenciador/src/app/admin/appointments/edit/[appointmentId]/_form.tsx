"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";

type Props = {
  appointmentId: string;
};

export default function AppointmentEditForm({ appointmentId }: Props) {
  const router = useRouter();

  useEffect(() => {
    router.replace(`/admin/appointments?edit=${encodeURIComponent(appointmentId)}`);
  }, [appointmentId, router]);

  return <p className="text-[14px] text-[#8b7b75]">Redirecionando para a edição...</p>;
}
