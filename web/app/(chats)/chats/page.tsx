import { makeRequest } from "@/lib/req";
import { getToken } from "@/utils/token";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { Chat } from "./types";
import ErrorMessage from "@/components/common/error";
import ChatCard, { CreateChatModal } from "./page.client";
import { languagesArray } from "@/constants/languages";

export const dynamic = "force-dynamic";

async function Page() {
  const token = getToken(cookies());
  if (!token) return redirect("/login");
  const req = await makeRequest<undefined, Chat[]>("/chats", {
    method: "GET",
    body: undefined,
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });

  const voicesReq = await makeRequest<undefined, any[]>("/voices", {
    method: "GET",
    body: undefined,
    cache: "no-cache",
  });

  return (
    <div className="container">
      <div className="flex flex-row w-full items-center">
        <h1 className="text-2xl font-semibold">My Conversations</h1>
        {voicesReq.failed ? null : (
          <CreateChatModal voices={voicesReq.data} languages={languagesArray} />
        )}
      </div>
      <div className="flex flex-col items-center justify-center gap-4 mt-4">
        {req.failed ? (
          <ErrorMessage message={req.error.message} />
        ) : (
          <>
            {req.data.map((chat) => (
              <ChatCard chat={chat} key={chat.id} />
            ))}
          </>
        )}
      </div>
    </div>
  );
}

export default Page;
