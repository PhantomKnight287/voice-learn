"use client";
import { PUBLIC_CDN_URL } from "@/constants";
import Rive from "@rive-app/react-canvas";

function FlagAnimation() {
  return <Rive src={`${PUBLIC_CDN_URL}/flags.riv`} className="size-[500px]" />;
}

export default FlagAnimation;
