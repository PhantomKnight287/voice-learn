import Script from "next/script";
import { Features } from "./_components/features";
import { ApplicationStats } from "@/components/component/application-stats";
import { cn } from "@/lib/utils";
import { CalSans } from "@/fonts";
import VoiceLearnLogo_Light from "@/components/icons/light";
import VoiceLearnLogo_Dark from "@/components/icons/dark";
import DeviceFrame from "./_components/device";

function Gradient({
  conic,
  className,
  small,
}: {
  small?: boolean;
  conic?: boolean;
  className?: string;
}): JSX.Element {
  return (
    <span
      className={`absolute mix-blend-normal will-change-[filter] rounded-[100%] ${
        small ? "blur-[32px]" : "blur-[75px]"
      } ${conic ? "bg-glow-conic" : ""} ${className}`}
    />
  );
}

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-between lg:p-24 overflow-x-hidden">
      <div className="relative flex place-items-center">
        <section className="w-full pt-44 xl:py-32 ">
          <div className="container flex flex-col items-center gap-4 px-4 md:px-6">
            <div className="flex flex-col items-center space-y-2 text-center ">
              <div className="bg-primary p-2 rounded-md">
                <VoiceLearnLogo_Light
                  width={80}
                  height={80}
                  className="hidden dark:block"
                />
                <VoiceLearnLogo_Dark
                  width={80}
                  height={80}
                  className="dark:hidden block"
                />
              </div>

              <h1
                className={cn(
                  "text-3xl font-bold tracking-wide sm:text-5xl z-10",
                  CalSans.className
                )}
              >
                The app to practice any language, <br />
                the fun way
              </h1>
            </div>
          </div>
        </section>
      </div>
      <div className="flex flex-row flex-nowrap overflow-hidden mt-10 gap-10">
        <DeviceFrame
          src="https://cdn.voicelearn.tech/IMG_0013.PNG"
          deviceClassName="mt-30"
        />
        <DeviceFrame
          src="https://cdn.voicelearn.tech/IMG_0012.PNG"
          deviceClassName="mt-20"
        />
        <DeviceFrame src="https://cdn.voicelearn.tech/IMG_0011.PNG" />
        <DeviceFrame
          src="https://cdn.voicelearn.tech/IMG_0022.PNG"
          deviceClassName="mt-20"
        />
        <DeviceFrame
          src="https://cdn.voicelearn.tech/IMG_0023.PNG"
          deviceClassName="mt-30"
        />
      </div>

      <Features />
      <ApplicationStats />
      <div className="mx-8 flex flex-col items-center justify-center">
        <div className="container px-5 py-24 mx-auto">
          <h2
            id="waitlist"
            className="text-3xl font-semibold leading-7 text-left lg:text-center  mb-2"
          >
            Join Waitlist
          </h2>
          <p className="text-muted-foreground mb-10">
            Voice Learn is going under heavy revamp to meet your needs better.
            Sign up for the waitlist. We appreciate your patience.
          </p>

          <div
            id="getWaitlistContainer"
            data-waitlist_id="17098"
            data-widget_type="WIDGET_1"
          ></div>
          <link
            rel="stylesheet"
            type="text/css"
            href="https://prod-waitlist-widget.s3.us-east-2.amazonaws.com/getwaitlist.min.css"
          />
          <Script src="https://prod-waitlist-widget.s3.us-east-2.amazonaws.com/getwaitlist.min.js"></Script>
        </div>
      </div>
    </main>
  );
}
