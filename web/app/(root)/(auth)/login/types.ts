import { UserState } from "@/state/user";

export type LoginResponse = {
  user: Exclude<UserState["user"], undefined>;
  token: string;
};

export interface LoginBody {
  email: string;
  password: string;
  timezone: string;
  timeZoneOffset: string;
}
