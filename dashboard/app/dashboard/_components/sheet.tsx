"use client";
import { Button } from "@/components/ui/button";
import { Sheet, SheetContent, SheetTrigger } from "@/components/ui/sheet";
import { Home, Menu } from "lucide-react";
import Link from "next/link";
import { LINKS } from "./links";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";

export default function NavSheet(props: { name: string }) {
  const pathname = usePathname();
  const pathnameToCheck = pathname?.replace(`/dashboard`, "");
  return (
    <header className="flex h-14 items-center gap-4 border-b bg-muted/40 px-4 lg:h-[60px] lg:px-6">
      <Sheet>
        <SheetTrigger asChild>
          <Button variant="outline" size="icon" className="shrink-0 md:hidden">
            <Menu className="h-5 w-5" />
            <span className="sr-only">Toggle navigation menu</span>
          </Button>
        </SheetTrigger>
        <SheetContent side="left" className="flex flex-col">
          <nav className="grid gap-2 text-lg font-medium">
            <Link
              href="#"
              className="flex items-center gap-2 text-lg font-semibold"
            >
              <span className="sr-only">{props.name}</span>
            </Link>
            {LINKS.map((link) => (
              <Link
                key={link.href}
                href={`/dashboard${link.href}`}
                className={cn(
                  "flex items-center gap-3 rounded-lg px-3 py-2 transition-all hover:text-primary",
                  {
                    "text-primary bg-muted": pathnameToCheck === link.href,
                    "text-muted-foreground": pathnameToCheck !== link.href,
                  }
                )}
              >
                {link.icon}
                {link.label}
              </Link>
            ))}
          </nav>
        </SheetContent>
      </Sheet>
    </header>
  );
}
