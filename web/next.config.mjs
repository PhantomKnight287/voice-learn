import createMDX from "fumadocs-mdx/config";
import { REDIRECTS, COOKIE_NAME } from "./redirects.mjs";

const withMDX = createMDX();
/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "api.dicebear.com",
        pathname: "/8.x/initials/**",
        port: "",
      },
      {
        protocol: "https",
        hostname: "cdn.voicelearn.tech",
        pathname: "/**",
        port: "",
      },
    ],
  },
  typescript: { ignoreBuildErrors: true },
  pageExtensions: ["js", "jsx", "ts", "tsx", "mdx"],
};

export default withMDX(nextConfig);
