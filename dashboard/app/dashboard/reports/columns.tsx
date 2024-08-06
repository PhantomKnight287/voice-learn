"use client";

import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";
import { ColumnDef } from "@tanstack/react-table";
import Link from "next/link";

export const columns: ColumnDef<{
  question: {
    id: string;
  };
  id: string;
  title: string;
  content: string;
  status: "pending" | "approved" | "rejected";
  createdAt: Date;
  author: {
    id: string;
    name: string;
  };
}>[] = [
  {
    accessorKey: "title",
    header: "Title",
    cell(props) {
      const row = props.row;
      return (
        <Link
          href={`/dashboard/reports/${row.original.id}`}
          className="underline"
        >
          {row.original.title}
        </Link>
      );
    },
  },
  {
    accessorKey: "content",
    header: "Content",
  },
  {
    accessorKey: "status",
    header: "Status",
    cell(props) {
      const variant = props.row.original.status;
      return (
        <Badge
          variant={"outline"}
          className={cn("capitalize", {
            "bg-yellow-500": variant === "pending",
            "bg-red-500": variant === "rejected",
            "bg-green-500": variant === "approved",
          })}
        >
          {props.renderValue() as string}
        </Badge>
      );
    },
  },
  {
    accessorFn: (row) => row.author.name,
    header: "Author",
    cell(props) {
      return (
        <Link
          href={`/dashboard/users/${props.row.original.author.id}`}
          className="underline"
        >
          {props.row.original.author.name}
        </Link>
      );
    },
  },
  {
    accessorFn: (row) => row.question.id,
    header: "Question",
    cell(props) {
      return (
        <Link
          href={`/dashboard/questions/${props.row.original.question.id}`}
          className="underline"
        >
          {props.row.original.question.id}
        </Link>
      );
    },
  },
];
