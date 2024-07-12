export interface VerifyMagicLinkBody {
  token: string;
}

export interface VerifyMagicLinkResponse {
  user: {
    id: string;
    name: string;
    tokens: number;
  };
  token: string;
}
