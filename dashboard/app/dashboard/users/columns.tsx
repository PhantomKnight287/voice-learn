"use client";

import { ColumnDef } from "@tanstack/react-table";
import Link from "next/link";

export const columns: ColumnDef<{
  id: string;
  name: string;
  email: string;
  emeralds: number;
  lives: number;
  xp: number;
  avatar: string;
  avatarHash: string;
  activeStreaks: number;
  tier: string;
  timezone: string;
  timeZoneOffSet: number;
  createdAt: Date;
  _count: {};
}>[] = [
  {
    accessorKey: "name",
    header: "Name",
    cell(props) {
      return (
        <Link
          className="underline"
          href={`/dashboard/users/${props.row.original.id}`}
        >
          {props.row.original.name}
        </Link>
      );
    },
  },

  {
    accessorKey: "email",
    header: "Email",
  },
  {
    accessorKey: "emeralds",
    header: "Emeralds",
  },
  {
    accessorKey: "tier",
    header: "Tier",
  },
  {
    accessorKey: "timezone",
    header: "Timezone",
  },
];
