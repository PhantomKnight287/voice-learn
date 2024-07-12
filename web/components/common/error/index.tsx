export default function ErrorMessage({
  message = "An Error Occurred",
}: {
  message?: string;
}) {
  return (
    <div className="container flex items-center justify-center">
      <p className="text-red-400">{message}</p>
    </div>
  );
}
