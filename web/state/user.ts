import { create } from "zustand";

export interface UserState {
  user?: {
    id: string;
    name: string;
    tokens: string;
  };
  setUser: (user: UserState["user"]) => void;
  logOut: () => void;
  setTokens: (tokens: number) => void;
}

export const useUser = create<UserState>((set) => ({
  user: undefined,
  setUser(user) {
    set((old) => ({ user: user }));
  },
  setTokens(tokens) {
    //@ts-expect-error
    set((old) => ({ user: { ...old.user, tokens } }));
  },
  logOut() {
    set({ user: undefined });
  },
}));
