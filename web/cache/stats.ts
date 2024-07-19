import { API_URL } from "@/constants";
import { unstable_cache as cache } from "next/cache";
export type Root = {
  users: number;
  chats: number;
  totalLanguages: number;
  totalMessages: number;
  mostPracticedLanguage: {
    id: string;
    name: string;
    flagUrl: string;
  };
  mostLearnedLanguage: {
    id: string;
    name: string;
    flagUrl: string;
  };
  modules: number;
  lessons: number;
  questions: number;
};

export async function getAppStats(): Promise<Root | null> {
  try {
    return await cache(
      async () => {
        const response = await fetch(`${API_URL}/`, {
          headers: {
            Accept: "application/json",
          },
          next: {
            revalidate: 60,
          },
        });

        if (!response.ok) {
          return null;
        }

        const data = (await response.json()) as Root;

        return data;
      },
      ["app-stats"],
      {
        revalidate: 900,
        tags: ["app-stats"],
      }
    )();
  } catch (err) {
    console.error(err);
    return null;
  }
}
