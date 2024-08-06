import { Bell, CircleAlert, Home, Key, KeyRound, User } from "lucide-react";
export const LINKS = [
  {
    href: "",
    icon: <Home className="h-4 w-4" />,
    label: "Dashboard",
  },
  {
    href: "/users",
    label: "Users",
    icon: <User className="h-4 w-4" />,
  },
  {
    href: "/reports",
    label: "Reports",
    icon: <CircleAlert className="h-4 w-4" />,
  },
];
