"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";

type Props = {
  locationId: string;
};

export default function LocationEditForm({ locationId }: Props) {
  const router = useRouter();

  useEffect(() => {
    router.replace(`/admin/locations?edit=${encodeURIComponent(locationId)}`);
  }, [locationId, router]);

  return <p className="text-[14px] text-[#8b7b75]">Redirecionando para a edição...</p>;
}
