import Header from "@/components/common/header";
import { ThemeProvider } from "@/components/theme-provider";
import { Toaster } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { sans } from "@/fonts";
import { cn } from "@/lib/utils";
import { Metadata } from "next";
import { ReactNode } from "react";
import "./globals.css";

export const metadata = {
  title: {
    default: "VoiceLearn",
    template: "%s - VoiceLearn",
  },
  metadataBase: new URL("https://voicelearn.tech"),
  description:
    "Talk or chat with our AI to practice new language skills in open conversations. Improve naturally with tailored interactions on our platform",
  keywords: ["voice", "learn voice", "ai", "phantomknight287"],
  openGraph: {
    title: "VoiceLearn",
    description:
      "Talk or chat with our AI to practice new language skills in open conversations. Improve naturally with tailored interactions on our platform",
    images: ["/logo.png"],
    locale: "en_US",
    url: "https://voicelearn.tech",
    type: "website",
  },
  authors: [
    {
      name: "PhantomKnight287",
      url: "https://procrastinator.fyi",
    },
  ],
  creator: "PhantomKnight287",
  twitter: {
    title: "VoiceLearn",
    description:
      "Talk or chat with our AI to practice new language skills in open conversations. Improve naturally with tailored interactions on our platform",
    card: "summary",
    images: ["/logo.png"],
    creator: "gurpalsingh287",
  },
  generator: "Next.js",
  icons: {
    icon: "/logo.png",
  },
} satisfies Metadata;

export default function Layout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body
        className={cn(sans.variable, "font-sans min-h-screen flex flex-col")}
      >
        <ThemeProvider
          attribute="class"
          defaultTheme="light"
          enableSystem
          disableTransitionOnChange
        >
          <TooltipProvider>{children}</TooltipProvider>
          <Toaster />
        </ThemeProvider>
      </body>
    </html>
  );
}
