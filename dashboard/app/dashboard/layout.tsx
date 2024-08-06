import { Button } from "@/components/ui/button";
import { API_URL, COOKIE_NAME } from "@/constants";
import { cookies } from "next/headers";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import SidebarNav from "./_components/sidebar";
import { ArrowLeft, Bell } from "lucide-react";
import NavSheet from "./_components/sheet";
import { ReactNode } from "react";
import ClientLayout from "./layout.client";

export default async function ProjectLayout({
  params,
  children,
}: {
  params: { id: string };
  children: ReactNode;
}) {
  const cookiesStore = cookies();
  const token = cookiesStore.get(COOKIE_NAME);
  if (!token?.value) return redirect("/login");

  return (
    <>
      {/* <Header hideContent /> */}
      <div className="grid min-h-screen w-full md:grid-cols-[220px_1fr] lg:grid-cols-[280px_1fr]">
        <div className="hidden border-r bg-muted/40 md:block">
          <div className="flex h-full max-h-screen flex-col gap-2">
            <div className="flex h-14 items-center border-b px-4 lg:h-[60px] lg:px-6 gap-2">
              <Link href="#">
                <ArrowLeft />
              </Link>
              <Link
                href={`/dashboard`}
                className="flex items-center gap-2 font-semibold"
              >
                <span className="">Voice Learn</span>
              </Link>
            </div>
            <SidebarNav />
          </div>
        </div>
        <div className="flex flex-col">
          <NavSheet name={"Voice Learn"} />
          {children}
        </div>
      </div>
    </>
  );
}
