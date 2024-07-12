"use client";

import { Chat } from "./types";
import Link from "next/link";
import Image from "next/image";
import dayjs from "dayjs";
import { upperFirst } from "@/utils/string";
import { languages } from "@/constants/languages";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { MessageCirclePlus } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { CreateChatResponse, Voice } from "./create/types";
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
import { readCookie } from "@/utils/cookie";
import { makeRequest } from "@/lib/req";
import { toast } from "sonner";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { useRouter } from "next/navigation";

import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";

const DateFormatter = Intl.DateTimeFormat("en-IN", {
  dateStyle: "short",
});

function ChatCard({ chat }: { chat: Chat }) {
  return (
    <Link
      className="flex items-center gap-4 rounded-lg bg-gray-100 p-4 transition-colors hover:bg-gray-200 dark:bg-gray-800 dark:hover:bg-gray-700 w-full"
      href={`/chats/${chat.id}`}
    >
      <Avatar>
        <AvatarImage
          alt={chat.voice.name}
          src={`https://api.dicebear.com/8.x/initials/png?seed=${chat.voice.name
            .split("_")[0]
            .replaceAll(" ", "")}`}
        />
        <AvatarFallback>{chat.voice.name}</AvatarFallback>
      </Avatar>
      <div className="flex-1 grid gap-1">
        <div className="flex items-center justify-between">
          <p className="text-base font-medium">{chat.name}</p>
          <p className="text-sm text-gray-500 dark:text-gray-400">
            {dayjs(chat.updatedAt).format("DD/MM/YYYY")}
          </p>
        </div>
        <p className="text-sm text-gray-500 dark:text-gray-400 line-clamp-1">
          {chat.initialPrompt}
        </p>
      </div>
    </Link>
  );
}

export default ChatCard;

const formSchema = z.object({
  name: z.string().min(1, { message: "Please enter name of the chat." }),
  initialPrompt: z.string().optional(),
  voiceId: z.string(),
  language: z.string(),
});

export function CreateChatModal({
  voices,
  languages,
}: {
  voices: any[];
  languages: string[];
}) {
  const [modalOpened, setModalOpened] = useState(false);
  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {},
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
      <Button
        variant={"secondary"}
        className={"ml-auto"}
        onClick={() => {
          setModalOpened((o) => !o);
        }}
      >
        <MessageCirclePlus />
      </Button>
      <Dialog open={modalOpened} onOpenChange={setModalOpened}>
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
                name="language"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Language</FormLabel>
                    <Select
                      onValueChange={field.onChange}
                      defaultValue={field.value}
                    >
                      <FormControl>
                        <SelectTrigger>
                          <SelectValue placeholder="Select a language" />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {languages.map((lang) => (
                          <SelectItem key={lang} value={lang}>
                            {upperFirst(lang)}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <FormDescription>Choose a language.</FormDescription>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="voiceId"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Voice</FormLabel>
                    <Select
                      onValueChange={field.onChange}
                      defaultValue={field.value}
                    >
                      <FormControl>
                        <SelectTrigger>
                          <SelectValue placeholder="Select a voice" />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {voices.map((voice) => (
                          <SelectItem
                            key={voice.id}
                            value={voice.id}
                            className="flex flex-row items-center justify-between w-full"
                          >
                            {voice.name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <FormDescription>
                      Choose a voice. View list of voices{" "}
                      <a
                        target="_blank"
                        href="/voices"
                        className="text-blue-500"
                      >
                        here
                      </a>
                      .
                    </FormDescription>
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
                      Tell AI to act like someone. For example: a Cashier
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
                    setModalOpened(false);
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
