import { getAppStats } from "@/cache/stats";
import { CalSans } from "@/fonts";
import { cn } from "@/lib/utils";
import { ComponentProps } from "react";

export async function ApplicationStats() {
  const stats = await getAppStats();

  return (
    <section className="container flex flex-col gap-6 py-8 md:max-w-[64rem] md:py-12">
      <div className="px-5 py-2 mx-auto container">
        <div className="mx-auto max-w-7xl px-6 lg:px-8">
          <div className="mx-auto max-w-2xl lg:text-center">
            <h2
              className={cn(
                "text-3xl font-semibold leading-7",
                CalSans.className
              )}
            >
              Stats
            </h2>
          </div>
        </div>
      </div>
      <div className="grid gap-5 sm:gap-7 flex-wrap w-full sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-3">
        <div className="bg-border rounded-lg p-5 sm:p-7 w-full flex flex-col gap-2">
          <span className="text-3xl font-bold flex">
            {stats?.users.toLocaleString()}
          </span>
          <span className="text-muted-foreground ">Total Users</span>
        </div>
        <div className="bg-border rounded-lg p-5 sm:p-7 w-full flex flex-col gap-2">
          <span className="text-3xl font-bold flex">
            {stats?.chats.toLocaleString()}
          </span>
          <span className="text-muted-foreground ">Total Chats</span>
        </div>
        <div className="bg-border rounded-lg p-5 sm:p-7 w-full flex flex-col gap-2">
          <span className="text-3xl font-bold flex">
            {stats?.totalMessages.toLocaleString()}
          </span>
          <span className="text-muted-foreground ">Total Messages</span>
        </div>
        <div className="bg-border rounded-lg p-5 sm:p-7 w-full flex flex-col gap-2">
          <span className="text-3xl font-bold flex">
            {stats?.totalLanguages.toLocaleString()}
          </span>
          <span className="text-muted-foreground ">Languages To Learn</span>
        </div>
        <div className="bg-border rounded-lg p-5 sm:p-7 w-full flex flex-col gap-2">
          <span className="text-3xl font-bold flex">
            {stats?.modules.toLocaleString()}
          </span>
          <span className="text-muted-foreground ">Personalised Modules</span>
        </div>
        <div className="bg-border rounded-lg p-5 sm:p-7 w-full flex flex-col gap-2">
          <span className="text-3xl font-bold flex">
            {stats?.lessons.toLocaleString()}
          </span>
          <span className="text-muted-foreground ">Personalised Lessons</span>
        </div>
        <div className="bg-border rounded-lg p-5 sm:p-7 w-full flex flex-col gap-2">
          <span className="text-3xl font-bold flex">
            {stats?.questions.toLocaleString()}
          </span>
          <span className="text-muted-foreground ">Personalised Questions</span>
        </div>
        <div className="bg-border rounded-lg p-5 sm:p-7 w-full flex flex-col gap-2">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-full flex items-center justify-center">
              <img
                src={stats?.mostLearnedLanguage.flagUrl}
                alt={`${stats?.mostLearnedLanguage.name} flag`}
                className="w-8 h-8"
              />
            </div>
            <span className="font-medium">
              {stats?.mostLearnedLanguage.name}
            </span>
          </div>
          <div className="flex items-center gap-2 text-muted-foreground mt-auto">
            <span className="font-medium">Most Learned Language</span>
          </div>
        </div>
        <div className="bg-border rounded-lg p-5 sm:p-7 w-full flex flex-col gap-2">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-full flex items-center justify-center">
              <img
                src={stats?.mostPracticedLanguage.flagUrl}
                alt={`${stats?.mostPracticedLanguage.name} flag`}
                className="w-8 h-8"
              />
            </div>
            <span className="font-medium">
              {stats?.mostPracticedLanguage.name}
            </span>
          </div>
          <div className="flex items-center gap-2 text-muted-foreground mt-auto">
            <span className="font-medium">Most Practiced Language</span>
          </div>
        </div>
      </div>
    </section>
  );
}

