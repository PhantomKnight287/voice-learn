'use client';

import { Button } from "@/components/ui/button"
import {
    Card,
    CardContent,
    CardDescription,
    CardFooter,
    CardHeader,
    CardTitle,
} from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { useToast } from "@/components/ui/use-toast";
import { useState, } from "react"
import { loginAction } from "./action";
import { useUser } from "@/state/user";
import { useRouter } from "next/navigation";

export default function Login() {
    return (
        <div className="flex w-full h-screen items-center justify-center">
            <LoginForm />
        </div>
    )
}

function LoginForm() {
    const [email, setEmail] = useState("")
    const [password, setPassword] = useState("")
    const { toast } = useToast()
    const { user, setUser } = useUser()
    const { replace } = useRouter()
    return (
        <Card className="w-full max-w-sm">
            <CardHeader>
                <CardTitle className="text-2xl">Login</CardTitle>
                <CardDescription>
                    Enter your email below to login to your account.
                </CardDescription>
            </CardHeader>
            <CardContent className="grid gap-4">
                <div className="grid gap-2">
                    <Label htmlFor="email">Email</Label>
                    <Input id="email" type="email" placeholder="m@example.com" required
                        value={email}
                        onChange={e => setEmail(e.target.value)}
                    />
                </div>
                <div className="grid gap-2">
                    <Label htmlFor="password">Password</Label>
                    <Input id="password" type="password" required
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        placeholder="password"
                    />
                </div>
            </CardContent>
            <CardFooter>
                <Button className="w-full"

                    onClick={async () => {
                        const data = await loginAction(email, password)
                        if (data.error) {
                            return toast({ title: data.error, variant: "destructive" })
                        }

                        setUser({
                            id: data.id, name: data.name
                        })
                        toast({ title: `Welcome ${data.name}` })
                        replace("/dashboard")
                    }}
                >Sign in</Button>
            </CardFooter>
        </Card>
    )
}
