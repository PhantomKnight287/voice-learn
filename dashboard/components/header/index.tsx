"use client";

import { useUser } from "@/state/user";
import { Button, buttonVariants } from "../ui/button";
import Link from "next/link";
import { useEffect } from "react";
import fetchUser from "./action";
import { usePathname } from "next/navigation";

export default function Header() {
  const { user, setUser } = useUser();
  const pathname = usePathname();
  useEffect(() => {
    if (user?.id) return;
    fetchUser().then((d) => {
      if (d) setUser(d);
    });
  }, []);
  if (!["/login", "/"].includes(pathname)) return null;
  return (
    <div className="container flex flex-row items-center justify-between py-2">
      <h1 className="text-2xl">Voice Learn</h1>

      {!user?.id ? (
        <Link href="/auth/login" className={buttonVariants()}>
          Login
        </Link>
      ) : (
        <span>{user.name}</span>
      )}
    </div>
  );
}
