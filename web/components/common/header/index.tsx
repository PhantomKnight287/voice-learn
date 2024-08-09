"use client";
import Link from "next/link";

import InteractiveHeaderComponents from "./index.client";
import VoiceLearnLogo_Light from "@/components/icons/light";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";
import { useTheme } from "next-themes";
import VoiceLearnLogo_Dark from "@/components/icons/dark";
import { CalSans, sans } from "@/fonts";

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
      className={cn("flex pt-5 pb-6 z-50", {
        "bg-transparent  w-full backdrop-blur-lg": pathname === "/",
      })}
    >
      <div className="w-full p-4 pt-0 md:py-6 md:px-10 flex flex-row">
        <Link href="/" className="flex items-center justify-center">
          <div className="flex flex-row items-center">
            <div className="bg-primary p-2 rounded-md">
              <VoiceLearnLogo_Light
                width={30}
                height={30}
                className="hidden dark:block"
              />
              <VoiceLearnLogo_Dark
                width={30}
                height={30}
                className="dark:hidden block"
              />
            </div>
            <div
              className={cn(
                "font-semibold leading-loose ml-1 text-lg",
                sans.className
              )}
            >
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
