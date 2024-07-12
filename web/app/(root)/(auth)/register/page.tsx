
import RegisterForm from "./page.client";
import { Metadata } from "next";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { getToken } from "@/utils/token";

export const metadata: Metadata = {
  title: "Register",
  description: "Register to use VoiceLearn",
};

export default function Register() {
  const token = getToken(cookies());
  if (token) {
    redirect("/chats");
  }
  return (
    <div className="container flex min-h-screen h-screen w-screen flex-col items-center justify-center bg-background">
      <div className="mx-auto flex w-full flex-col justify-center gap-6 sm:w-[350px]">
        <RegisterForm />
      </div>
    </div>
  );
}
