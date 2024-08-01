import { getToken } from "@/utils/token";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";

export default function DashboardPage(){
    const token = getToken(cookies())
    if(!token) redirect("/")
        return <>
        </> 
}