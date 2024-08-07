"use server";

import { API_URL } from "@/constants";
import { getToken } from "@/lib/cookies";
import { removeAvatarSchema, sendNotificationSchema, updateUserSchema } from "@/schema/update-user";
import { cookies } from "next/headers";

export async function updateUserProfile(userId: string, body: any) {
  const result = updateUserSchema.safeParse(body);
  if (!result.success) {
    return {
      error: result.error.errors[0].message,
    };
  }
  const token = getToken(cookies());
  const req = await fetch(`${API_URL}/users/${userId}`, {
    method: "PATCH",
    headers: {
      "Content-type": "application/json",
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(body),
  });
  const res = await req.json();
  if (!req.ok) {
    return {
      error: res.message ?? "An error occurred",
    };
  }
  return res as { message: string };
}

export async function removeAvatar(userId: string, body: any) {
  const result = removeAvatarSchema.safeParse(body);
  if (!result.success) {
    return {
      error: result.error.errors[0].message,
    };
  }
  const token = getToken(cookies());
  const req = await fetch(`${API_URL}/users/${userId}/avatar`, {
    method: "DELETE",
    headers: {
      "Content-type": "application/json",
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(body),
  });
  const res = await req.json();
  if (!req.ok) {
    return {
      error: res.message ?? "An error occurred",
    };
  }
  return res as { message: string };
}


export async function notifyUser(userId: string, body: any) {
  const result = sendNotificationSchema.safeParse(body);
  if (!result.success) {
    return {
      error: result.error.errors[0].message,
    };
  }
  const token = getToken(cookies());
  const req = await fetch(`${API_URL}/users/${userId}/notification`, {
    method: "POST",
    headers: {
      "Content-type": "application/json",
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(body),
  });
  const res = await req.json();
  if (!req.ok) {
    return {
      error: res.message ?? "An error occurred",
    };
  }
  return res as { message: string };
}
