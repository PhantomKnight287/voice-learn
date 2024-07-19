import Script from "next/script";
import { Features } from "./_components/features";
import HowItWorks from "./_components/how-it-works";
import FlagAnimation from "./flag.animation";
import { buttonVariants } from "@/components/ui/button";
import { ApplicationStats } from "@/components/component/application-stats";

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
        <section className="w-full py-32 xl:py-32 ">
          <div className="container flex flex-col items-center gap-4 px-4 md:px-6">
            <div className="flex flex-col items-center space-y-2 text-center ">
              <Gradient className="top-[-500px] opacity-[0.15] w-[1000px] h-[1000px] bg-gradient-to-t from-blue-500 z-0" />
              <h1 className="text-3xl font-bold tracking-tighter sm:text-5xl z-10">
                Unlock Your Language Potential
              </h1>
              <p className="max-w-[600px] text-gray-500 md:text-xl dark:text-gray-400 z-10">
                Converse with our AI assistant and take your communication
                skills to new heights.
              </p>
            </div>
            <div className="flex flex-col gap-2 min-[400px]:flex-row z-10">
              <a className={buttonVariants()} href="#waitlist">
                Get Started
              </a>
            </div>
          </div>
        </section>
      </div>
      {/* <FlagAnimation /> */}
      <Features />
      <ApplicationStats />
      <HowItWorks />
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
