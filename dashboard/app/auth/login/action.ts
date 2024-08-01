"use server";

import { API_URL } from "@/constants";
import { cookies } from "next/headers";

export async function loginAction(email: string, password: string) {
  const req = await fetch(`${API_URL}/auth/login`, {
    headers: { "content-type": "application/json" },
    method: "POST",
    body: JSON.stringify({ email, password }),
  });
  const body = await req.json();
  if (!req.ok) {
    console.log(body)
    return {
      error: body.message || "Internal server error",
    };
  }
  cookies().set("voice_learn_admin_token",body.token,{maxAge:30 * 24 * 60 * 60 * 1000})
  return body;
}
