"use client";
import { useUser } from "@/state/user";

export default function ClientLayout({ clientId }: { clientId: string }) {
  const { user } = useUser();
  if (!user?.id) return null;
  return null;
}
