import { DataTable } from "@/components/ui/data-table";
import { columns } from "./columns";
import { getToken } from "@/lib/cookies";
import { cookies } from "next/headers";
import { API_URL } from "@/constants";

export const dynamic = "force-dynamic"

export default async function Users({
  searchParams,
}: {
  searchParams: { [key: string]: string };
}) {
  const page = Number.isNaN(parseInt(searchParams.page))
    ? 1
    : parseInt(searchParams.page);
  const limit = Number.isNaN(parseInt(searchParams.limit))
    ? 50
    : parseInt(searchParams.limit);

  const token = getToken(cookies());
  const req = await fetch(`${API_URL}/users?page=${page ?? 1}&limit=${limit}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  const data = await req.json();

  return (
    <main className="flex flex-1 flex-col gap-4 p-4 lg:gap-6 lg:p-6">
      <div className="flex items-center">
        <h1 className="text-lg font-semibold md:text-2xl">Users</h1>
      </div>
      <div className="flex flex-1 items-start justify-start rounded-lg border border-dashed shadow-sm flex-col p-4">
        <div className="px-auto w-full">
          <DataTable
            columns={columns}
            data={data.results}
            pageCount={data.pages}
          />
        </div>
      </div>
    </main>
  );
}
