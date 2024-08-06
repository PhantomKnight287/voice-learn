"use server";
import { API_URL } from "@/constants";
import { getToken } from "@/lib/cookies";
import { cookies } from "next/headers";

export default async function fetchUser() {
  const token = getToken(cookies());
  const req = await fetch(`${API_URL}/auth/hydrate`, {
    body: undefined,
    method: "GET",
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });
  if (!req.ok) {
    return;
  } else {
    const body = await req.json();
    return body;
  }
}
