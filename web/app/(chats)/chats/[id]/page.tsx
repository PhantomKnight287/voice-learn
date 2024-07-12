import ErrorMessage from "@/components/common/error";
import { makeRequest } from "@/lib/req";
import { getToken } from "@/utils/token";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { ChatInfo } from "./types";
import { ChatContainer } from "./page.client";

export const dynamic = "force-dynamic";

async function Chat({ params }: { params: { id: string } }) {
  const token = getToken(cookies());
  if (!token) return redirect("/login");
  const req = await makeRequest<undefined, ChatInfo>(`/chats/${params.id}`, {
    body: undefined,
    method: "GET",
    headers: {
      authorization: `Bearer ${token}`,
    },
  });
  if (req.failed) return <ErrorMessage message={req.error.message} />;
  return <ChatContainer chat={req.data} />;
}

export default Chat;

