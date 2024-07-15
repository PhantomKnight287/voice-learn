import { COOKIE_NAME } from "@/constants";
import { cookies } from "next/headers";

export function getToken(
  cookiesStore: ReturnType<typeof cookies>,
  accessor: string = COOKIE_NAME
) {
  const token = cookiesStore.get(accessor);
  if (!token?.value) return null;
  return token.value;
}
