"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";

export default function PatientCreateForm() {
  const router = useRouter();

  useEffect(() => {
    router.replace("/admin/patients?new=1");
  }, [router]);

  return <p className="text-[14px] text-[#8b7b75]">Redirecionando para o cadastro...</p>;
}
