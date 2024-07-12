"use client";

import { useRef, useState } from "react";
import { ChatInfo } from "./types";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Mic, Send, X } from "lucide-react";
import { toast } from "sonner";
import { io as socketio } from "socket.io-client";

import { API_URL } from "@/constants";
import { readCookie } from "@/utils/cookie";
import { useUser } from "@/state/user";
import { useEffectOnce } from "@/hooks/use-effect-once";
import Message from "./components/message";
import { cn } from "@/lib/utils";

export function ChatContainer({ chat }: { chat: ChatInfo }) {
  const [inputMode, setInputMode] = useState<"text" | "audio">("audio");

  const [url, setUrl] = useState("");
  const [message, setMessage] = useState("");

  const [messages, setMessages] = useState<ChatInfo["messages"]>(chat.messages);
  const chunks = useRef<Blob[]>([]);
  const [loading, setLoading] = useState(false);
  const { setTokens, user } = useUser();
  const [io, setIo] = useState<ReturnType<typeof socketio> | undefined>(
    undefined
  );
  const [eolReceived, setEolReceived] = useState(true);
  const [botResponse, setBotResponse] = useState("");
  const [recording, setRecording] = useState(false);
  const [duration, setDuration] = useState(0);
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffectOnce(() => {
    if (!io) {
      const socket = socketio(API_URL, {
        auth: {
          token: readCookie("voice_learn_token"),
        },
        query: {
          chatId: chat.id,
        },
        transports: ["websocket"],
      });
      setIo(socket);
      socket?.on("speech_to_text_error", (error) => {
        setLoading(false);
        toast.error(
          typeof error === "string"
            ? error
            : "Failed to convert speech to text. Please try again."
        );
      });
      socket.on("speech_to_text", (text) => {
        setMessage(text);
        setInputMode("text");
        setLoading(false);
      });
      socket.on("response_stream", (text) => {
        setBotResponse((o) => o + text);
      });
      socket.on("response_stream_end", (message) => {
        setEolReceived(true);
        setMessages((old) => [...old, message]);
        setBotResponse("");
      });
      socket.on("updated_tokens", (tokens) => {
        setTokens(tokens as number);
      });
      socket.on("error", (err) => {
        toast.error(err);
      });
      socket.on("message", (message) => {
        if (message.refId) {
          setMessages((old) =>
            old.map((item) => (item.id === message.refId ? message : item))
          );
        } else {
          setMessages((old) => [...old, message]);
        }
        scrollRef?.current?.scrollIntoView({ behavior: "smooth" });
      });
    }
    return () => {
      console.log(io);
      io?.disconnect();
    };
  }, [io]);

  useEffectOnce(() => {
    scrollRef?.current?.scrollIntoView({ behavior: "smooth" });
  }, [scrollRef?.current]);

  return (
    <>
      <div className={cn("container flex flex-col mb-2 flex-1")}>
        <div className="flex-[0.9] mb-2">
          {messages.length === 0 ? (
            <p className="text-muted-foreground text-center">No Messages</p>
          ) : (
            <div className="flex flex-col space-y-4">
              {messages.map((message) => (
                <Message
                  message={message}
                  key={message.id}
                  voiceName={chat.voice.name}
                />
              ))}
              {eolReceived === false ? (
                <>
                  {botResponse ? (
                    <Message
                      message={{
                        audioUrl: "",
                        author: "Bot",
                        chatId: chat.id,
                        content: botResponse,
                        id: crypto.randomUUID(),
                        tokens: BigInt(2),
                        createdAt: new Date(),
                        updatedAt: new Date(),
                      }}
                      voiceName={chat.voice.name}
                    />
                  ) : (
                    <Message
                      message={{
                        audioUrl: "",
                        author: "Bot",
                        chatId: chat.id,
                        content: "",
                        id: crypto.randomUUID(),
                        tokens: BigInt(2),
                        createdAt: new Date(),
                        updatedAt: new Date(),
                      }}
                      voiceName={chat.voice.name}
                    />
                  )}
                </>
              ) : null}
              <div ref={scrollRef} />
            </div>
          )}
        </div>
        <div className="flex flex-row items-center gap-3 mt-auto">
          {url && inputMode === "audio" ? (
            <video controls className="max-h-10 w-full">
              <source src={url} type="audio/ogg" />
            </video>
          ) : (
            <Input
              placeholder={
                !recording ? "Send a message" : `Recording: ${duration}/10`
              }
              className="rounded-lg"
              value={message}
              disabled={loading || recording || !eolReceived}
              onChange={(e) => {
                if (message.length === 0 && e.target.value.length !== 0) {
                  setInputMode("text");
                } else if (
                  message.length !== 0 &&
                  e.target.value.length === 0
                ) {
                  setInputMode("audio");
                }
                setMessage(e.target.value);
              }}
            />
          )}

          <Button
            loading={loading}
            onClick={() => {
              if (inputMode === "audio" && chunks.current.length === 0) {
                if (
                  navigator.mediaDevices &&
                  navigator.mediaDevices.getUserMedia
                ) {
                  navigator?.mediaDevices
                    ?.getUserMedia({ audio: true, video: false })
                    .then((stream) => {
                      const recorder = new MediaRecorder(stream);
                      recorder.start();
                      setRecording(true);

                      recorder.ondataavailable = (e) => {
                        let data = [...chunks.current];
                        data.push(e.data);
                        chunks.current = data;
                      };
                      recorder.onstop = (e) => {
                        const blob = new Blob(chunks.current, {
                          type: "audio/ogg; codecs=opus",
                        });
                        const audioUrl = window.URL.createObjectURL(blob);
                        setUrl(audioUrl);
                        stream.getTracks().forEach((track) => track.stop());
                      };
                      const timer = setInterval(() => {
                        setDuration((o) => o + 1);
                      }, 1000);
                      setTimeout(() => {
                        clearInterval(timer);
                        setRecording(false);
                        recorder?.stop();
                      }, 11000);
                    })
                    .catch(console.error);
                } else {
                  toast.error("Recording Audio not supported by your browser.");
                }
              } else if (inputMode === "audio" && chunks.current.length) {
                io?.emit(
                  "speech_to_text",
                  new Blob(chunks.current, {
                    type: "audio/ogg; codecs=opus",
                  })
                );
                setLoading(true);
              } else if (inputMode === "text" && message.length) {
                const id = crypto.randomUUID();
                const payload: Record<string, any> = {
                  message,
                  refId: id,
                };
                if (chunks.current.length) {
                  payload["blob"] = new Blob(chunks.current, {
                    type: "audio/ogg; codecs=opus",
                  });
                }
                io?.emit("text_message", payload);
                setEolReceived(false);
                if (user?.tokens && parseInt(user.tokens) > 0) {
                  setMessages((old) => [
                    ...old,
                    {
                      audioUrl: "",
                      author: "User",
                      chatId: chat.id,
                      content: message,
                      createdAt: new Date(),
                      id,
                      tokens: BigInt(2),
                      updatedAt: new Date(),
                    },
                  ]);
                }
                setMessage("");
                setUrl("");
                setInputMode("audio");
                chunks.current = [];
                setRecording(false);
                setDuration(0);
              }
            }}
          >
            {inputMode === "audio" ? (
              <>{!url ? <Mic /> : <Send />}</>
            ) : (
              <Send />
            )}
          </Button>
          {url && inputMode === "audio" ? (
            <Button
              variant={"outline"}
              disabled={loading}
              onClick={() => {
                chunks.current = [];
                setInputMode("audio");
                setUrl("");
              }}
            >
              <X className="text-red-500" />
            </Button>
          ) : null}
        </div>
      </div>
    </>
  );
}
