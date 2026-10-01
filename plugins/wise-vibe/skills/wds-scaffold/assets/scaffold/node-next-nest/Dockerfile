# {{PROJECT_NAME}} — node-next-nest (pnpm workspace · dev = local 모드, runtime-* = prod 모드)
FROM node:22-slim AS base
ENV PNPM_HOME=/pnpm PATH=/pnpm:$PATH NEXT_TELEMETRY_DISABLED=1
RUN corepack enable
WORKDIR /app

FROM base AS dev
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml* ./
COPY apps/api/package.json apps/api/
COPY apps/web/package.json apps/web/
RUN pnpm install --no-frozen-lockfile
COPY . .
EXPOSE 3000 4000
CMD ["pnpm", "--filter", "./apps/api", "dev"]

FROM dev AS build
RUN pnpm -r build

FROM base AS runtime-api
COPY --from=build --chown=node:node /app /app
USER node
WORKDIR /app/apps/api
EXPOSE 4000
CMD ["node", "dist/main.js"]

FROM base AS runtime-web
COPY --from=build --chown=node:node /app /app
USER node
WORKDIR /app/apps/web
EXPOSE 3000
CMD ["node", "node_modules/next/dist/bin/next", "start", "-H", "0.0.0.0", "-p", "3000"]
