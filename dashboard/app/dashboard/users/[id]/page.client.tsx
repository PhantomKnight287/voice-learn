"use client";

import { Button } from "@/components/ui/button";
import { useMemo, useState, useTransition } from "react";
import { User } from "./type";
import { useForm } from "react-hook-form";
import { z } from "zod";
import {
  NotificationType,
  removeAvatarSchema,
  sendNotificationSchema,
  updateUserSchema,
} from "@/schema/update-user";
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
import { notifyUser, removeAvatar, updateUserProfile } from "./actions";
import { useToast } from "@/components/ui/use-toast";
import { useRouter } from "next/navigation";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

export default function UserActions({ user }: { user: User }) {
  const [updateProfileModalOpened, setUpdateProfileModalOpened] =
    useState(false);
  const [removeAvatarModalOpened, setRemoveAvatarModalOpened] = useState(false);
  const [notifyUserModalOpened, setNotifyUserModalOpened] = useState(false);
  const [loading, setLoading] = useState(false);
  const [isPending, startTransition] = useTransition();
  const form = useForm<z.infer<typeof updateUserSchema>>({
    defaultValues: {
      ...user,
      updateReasonTitle: "Profile updated by moderators",
    },
    resolver: zodResolver(updateUserSchema),
  });
  const removeAvatarForm = useForm<z.infer<typeof removeAvatarSchema>>({
    resolver: zodResolver(removeAvatarSchema),
    defaultValues: {
      updateReasonTitle: "Profile updated by moderators",
    },
  });
  const notifyUserForm = useForm<z.infer<typeof sendNotificationSchema>>({
    resolver: zodResolver(sendNotificationSchema),
    defaultValues: {
      title: "Profile updated by moderators",
    },
  });
  const { toast } = useToast();
  const { refresh } = useRouter();
  async function onSubmit(values: z.infer<typeof updateUserSchema>) {
    setLoading(true);
    startTransition(async () => {
      const res = await updateUserProfile(user.id, values);
      if ((res as any).error) {
        toast({
          title: (res as any).error,
          variant: "destructive",
        });
      } else {
        toast({
          title: "User Updated",
        });
      }
      setLoading(false);
      setUpdateProfileModalOpened(false);
      refresh();
    });
  }
  async function onRemoveAvatarSubmit(
    values: z.infer<typeof removeAvatarSchema>
  ) {
    setLoading(true);
    startTransition(async () => {
      const res = await removeAvatar(user.id, values);
      if ((res as any).error) {
        toast({
          title: (res as any).error,
          variant: "destructive",
        });
      } else {
        toast({
          title: "User Updated",
        });
      }
      setLoading(false);
      setRemoveAvatarModalOpened(false);
      refresh();
    });
  }
  async function onSendNotificationSubmit(
    values: z.infer<typeof sendNotificationSchema>
  ) {
    setLoading(true);
    startTransition(async () => {
      const res = await notifyUser(user.id, values);
      if ((res as any).error) {
        toast({
          title: (res as any).error,
          variant: "destructive",
        });
      } else {
        toast({
          title: "User Updated",
        });
      }
      setLoading(false);
      setNotifyUserModalOpened(false);
      refresh();
    });
  }

  return (
    <>
      <div className="flex flex-row gap-2">
        <Button onClick={() => setRemoveAvatarModalOpened((o) => !o)}>
          Remove Avatar
        </Button>
        <Button onClick={() => setNotifyUserModalOpened((o) => !o)}>
          Send Notification
        </Button>
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
            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-3">
              <FormField
                control={form.control}
                name="name"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Name</FormLabel>
                    <FormControl>
                      <Input
                        placeholder="shadcn"
                        {...field}
                        disabled={isPending}
                      />
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
                      <Input
                        placeholder="shadcn"
                        type="number"
                        {...field}
                        disabled={isPending}
                      />
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
                      <Input
                        placeholder="shadcn"
                        type="number"
                        {...field}
                        disabled={isPending}
                      />
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
                      <Input
                        placeholder="shadcn"
                        type="number"
                        {...field}
                        disabled={isPending}
                      />
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
                      <Input
                        placeholder="shadcn"
                        type="number"
                        {...field}
                        disabled={isPending}
                      />
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
                      <Input
                        placeholder="shadcn"
                        type="text"
                        {...field}
                        disabled={isPending}
                      />
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
                      <Input type="text" {...field} disabled={isPending} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <Button
                type="submit"
                className="w-full"
                disabled={!form.formState.isDirty}
                loading={loading}
              >
                Update
              </Button>
            </form>
          </Form>
        </DialogContent>
      </Dialog>
      <Dialog
        open={removeAvatarModalOpened}
        onOpenChange={setRemoveAvatarModalOpened}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Remove {user.name}&apos;s Avatar</DialogTitle>
          </DialogHeader>
          <Form {...removeAvatarForm}>
            <form
              onSubmit={removeAvatarForm.handleSubmit(onRemoveAvatarSubmit)}
              className="space-y-3"
            >
              <FormField
                control={removeAvatarForm.control}
                name="updateReasonTitle"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Update Reason Title</FormLabel>
                    <FormControl>
                      <Input
                        placeholder="shadcn"
                        type="text"
                        {...field}
                        disabled={isPending}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={removeAvatarForm.control}
                name="updateReasonDescription"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Update Reason Description</FormLabel>
                    <FormControl>
                      <Input type="text" {...field} disabled={isPending} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <Button
                type="submit"
                className="w-full"
                disabled={!form.formState.isDirty}
                loading={loading}
              >
                Update
              </Button>
            </form>
          </Form>
        </DialogContent>
      </Dialog>
      <Dialog
        open={notifyUserModalOpened}
        onOpenChange={setNotifyUserModalOpened}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Notify {user.name}</DialogTitle>
          </DialogHeader>
          <Form {...notifyUserForm}>
            <form
              onSubmit={notifyUserForm.handleSubmit(onSendNotificationSubmit)}
              className="space-y-3"
            >
              <FormField
                control={notifyUserForm.control}
                name="title"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Title</FormLabel>
                    <FormControl>
                      <Input
                        placeholder="shadcn"
                        type="text"
                        {...field}
                        disabled={isPending}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={notifyUserForm.control}
                name="description"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Description</FormLabel>
                    <FormControl>
                      <Input type="text" {...field} disabled={isPending} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={notifyUserForm.control}
                name="type"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Type</FormLabel>
                    <Select
                      onValueChange={field.onChange}
                      defaultValue={field.value}
                    >
                      <FormControl>
                        <SelectTrigger>
                          <SelectValue placeholder="Select a notification type" />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        {Object.keys(NotificationType).map((e) => (
                          <SelectItem key={e} value={e}>
                            {e}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <Button
                type="submit"
                className="w-full"
                disabled={!form.formState.isDirty}
                loading={loading}
              >
                Notify
              </Button>
            </form>
          </Form>
        </DialogContent>
      </Dialog>
    </>
  );
}
