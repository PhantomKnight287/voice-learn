import { makeRequest } from "@/lib/req";
import { NextRequest, NextResponse } from "next/server";
import { VerifyMagicLinkBody, VerifyMagicLinkResponse } from "./types";
import { cookies } from "next/headers";
import ms from "ms";
import { redirect } from "next/navigation";

export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  const token = request.nextUrl.searchParams.get("token");
  if (!token)
    return NextResponse.json(
      { message: "Invalid Magic Link" },
      { status: 400 }
    );
  const req = await makeRequest<VerifyMagicLinkBody, VerifyMagicLinkResponse>(
    "/auth/verify-magic-link",
    {
      body: {
        token: token,
      },
      method: "POST",
    }
  );
  if (req.failed) {
    return NextResponse.json(
      { message: req.error.message },
      { status: req.error.statusCode }
    );
  } else {
    const cookiesStore = cookies();
    cookiesStore.set("voice_learn_token", req.data.token, {
      httpOnly: false,
      expires: new Date(Date.now() + ms("30 days")),
    });
    redirect(`/`);
  }
}
