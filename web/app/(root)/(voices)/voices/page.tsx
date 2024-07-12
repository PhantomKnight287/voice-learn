import ErrorMessage from "@/components/common/error";
import { makeRequest } from "@/lib/req";
import VoiceCard from "./page.client";
import { Metadata } from "next";

export const metadata: Metadata = {
  title: "Voices",
  description: "View the voices available on VoiceLearn",
};

async function Voices() {
  const voicesReq = await makeRequest<undefined, any[]>("/voices", {
    body: undefined,
    method: "GET",
    cache: "no-cache",
  });

  if (voicesReq.failed) return <ErrorMessage key={voicesReq.error.message} />;

  return (
    <div className="container">
      <div className="flex flex-col w-full items-start">
        <h1 className="text-2xl font-semibold">
          Voices{" "}
          <span className="text-muted-foreground">
            ({voicesReq.data.length})
          </span>
        </h1>
        <p className="tracking-tigher text-muted-foreground">
          List of all the voices available and tokens required to generate an
          output. All voices are multilingual.
        </p>
      </div>
      <div className="flex w-full flex-col items-center justify-center gap-2 overflow-y-auto p-6 md:grid md:grid-cols-2 xl:grid-cols-3">
        {voicesReq.data.map((voice) => (
          <VoiceCard voice={voice} key={voice.id} />
        ))}
      </div>
    </div>
  );
}

export default Voices;
