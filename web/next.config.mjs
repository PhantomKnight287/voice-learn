import createMDX from 'fumadocs-mdx/config';
 
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
  pageExtensions:[
    "js",
    "jsx",
    "ts",
    "tsx",
    "mdx"
  ],
};

export default withMDX(nextConfig);
