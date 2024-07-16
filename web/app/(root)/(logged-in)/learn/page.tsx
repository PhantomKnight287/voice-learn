import { CalSans } from "@/fonts";
import { makeRequest } from "@/lib/req";
import { cn } from "@/lib/utils";
import { REDIRECTS } from "@/redirects.mjs";
import { getToken } from "@/utils/token";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { LearnPayload } from "./types";
import Image from "next/image";

export const dynamic = "force-dynamic";

export default async function Learn() {
  const token = getToken(cookies());
  if (!token) return redirect(REDIRECTS.LOGGED_OUT);
  const req = await makeRequest<undefined, LearnPayload>("/onboarding", {
    method: "GET",
    body: undefined,
    cache: "no-cache",
    headers: {
      Authorization: token,
    },
  });
  if (req.failed) return redirect("/errors/500");
  return (
    <div className="container flex flex-col">
      <h1 className={cn("text-2xl font-bold flex flex-row flex-nowrap gap-4 items-center tracking-wide", CalSans.className)}>
        <Image
          src={req.data.language.flagUrl}
          width={40}
          height={40}
          alt={req.data.language.name}
        />
        {req.data.language.name}
      </h1>
    </div>
  );
}
