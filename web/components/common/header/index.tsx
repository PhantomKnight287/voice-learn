"use client";
import Link from "next/link";

import InteractiveHeaderComponents from "./index.client";
import VoiceLearnLogo_Light from "@/components/icons/light";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";

const LINKS = [
  {
    href: "/chats",
    label: "Chats",
  },
  {
    href: "/voices",
    label: "Voices",
  },
];

export default function Header() {
  const pathname = usePathname();
  return (
    <header
      className={cn("flex pt-5 pb-6 z-10 ", {
        "bg-transparent fixed w-full backdrop-blur-lg": pathname === "/",
      })}
    >
      <div className="container flex flex-row">
        <Link href="/" className="flex items-center justify-center">
          <div className="flex flex-row items-end">
            <VoiceLearnLogo_Light width={40} height={40} />
            <div className="font-semibold leading-3 ml-1">
              Voice Learn
            </div>
          </div>
        </Link>
        <div className="flex flex-row ml-auto">
          <InteractiveHeaderComponents />
        </div>
      </div>
    </header>
  );
}
