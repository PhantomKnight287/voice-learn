# Stage 1: Build environment
FROM node:18-alpine AS builder

# Install corepack
RUN apk add --no-cache corepack

# Enable pnpm
RUN corepack enable pnpm

# Set working directory
WORKDIR /app

# Copy package.json and pnpm-lock.yaml
COPY package.json pnpm-lock.yaml ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy the rest of the application code
COPY . .

# Build the Next.js app
RUN pnpm run build

# Stage 2: Production environment
FROM node:18-alpine AS runner

# Install corepack
RUN apk add --no-cache corepack

# Enable pnpm
RUN corepack enable pnpm

# Set working directory
WORKDIR /app

# Copy built assets from the builder stage
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/public ./public

# Set environment variables
ENV NODE_ENV production

# Expose the listening port
EXPOSE 3000

# Run the application
CMD ["pnpm", "start"]