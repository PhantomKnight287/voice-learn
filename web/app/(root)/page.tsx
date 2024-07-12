import Script from "next/script";
import { Features } from "./_components/features";
import HowItWorks from "./_components/how-it-works";

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
            <div className="flex flex-col gap-2 min-[400px]:flex-row">
              <a
                className="inline-flex h-10 items-center justify-center rounded-md bg-gray-900 px-8 text-sm font-medium text-gray-50 shadow transition-colors hover:bg-gray-900/90 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-gray-950 disabled:pointer-events-none disabled:opacity-50 dark:bg-gray-50 dark:text-gray-900 dark:hover:bg-gray-50/90 dark:focus-visible:ring-gray-300 z-[69]"
                href="#waitlist"
              >
                Join Waitlist
              </a>
            </div>
          </div>
        </section>
      </div>
      <Features />
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
