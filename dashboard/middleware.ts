import { NextResponse } from "next/server";
import { NextRequest } from "next/server";
import { getToken } from "./lib/cookies";
import { COOKIE_NAME } from "./constants";

export function middleware(request: NextRequest) {
  const cookies = request.cookies;
  const token = cookies.get(COOKIE_NAME);
  if (!token?.value) return NextResponse.redirect(new URL("/", request.url));
  return NextResponse.next();
}

export const config = {
  matcher: ["/dashboard", "/dashboard/:path*"],
};
