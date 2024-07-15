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
    ],
  },
  typescript: { ignoreBuildErrors: true },
  pageExtensions: ["js", "jsx", "ts", "tsx", "mdx"],
  async redirects() {
    return [
      {
        source: "/",
        destination: REDIRECTS.DASHBOARD,
        has: [
          {
            type: "cookie",
            key: COOKIE_NAME,
          },
        ],
        permanent: true,
      },
    ];
  },
};

export default withMDX(nextConfig);
