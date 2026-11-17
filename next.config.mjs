/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // Lint is checked separately; don't fail production builds on lint nits.
  eslint: { ignoreDuringBuilds: true },
  // In Next 14 the external-packages list lives under `experimental`
  // (it became top-level `serverExternalPackages` only in Next 15).
  // These packages ship native binaries / large ESM modules and must not be
  // bundled by webpack — they are require()'d at runtime instead.
  experimental: {
    serverComponentsExternalPackages: [
      "@lancedb/lancedb",
      "@huggingface/transformers",
      "onnxruntime-node",
      "sharp",
    ],
  },
};

export default nextConfig;
