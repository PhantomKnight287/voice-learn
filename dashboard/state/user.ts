import { create } from "zustand";

export interface User {
  id: string;
  name: string;
}

export const useUser = create<{
  user: User;
  setUser: (user: User) => void;
  logOut: () => void;
}>((set) => ({
  user: { id: "", name: "" },
  logOut() {
    set((old) => ({ ...old, user: { id: "", name: "" } }));
  },
  setUser(user) {
    set((old) => ({ ...old, user }));
  },
}));
