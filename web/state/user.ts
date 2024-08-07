import { create } from "zustand";

export enum Tiers {
  free = "free",
  premium = "premium",
  epic = "epic",
}
export interface UserState {
  user?: {
    id: string;
    email?: string;
    name: string;
    paths: number;
    updatedAt: string;
    createdAt: string;
    token: string;
    lives: number;
    emeralds: number;
    xp: number;
    activeStreaks: number;
    isStreakActive: boolean;
    tiers: Tiers;
    avatarHash: string;
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
