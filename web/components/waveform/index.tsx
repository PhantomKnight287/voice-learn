import { useEffectOnce } from "@/hooks/use-effect-once";
import { Pause, Play } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import WaveSurfer from "wavesurfer.js";
import "wave-audio-path-player";

const Waveform = ({ audio }: { audio: string }) => {
  const containerRef = useRef<HTMLDivElement>(null);

  const waveSurferRef = useRef<WaveSurfer>();
  const [playing, setPlaying] = useState(false);

  useEffectOnce(() => {
    if (containerRef.current) {
      if (window.innerWidth <= 950) {
        const audioElement = document.createElement("audio");
        audioElement.src = audio;
        audioElement.className = "w-full mb-2";
        audioElement.controls = true;
        containerRef.current.appendChild(audioElement);
      } else {
        containerRef.current.innerHTML = `<wave-audio-path-player 
        src="${audio}"
        wave-width="200" 
        wave-height="40" 
        wave-options='{"samples": 100, "type": "steps", "paths": [ 
          {"d":"L", "sx": 0, "sy":0, "ex":50, "ey":100 },
          {"d":"L", "sx": 50, "sy":100, "ex":100, "ey":0 }
        ]}'>
        </wave-audio-path-player>`;
      }
    }
  }, [containerRef?.current]);

  // useEffectOnce(() => {
  //   if (containerRef.current) {
  //     const waveSurfer = WaveSurfer.create({
  //       container: containerRef.current!,
  //       barHeight: 0.5,
  //       cursorColor: "green",
  //       hideScrollbar: true,
  //       progressColor: "#3b82f6",
  //       autoScroll: true,
  //       height: 30,
  //       barWidth: 2,
  //       // Optionally, specify the spacing between bars
  //       barGap: 1,
  //       // And the bar radius
  //       barRadius: 0,
  //       plugins: [
  //         HoverPlugin.create({
  //           lineColor: "#ff0000",
  //           lineWidth: 2,
  //           labelBackground: "#555",
  //           labelColor: "#fff",
  //           labelSize: "11px",
  //         }),
  //       ],
  //     });

  //     waveSurfer.load(
  //       audio.startsWith("/") ? `${API_URL}/audio${audio}` : audio
  //     );
  //     waveSurfer.on("finish", () => {
  //       setPlaying(false);
  //     });
  //     waveSurfer.on("ready", () => {
  //       waveSurferRef.current = waveSurfer;
  //     });
  //   }

  //   return () => {
  //     waveSurferRef?.current?.destroy();
  //   };
  // }, [audio, containerRef.current]);

  return <div className="w-full" ref={containerRef}></div>;

  return (
    <div className="flex flex-row items-center w-full">
      <button
        onClick={() => {
          waveSurferRef.current?.playPause();
          setPlaying(waveSurferRef.current?.isPlaying() || false);
        }}
        type="button"
        className="bg-blue-400 rounded-lg p-2 mr-2"
      >
        {playing ? <Pause /> : <Play />}
      </button>
      <div ref={containerRef} className="w-full" />
    </div>
  );
};

export default Waveform;
