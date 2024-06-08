FROM node:20-alpine

WORKDIR /app

COPY package.json pnpm-lock.yaml ./prisma ./

RUN corepack enable && pnpm install

COPY . .

RUN pnpm build

CMD [ "pnpm", "start:prod"]