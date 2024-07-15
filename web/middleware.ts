import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

export function middleware(request: NextRequest) {
  if (process.env.NODE_ENV === "development") return;
  if (
    request.nextUrl.pathname.startsWith("/legal") ||
    request.nextUrl.pathname == "/"
  ) {
    return;
  }
  return NextResponse.redirect(new URL("/", request.url));
}

export const config = {
  matcher: ["/((?!api|_next/static|_next/image|favicon.ico).*)"],
};
