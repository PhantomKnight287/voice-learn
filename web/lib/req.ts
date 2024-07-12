import { API_URL } from "@/constants";
import { ApiError } from "@/types/error";

type RequestType =
  | "GET"
  | "PUT"
  | "DELETE"
  | "OPTIONS"
  | "HEAD"
  | "CONNECT"
  | "TRACE";

export type ResponseBody<U> =
  | {
      failed: true;
      error: ApiError;
    }
  | { failed: false; data: U };

export async function makeRequest<U, T>(
  path: string,
  body: Omit<RequestInit, "body" | "method"> & {
    body: U;
    method: U extends undefined ? RequestType : "POST" | "PATCH";
  }
): Promise<ResponseBody<T>> {
  const req = await fetch(`${API_URL}${path}`, {
    ...body,
    body:
      body.body instanceof FormData
        ? (body.body as any)
        : JSON.stringify(body.body),
    headers:
      body.body instanceof FormData
        ? body.headers
        : {
            "Content-Type": "application/json",
            ...body.headers,
          },
  });
  if (!req.ok) {
    return {
      failed: true,
      error: (await req.json()) as ApiError,
    };
  } else {
    return {
      failed: false,
      data: (await req.json()) as T,
    };
  }
}
