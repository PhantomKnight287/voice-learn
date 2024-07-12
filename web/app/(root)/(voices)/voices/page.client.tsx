"use client";

import { Card, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import Image from "next/image";
import dynamic from "next/dynamic";
import { useState } from "react";
import { z } from "zod";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { languagesArray } from "@/constants/languages";
import { useRouter } from "next/navigation";
import { readCookie } from "@/utils/cookie";
import { makeRequest } from "@/lib/req";
import { CreateChatResponse } from "@/app/(chats)/chats/create/types";
import { toast } from "sonner";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { upperFirst } from "@/utils/string";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { useUser } from "@/state/user";

const Waveform = dynamic(() => import("@/components/waveform"), {
  ssr: false,
  loading: () => <p>Loading...</p>,
});

const formSchema = z.object({
  name: z.string().min(1, { message: "Please enter name of the chat." }),
  initialPrompt: z.string().optional(),
  voiceId: z.string(),
  language: z.string(),
});
function VoiceCard({ voice }: { voice: any }) {
  const [createChatModalOpened, setCreateChatModalOpened] = useState(false);
  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      voiceId: voice.id,
      language: languagesArray[0],
    },
  });
  const { replace } = useRouter();
  const [loading, setLoading] = useState(false);
  const { user } = useUser();

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
      <Card>
        <CardHeader className="pb-0">
          <Image
            src={`https://api.dicebear.com/8.x/initials/png?seed=${voice.name
              .split("_")[0]
              .replaceAll(" ", "")}`}
            alt={voice.name}
            width={100}
            height={100}
            className="rounded-lg mb-2"
          />
        </CardHeader>
        <div className="flex flex-row items-center justify-between px-6">
          <CardTitle>{voice.name}</CardTitle>
          <div className="flex flex-row items-center bg-muted px-2 py-2 rounded-xl gap-2">
            <Image src="/coin.png" width={30} height={30} alt="Coin Logo" />
            {voice.cost}
          </div>
        </div>
        <CardFooter className="flex flex-col items-start gap-2 w-full">
          <p>Preview Audio</p>
          <Waveform audio={voice.previewUrl} />
          <Button
            className="w-full"
            onClick={() => {
              if (user?.id) setCreateChatModalOpened((o) => !o);
              else replace(`/login`);
            }}
          >
            Create New Chat
          </Button>
        </CardFooter>
      </Card>
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
                        {languagesArray.map((lang) => (
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

export default VoiceCard;
