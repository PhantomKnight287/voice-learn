FROM node:20-alpine

WORKDIR /app

ENV DATABASE_URL=postgres://postgres:postgres@voice_learn_postgres/postgres

COPY package.json pnpm-lock.yaml ./prisma ./

RUN corepack enable && pnpm install

COPY . .

RUN chmod +x ./run-server.sh

RUN pnpm build

CMD [ "sh", "./run-server.sh"]