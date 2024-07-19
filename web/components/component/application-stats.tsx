import { getAppStats } from "@/cache/stats";
import { ComponentProps } from "react";

export async function ApplicationStats() {
  const stats = await getAppStats();
  const numberFormatter = new Intl.NumberFormat("en-US", {});
  return (
    <section className="container flex flex-col gap-6 py-8 md:max-w-[64rem] md:py-12 min-h-screen ">
      <div className="px-5 py-2 mx-auto container">
        <div className="mx-auto max-w-7xl px-6 lg:px-8">
          <div className="mx-auto max-w-2xl lg:text-center">
            <h2 className="text-3xl font-semibold leading-7 ">Stats</h2>
          </div>
        </div>
      </div>
      <div className="grid gap-5 sm:gap-7 flex-wrap w-full sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-3">
        <div className="bg-secondary rounded-lg p-5 sm:p-7 w-full flex flex-col gap-2">
          <span className="text-3xl font-bold flex">
            {stats?.users.toLocaleString()}
          </span>
          <span className="text-muted-foreground ">Total Users</span>
        </div>
        <div className="bg-secondary rounded-lg p-5 sm:p-7 w-full flex flex-col gap-2">
          <span className="text-3xl font-bold flex">
            {stats?.chats.toLocaleString()}
          </span>
          <span className="text-muted-foreground ">Total Chats</span>
        </div>
        <div className="bg-secondary rounded-lg p-5 sm:p-7 w-full flex flex-col gap-2">
          <span className="text-3xl font-bold flex">
            {stats?.totalMessages.toLocaleString()}
          </span>
          <span className="text-muted-foreground ">Total Messages</span>
        </div>
        <div className="bg-secondary rounded-lg p-5 sm:p-7 w-full flex flex-col gap-2">
          <span className="text-3xl font-bold flex">
            {stats?.totalLanguages.toLocaleString()}
          </span>
          <span className="text-muted-foreground ">Languages To Learn</span>
        </div>
        <div className="bg-secondary rounded-lg p-5 sm:p-7 w-full flex flex-col gap-2">
          <span className="text-3xl font-bold flex">
            {stats?.modules.toLocaleString()}
          </span>
          <span className="text-muted-foreground ">Personalised Modules</span>
        </div>
        <div className="bg-secondary rounded-lg p-5 sm:p-7 w-full flex flex-col gap-2">
          <span className="text-3xl font-bold flex">
            {stats?.lessons.toLocaleString()}
          </span>
          <span className="text-muted-foreground ">Personalised Lessons</span>
        </div>
        <div className="bg-secondary rounded-lg p-5 sm:p-7 w-full flex flex-col gap-2">
          <span className="text-3xl font-bold flex">
            {stats?.questions.toLocaleString()}
          </span>
          <span className="text-muted-foreground ">Personalised Questions</span>
        </div>
        <div className="bg-secondary rounded-lg p-5 sm:p-7 w-full flex flex-col gap-2">
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
            <LanguagesIcon className="w-5 h-5" />
            <span className="font-medium">Most Learned Language</span>
          </div>
        </div>
        <div className="bg-secondary rounded-lg p-5 sm:p-7 w-full flex flex-col gap-2">
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
            <LanguagesIcon className="w-5 h-5" />
            <span className="font-medium">Most Practiced Language</span>
          </div>
        </div>
      </div>
    </section>
  );
}

function LanguagesIcon(props: ComponentProps<"svg">) {
  return (
    <svg
      {...props}
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d="m5 8 6 6" />
      <path d="m4 14 6-6 2-3" />
      <path d="M2 5h12" />
      <path d="M7 2h1" />
      <path d="m22 22-5-10-5 10" />
      <path d="M14 18h6" />
    </svg>
  );
}
