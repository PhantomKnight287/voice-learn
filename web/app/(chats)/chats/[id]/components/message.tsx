"use client";

import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { Pause, Play } from "lucide-react";
import { useEffect, useRef, useState } from "react";

function Message({ message, voiceName }: { message: any; voiceName: string }) {
  const audioRef = useRef<HTMLAudioElement>(null);
  const [playing, setPlaying] = useState(false);

  return (
    <>
      <div
        className={cn(
          "flex w-max max-w-[75%] flex-col gap-2 rounded-lg px-3 py-2 text-sm bg-muted items-center",
          {
            "ml-auto bg-primary text-primary-foreground rounded-br-none":
              message.author === "User",
            "rounded-bl-none": message.author === "Bot",
            "flex-row": message.author === "User",
            "flex-row-reverse": message.author === "Bot",
          }
        )}
      >
        {message.content.length ? (
          message.content
        ) : (
          <>
            <div className="h-2 w-2 bg-white rounded-full animate-bounce [animation-delay:-0.2s]"></div>
            <div className="h-2 w-2 bg-white rounded-full animate-bounce [animation-delay:-0.15s]"></div>
            <div className="h-2 w-2 bg-white rounded-full animate-bounce"></div>
          </>
        )}

        {message.audioUrl ? (
          <Button
            onClick={() => {
              setPlaying((old) => {
                if (old === true) {
                  audioRef.current?.pause();
                  return false;
                } else {
                  audioRef.current?.play();
                  return true;
                }
              });
            }}
            variant={"outline"}
            className={cn({
              "text-white": message.author === "User",
            })}
          >
            {playing ? <Pause /> : <Play />}
          </Button>
        ) : null}
      </div>
      {message.audioUrl ? (
        <audio
          ref={audioRef}
          className="hidden"
          src={message.audioUrl}
          onEnded={() => {
            setPlaying(false);
          }}
        ></audio>
      ) : null}
    </>
  );
}

export default Message;
