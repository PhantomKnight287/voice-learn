"use client";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { zodResolver } from "@hookform/resolvers/zod";
import Link from "next/link";
import { useForm } from "react-hook-form";
import { z } from "zod";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { useState } from "react";
import { makeRequest } from "@/lib/req";
import { LoginBody, LoginResponse } from "./types";
import { toast } from "sonner";
import { PasswordInput } from "@/components/password-input";
import { useUser } from "@/state/user";
import { createCookie } from "@/utils/cookie";
import { COOKIE_NAME, REDIRECTS } from "@/constants";
import { useRouter } from "next/navigation";

const loginFormSchema = z.object({
  email: z.string().email({ message: "Please enter a valid email" }),
  password: z.string().min(1, { message: "Please enter your password" }),
});

function LoginForm() {
  const [loading, setLoading] = useState(false);
  const { user, setUser } = useUser();
  const { replace } = useRouter();
  const form = useForm<z.infer<typeof loginFormSchema>>({
    resolver: zodResolver(loginFormSchema),
    defaultValues: {
      email: "",
      password: "",
    },
  });
  async function onSubmit(values: z.infer<typeof loginFormSchema>) {
    setLoading(true);
    const req = await makeRequest<LoginBody, LoginResponse>("/auth/sign-in", {
      body: {
        ...values,
        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
        timeZoneOffset: (-new Date().getTimezoneOffset()).toString(),
      },
      method: "POST",
    });
    if (req.failed) {
      toast.error(req.error.message, {});
    } else {
      setUser(req.data.user);
      createCookie(COOKIE_NAME, req.data?.token, 365);
      toast.success(`Welcome back ${req.data.user.name}`);
      replace(REDIRECTS.DASHBOARD);
    }
    setLoading(false);
  }
  return (
    <Card className="min-w-56">
      <CardHeader>
        <CardTitle className="text-xl">Lets sign you in</CardTitle>
        <CardDescription>
          Welcome back! We&apos;re glad to see you again. Please enter your
          details to sign in.
        </CardDescription>
      </CardHeader>
      <CardContent>
        <Form {...form}>
          <form className="grid gap-4" onSubmit={form.handleSubmit(onSubmit)}>
            <FormField
              control={form.control}
              name="email"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Email</FormLabel>
                  <FormControl>
                    <Input placeholder="john@sillyclub.com" {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            <FormField
              control={form.control}
              name="password"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Password</FormLabel>
                  <FormControl>
                    <PasswordInput placeholder="********" {...field} />
                  </FormControl>
                  <div className="flex">
                    <Link
                      href="/reset-password"
                      className="underline text-sm ml-auto"
                    >
                      Forgot Password?
                    </Link>
                  </div>
                  <FormMessage />
                </FormItem>
              )}
            />
            <Button type="submit" className="w-full" loading={loading}>
              Login
            </Button>
          </form>
        </Form>
        <div className="mt-4 text-center text-sm">
          Don&apos;t have an account?{" "}
          <Link href="/register" replace className="underline">
            Sign Up
          </Link>
        </div>
      </CardContent>
    </Card>
  );
}

export default LoginForm;
