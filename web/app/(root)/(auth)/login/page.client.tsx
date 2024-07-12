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
import { cn } from "@/lib/utils";

const loginFormSchema = z.object({
  email: z.string().email({ message: "Please enter a valid email" }),
});

function LoginForm() {
  const [loading, setLoading] = useState(false);
  const [emailSent, setEmailSent] = useState(false);
  const form = useForm<z.infer<typeof loginFormSchema>>({
    resolver: zodResolver(loginFormSchema),
    defaultValues: {
      email: "",
    },
  });
  async function onSubmit(values: z.infer<typeof loginFormSchema>) {
    setLoading(true);
    const req = await makeRequest<LoginBody, LoginResponse>("/auth/login", {
      body: values,
      method: "POST",
    });
    if (req.failed) {
      toast.error(req.error.message, {});
    } else {
      setEmailSent(true);
    }
    setLoading(false);
  }
  return (
    <Card className="min-w-56">
      <CardHeader>
        <CardTitle className="text-xl">
          {emailSent ? "Email Sent" : "Sign In"}
        </CardTitle>
        <CardDescription>
          {emailSent
            ? "We've sent a magic link on your email."
            : "Enter your email to receive a login link"}
        </CardDescription>
      </CardHeader>
      <CardContent
        className={cn({
          hidden: emailSent,
        })}
      >
        <Form {...form}>
          <form className="grid gap-4" onSubmit={form.handleSubmit(onSubmit)}>
            <FormField
              control={form.control}
              name="email"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Email</FormLabel>
                  <FormControl>
                    <Input placeholder="john@company.com" {...field} />
                  </FormControl>
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
