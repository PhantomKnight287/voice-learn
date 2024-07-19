"use client";
import { UserState, useUser } from "@/state/user";
import { buttonVariants } from "@/components/ui/button";
import { readCookie } from "@/utils/cookie";
import { useEffect } from "react";
import { makeRequest } from "@/lib/req";
import { PUBLIC_CDN_URL } from "@/constants";
import Heart from "@/components/icons/heart";
import { BoltIcon as BoltOutline } from "@heroicons/react/24/outline";
import { BoltIcon as BoltSolid } from "@heroicons/react/24/solid";

export default function InteractiveHeaderComponents() {
  const { user, setUser } = useUser();
  async function fetchUser(token: string) {
    const req = await makeRequest<undefined, UserState["user"]>(
      "/auth/hydrate",
      {
        body: undefined,
        method: "GET",
        headers: {
          Authorization: `Bearer ${token}`,
        },
      }
    );
    if (req.failed) {
      return;
    } else {
      setUser(req.data as UserState["user"]);
    }
  }
  useEffect(() => {
    const token = readCookie("voice_learn_token");
    if (!token) return;
    fetchUser(token);
  }, []);

  if (!user)
    return (
      <>
        <a
          href="#waitlist"
          className={buttonVariants({
            variant: "default",
          })}
        >
          Get Started
        </a>
      </>
    );
  return (
    <div className="flex flex-row gap-2 min-w-[90px]">
      <div className="flex flex-row items-center gap-4 ">
        <div className="flex flex-row items-center px-2 py-2 rounded-xl">
          {user.isStreakActive ? (
            <BoltSolid className="text-primary mr-2" width={30} height={30} />
          ) : (
            <BoltOutline
              className="outline-primary mr-2"
              width={30}
              height={30}
            />
          )}

          {user.activeStreaks}
        </div>
        <div className="flex flex-row items-center px-2 py-2 rounded-xl">
          <img
            src={`${PUBLIC_CDN_URL}/emerald.png`}
            width={30}
            height={30}
            alt="Emerald"
            className="mr-2"
          />
          {user.emeralds}
        </div>
        <div className="flex flex-row items-center px-2 py-2 rounded-xl">
          <Heart width={30} height={30} className="mr-2" />
          {user.lives}
        </div>
      </div>
    </div>
  );
}
