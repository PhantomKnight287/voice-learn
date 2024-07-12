import { buttonVariants } from "@/components/ui/button";

export default function InteractiveHeaderComponents() {
  return (
    <a href="#waitlist" className={buttonVariants({ variant: "default" })}>
      Join Waitlist
    </a>
  );
}
