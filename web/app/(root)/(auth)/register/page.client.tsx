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
import { RegisterBody, RegisterResponse } from "./types";
import { ApiError } from "@/types/error";
import { toast } from "sonner";
import { cn } from "@/lib/utils";

const registerFormSchema = z.object({
  name: z.string().min(1, { message: "Name is required" }),
  email: z.string().email({ message: "Please enter a valid email" }),
});

function RegisterForm() {
  const [loading, setLoading] = useState(false);
  const [emailSent, setEmailSent] = useState(false);
  const form = useForm<z.infer<typeof registerFormSchema>>({
    resolver: zodResolver(registerFormSchema),
    defaultValues: {
      email: "",
      name: "",
    },
  });
  async function onSubmit(values: z.infer<typeof registerFormSchema>) {
    setLoading(true);
    const req = await makeRequest<RegisterBody, RegisterResponse>(
      "/auth/register",
      {
        body: values,
        method: "POST",
      }
    );
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
          {emailSent ? "Email Sent" : "Sign Up"}
        </CardTitle>
        <CardDescription>
          {emailSent
            ? "We've sent a magic link on your email."
            : "Enter your information to create an account"}
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
              name="name"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Name</FormLabel>
                  <FormControl>
                    <Input placeholder="John Doe" {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
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
              Create an account
            </Button>
          </form>
        </Form>
        <div className="mt-4 text-center text-sm">
          Already have an account?{" "}
          <Link href="/login" replace className="underline">
            Sign in
          </Link>
        </div>
      </CardContent>
    </Card>
  );
}

export default RegisterForm;
