export default function HowItWorks() {
  return (
    <div className="mx-8 flex flex-col items-center justify-center">
      <div className="container px-5 py-24 mx-auto">
        <h2
          id="how-it-works"
          className="text-3xl font-semibold leading-7 text-left lg:text-center  mb-20   "
        >
          How It Works
        </h2>
        <ol className="relative border-l border-gray-200 dark:border-gray-700  mt-16 max-w-2xl sm:mt-20 lg:mt-24 lg:max-w-4xl mx-0 md:mx-auto">
          <li className="mb-10 ml-6">
            <div className="absolute w-3 h-3 bg-gray-600 rounded-full mt-1.5 -left-1.5 border border-white/50 " />
            <h3 className="flex items-center mb-1 text-lg font-semibold text-gray-900 dark:text-white">
              Create a new Chat
            </h3>
            <p className="mb-4 text-base font-normal text-gray-500 dark:text-gray-400">
              Users start by creating a chat session on the website, initiating
              an interactive language practice experience.
            </p>
          </li>
          <li className="mb-10 ml-6">
            <div className="absolute w-3 h-3 bg-gray-600 rounded-full mt-1.5 -left-1.5 border border-white/50 " />
            <h3 className="mb-1 text-lg font-semibold text-gray-900 dark:text-white">
              Talk or Text with AI
            </h3>
            <p className="text-base font-normal text-gray-500 dark:text-gray-400">
              Users can choose to either speak to the AI using voice input,
              allowing for voice-to-text conversion, or type messages directly
              for text-based interaction.
            </p>
          </li>
          <li className="ml-6">
            <div className="absolute w-3 h-3 bg-gray-600 rounded-full mt-1.5 -left-1.5 border border-white/50 " />
            <h3 className="mb-1 text-lg font-semibold text-gray-900 dark:text-white">
              Receive AI Responses
            </h3>
            <p className="text-base font-normal text-gray-500 dark:text-gray-400">
              The AI processes user input and generates responses, engaging in
              meaningful conversations to help users practice and improve their
              language skills.
            </p>
          </li>
        </ol>
      </div>
    </div>
  );
}
