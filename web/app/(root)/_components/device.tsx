import { cn } from "@/lib/utils";
import { DetailedHTMLProps, ImgHTMLAttributes } from "react";
export default function DeviceFrame({
  deviceClassName,
  ...props
}: DetailedHTMLProps<ImgHTMLAttributes<HTMLImageElement>, HTMLImageElement> & {
  deviceClassName?: string;
}) {
  return (
    <div
      className={cn("device device-iphone-14-pro relative", deviceClassName)}
    >
      <div className="device-frame">
        <img {...props} className={cn(props.className, "device-screen")} />
      </div>
      <div className="device-header"></div>
      <div className="device-btns"></div>
      <div className="device-stripe"></div>
      <div className="device-sensors"></div>
      <div className="device-power"></div>
      <div className="device-home"></div>
    </div>
  );
}
