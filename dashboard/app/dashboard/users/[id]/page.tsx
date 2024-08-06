import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { API_URL } from "@/constants";
import { getToken } from "@/lib/cookies";
import { cookies } from "next/headers";
import Link from "next/link";
import UserActions from "./page.client";
import { User } from "./type";
import { ArrowLeft } from "lucide-react";
import Back from "@/components/shared/back";

export default async function UserPage({
  params,
}: {
  params: { [key: string]: string };
}) {
  const token = getToken(cookies());
  const req = await fetch(`${API_URL}/users/${params.id}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  const data = (await req.json()) as User;

  return (
    <main className="flex flex-1 flex-col gap-4 p-4 lg:gap-6 lg:p-6">
      <div className="flex items-center flex-row justify-start gap-4">
        <Back />
        <Link
          href={
            data.avatar
              ? data.avatar
              : `https://gravatar.com/avatar/${data.avatarHash}?d=404`
          }
          target="_blank"
        >
          <Avatar>
            <AvatarImage
              src={
                data.avatar
                  ? data.avatar
                  : `https://gravatar.com/avatar/${data.avatarHash}?d=404`
              }
            />
            <AvatarFallback>{data.name}</AvatarFallback>
          </Avatar>
        </Link>
        <h1 className="text-lg font-semibold md:text-2xl">{data.name}</h1>
        <div className="ml-auto">
          <UserActions user={data} />
        </div>
      </div>
      <div className="flex flex-1 items-start justify-start rounded-lg border border-dashed shadow-sm flex-col p-4">
        <div className="px-auto w-full">
          <div className="grid grid-cols-1 md:grid-cols-3 xl:grid-cols-4">
            <div className="flex flex-col items-start justify-start">
              <h3 className="font-bold text-xl">Email</h3>
              <p>{data.email}</p>
            </div>
            <div className="flex flex-col items-start justify-start">
              <h3 className="font-bold text-xl">Emeralds</h3>
              <p>{data.emeralds}</p>
            </div>
            <div className="flex flex-col items-start justify-start">
              <h3 className="font-bold text-xl">XP</h3>
              <p>{data.xp}</p>
            </div>
            <div className="flex flex-col items-start justify-start">
              <h3 className="font-bold text-xl">Voice Credits</h3>
              <p>{data.voiceMessages}</p>
            </div>
          </div>
        </div>
      </div>
    </main>
  );
}
