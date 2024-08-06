"use client";

import { ArrowLeft } from "lucide-react";
import { useRouter } from "next/navigation";

export default function Back() {
  const { back } = useRouter();

  return (
    <button onClick={back}>
      <ArrowLeft />
    </button>
  );
}
