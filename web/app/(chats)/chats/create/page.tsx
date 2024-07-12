import { makeRequest } from "@/lib/req";
import { Voice } from "./types";
import { VoiceCard } from "./page.client";

export const dynamic = "force-dynamic";

async function Page({}: {}) {
  const req = await makeRequest<undefined, Voice[]>("/voices", {
    method: "GET",
    body: undefined,
  });
  if (req.failed) return null;
  return (
    <div className="container flex flex-col gap-4 items-center">
      <div className="w-full items-start">
        <h1 className="text-2xl font-semibold">Voices</h1>
      </div>
      {req.data.map((voice) => (
        <VoiceCard voice={voice} key={voice.id} />
      ))}
    </div>
  );
}

export default Page;
