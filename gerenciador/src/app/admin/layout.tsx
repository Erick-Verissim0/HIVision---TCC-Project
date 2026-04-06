import { Metadata } from "next";
import React from "react";
import { AppMenu } from "@/themes/components";

// ===============================================
export const metadata: Metadata = {
  title: 'Web Manager',
};
// ===============================================

export default function AdminLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <div className="bg-(--background-secondary) flex h-screen">
        <AppMenu />


        <div className="flex flex-1 ml-[30px]">
            {children}
        </div>
    </div>
  );
}
