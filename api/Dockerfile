# Stage 1: Build
FROM node:20-alpine AS builder

ARG DATABASE_URL

ENV DATABASE_URL=${DATABASE_URL}

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

# Set the working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package.json pnpm-lock.yaml ./
COPY ./prisma ./

# Install dependencies
RUN corepack enable && pnpm install

# Copy the rest of the application code
COPY . .

# Build the application (if applicable)
RUN pnpm build

# Stage 2: Production
FROM node:20-alpine

# Set the working directory
WORKDIR /app

# Copy only the necessary files from the build stage
COPY --from=builder /app/package.json /app/pnpm-lock.yaml ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist

# Expose the port the app runs on
EXPOSE 3000

# Command to run the application
CMD ["node", "dist/index.js"]
