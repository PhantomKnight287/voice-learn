import { makeRequest } from "@/lib/req";
import { Language } from "./type";
import { redirect } from "next/navigation";
import { REDIRECTS } from "@/redirects.mjs";
import Image from "next/image";

export default async function Languages() {
  const req = await makeRequest<undefined, Language[]>("/languages", {
    method: "GET",
    body: undefined,
    cache: "force-cache",
    next: {
      tags: ["languages", "all"],
    },
  });
  if (req.failed) return redirect(`/error/500`);
  const languages = req.data;

  return (
    <div className="flex flex-col container">
      <h1 className="text-2xl font-bold mb-5">Languages</h1>

      {languages.map((language) => (
        <div key={language.id} className="flex flex-row my-2">
          <Image src={language.flagUrl} width={40} height={40} alt={language.name} />
        </div>
      ))}
    </div>
  );
}
