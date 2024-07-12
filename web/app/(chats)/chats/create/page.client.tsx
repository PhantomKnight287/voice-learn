"use client";

import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { usePathname, useRouter } from "next/navigation";

import { useState } from "react";
import { CreateChatResponse, Voice } from "./types";
import Image from "next/image";
import { Separator } from "@/components/ui/separator";
import { Badge } from "@/components/ui/badge";
import { upperFirst } from "@/utils/string";
import { languages } from "@/constants/languages";
import { AlertDialogCancel } from "@radix-ui/react-alert-dialog";
import { z } from "zod";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { readCookie } from "@/utils/cookie";
import { makeRequest } from "@/lib/req";
import { toast } from "sonner";

const formSchema = z.object({
  name: z.string().min(1, { message: "Please enter name of the chat." }),
  initialPrompt: z.string().optional(),
  voiceId: z.string(),
});

export function VoiceCard({ voice }: { voice: Voice }) {
  const [createChatModalOpened, setCreateChatModalOpened] = useState(false);
  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      voiceId: voice.id,
    },
  });
  const { replace } = useRouter();
  const [loading, setLoading] = useState(false);

  async function onSubmit(values: z.infer<typeof formSchema>) {
    const token = readCookie("voice_learn_token");
    if (!token) replace("/login");
    setLoading(true);

    const req = await makeRequest<
      z.infer<typeof formSchema>,
      CreateChatResponse
    >("/chats", {
      method: "POST",
      body: values,
      headers: {
        authorization: `Bearer ${token}`,
      },
    });
    setLoading(false);
    if (req.failed) return toast.error(req.error.message);
    replace(`/chats/${req.data.id}`);
  }
  return (
    <>
      <AlertDialog>
        <AlertDialogTrigger asChild>
          <button className="flex flex-row items-center gap-4 bg-secondary p-4 rounded-xl hover:scale-110 transition-all duration-150">
            <Image
              src={`https://api.dicebear.com/8.x/initials/png?seed=${voice.name
                .split("_")[0]
                .replaceAll(" ", "")}`}
              alt={voice.name}
              width={100}
              height={100}
              className="rounded-lg"
            />
            <div className="flex flex-col items-start">
              <h3 className="text-xl line-clamp-1 max-w-52 text-left">
                {voice.name}
              </h3>
              <p className="tracking-tight text-muted-foreground text-left line-clamp-2 max-w-80">
                {voice.description}
              </p>
              <div className="flex flex-row items-center gap-2 mt-4">
                {voice.gender ? (
                  <Badge>{upperFirst(voice.gender)}</Badge>
                ) : null}
                {voice.language ? (
                  <Badge>
                    {languages[voice.language as keyof typeof languages] ||
                      upperFirst(voice.language)}
                  </Badge>
                ) : null}
              </div>
            </div>
          </button>
        </AlertDialogTrigger>
        <AlertDialogContent>
          <AlertDialogHeader>
            <Image
              src={`https://api.dicebear.com/8.x/initials/png?seed=${voice.name
                .split("_")[0]
                .replaceAll(" ", "")}`}
              alt={voice.name}
              width={100}
              height={100}
              className="rounded-lg mx-auto"
            />
            <h1 className="text-2xl font-medium">{voice.name}</h1>
            <Separator />
            <div className="flex flex-row items-center gap-2">
              {voice.gender ? <Badge>{upperFirst(voice.gender)}</Badge> : null}
              {voice.language ? (
                <Badge>
                  {languages[voice.language as keyof typeof languages] ||
                    upperFirst(voice.language)}
                </Badge>
              ) : null}
            </div>
            <video controls className="h-10">
              <source src={voice.previewUrl} type="audio/mpeg" />
              Your browser does not support the video tag.
            </video>
            <Separator />
            <AlertDialogDescription>{voice.description}</AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => {
                setCreateChatModalOpened((o) => !o);
              }}
            >
              Continue
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
      <Dialog
        open={createChatModalOpened}
        onOpenChange={setCreateChatModalOpened}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Create New Chat</DialogTitle>
          </DialogHeader>
          <Form {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
              <FormField
                control={form.control}
                name="name"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Name</FormLabel>
                    <FormControl>
                      <Input placeholder="In a Mall" {...field} />
                    </FormControl>
                    <FormDescription>The name of your chat.</FormDescription>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="initialPrompt"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Initial Prompt</FormLabel>
                    <FormControl>
                      <Textarea
                        placeholder="Act like a Cashier..."
                        {...field}
                      />
                    </FormControl>
                    <FormDescription>
                      Tell AI to act like someone like a Barista or a Cashier
                    </FormDescription>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <div className="flex flex-col w-full gap-4">
                <Button type="submit" loading={loading}>
                  Create
                </Button>
                <Button
                  type="button"
                  variant={"secondary"}
                  disabled={loading}
                  onClick={() => {
                    if (loading) return;
                    setCreateChatModalOpened(false);
                  }}
                >
                  Cancel
                </Button>
              </div>
            </form>
          </Form>
        </DialogContent>
      </Dialog>
    </>
  );
}
