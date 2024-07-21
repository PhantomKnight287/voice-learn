'use client'

import { useUser } from "@/state/user"
import { Button, buttonVariants } from "../ui/button"
import Link from "next/link"

export default function Header() {
    const { user } = useUser()
    return <div className="container flex flex-row items-center justify-between py-2">
        <h1 className="text-2xl">
            Voice Learn
        </h1>

        {
            !user.id ? <Link
                href="/auth/login"
                className={buttonVariants()}
            >
                Login
            </Link>
                : <span>
                    {user.name}
                </span>
        }
    </div>
}