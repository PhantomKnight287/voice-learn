import { cookies } from "next/headers";

export function getToken(
  cookiesStore: ReturnType<typeof cookies>,
  accessor: string = "voice_learn_token"
) {
  const token = cookiesStore.get(accessor);
  if (!token?.value) return null;
  return token.value;
}
