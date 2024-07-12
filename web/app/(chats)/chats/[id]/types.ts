interface ok {}

export interface ChatInfo extends ok {
  messages: ({} & { textState?: "loading" | "present" })[];
  voice: { name: string };
}
