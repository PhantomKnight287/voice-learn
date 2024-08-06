"use client";

import { Button } from "@/components/ui/button";
import { useState } from "react";
import { User } from "./type";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { updateUserSchema } from "@/schema/update-user";
import { zodResolver } from "@hookform/resolvers/zod";
import {
  Dialog,
  DialogContent,
  DialogDescription,
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

export default function UserActions({ user }: { user: User }) {
  const [updateProfileModalOpened, setUpdateProfileModalOpened] =
    useState(false);
  const form = useForm<z.infer<typeof updateUserSchema>>({
    defaultValues: {
      ...user,
      updateReasonTitle: "Profile updated by admin",
    },
    resolver: zodResolver(updateUserSchema),
  });
  
  return (
    <>
      <div className="flex flex-row gap-2">
        <Button>Remove Avatar</Button>
        <Button>Send Notification</Button>
        <Button onClick={() => setUpdateProfileModalOpened((o) => !o)}>
          Update Profile
        </Button>
      </div>
      <Dialog
        open={updateProfileModalOpened}
        onOpenChange={setUpdateProfileModalOpened}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Update {user.name}&apos;s profile</DialogTitle>
          </DialogHeader>
          <Form {...form}>
            <form
              onSubmit={form.handleSubmit(console.log)}
              className="space-y-3"
            >
              <FormField
                control={form.control}
                name="name"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Name</FormLabel>
                    <FormControl>
                      <Input placeholder="shadcn" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="xp"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>XP</FormLabel>
                    <FormControl>
                      <Input placeholder="shadcn" type="number" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="lives"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Lives</FormLabel>
                    <FormControl>
                      <Input placeholder="shadcn" type="number" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="voiceMessages"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Voice Credits</FormLabel>
                    <FormControl>
                      <Input placeholder="shadcn" type="number" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="emeralds"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Emeralds</FormLabel>
                    <FormControl>
                      <Input placeholder="shadcn" type="number" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="updateReasonTitle"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Update Reason Title</FormLabel>
                    <FormControl>
                      <Input placeholder="shadcn" type="text" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="updateReasonDescription"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Update Reason Description</FormLabel>
                    <FormControl>
                      <Input type="text" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <Button
                type="submit"
                className="w-full"
                disabled={!form.formState.isDirty}
              >
                Update
              </Button>
            </form>
          </Form>
        </DialogContent>
      </Dialog>
    </>
  );
}
