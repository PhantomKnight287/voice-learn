import { Button } from "@/components/ui/button";
import { ApiKey } from "@notify/db";
import { Loader2, TrashIcon } from "lucide-react";
import { useState } from "react";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";

export default function DeleteKey({ apiKey }: { apiKey: ApiKey }) {
  const [loading, setLoading] = useState(false);
  const [open, setOpen] = useState(false);
  return (
    <>
      <Button
        variant={"ghost"}
        disabled={loading}
        aria-disabled={loading}
        onClick={() => {
          if (loading) return;
          setOpen(true);
        }}
      >
        {loading ? (
          <Loader2 className="animate-spin" />
        ) : (
          <TrashIcon className="text-red-500" />
        )}
      </Button>
      <AlertDialog open={open} onOpenChange={() => setOpen(false)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Are you absolutely sure?</AlertDialogTitle>
            <AlertDialogDescription>
              This action cannot be undone. This will permanently delete your
              API key and it will no longer be functional.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => {
                setLoading(true);
              }}
            >
              Continue
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
