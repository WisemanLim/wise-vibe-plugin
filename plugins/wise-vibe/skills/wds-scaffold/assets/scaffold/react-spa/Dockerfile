# {{PROJECT_NAME}} — React SPA (multi-stage: dev = local 모드, runtime = prod 모드)
FROM node:24-alpine AS base
RUN npm install -g pnpm@11.3.0
WORKDIR /app

# dev: Vite dev server(HMR), 소스는 local 모드에서 바인드 마운트
FROM base AS dev
COPY package.json pnpm-lock.yaml* ./
# lock 이 커밋되면 재현 설치, 최초 scaffold 직후(lock 없음)에는 해석 후 생성
RUN if [ -f pnpm-lock.yaml ]; then pnpm install --frozen-lockfile; else pnpm install; fi
COPY . .
EXPOSE 8080
CMD ["pnpm", "dev"]

FROM dev AS build
RUN pnpm build

# runtime: 비root nginx 가 정적 파일을 서빙하고 /api 를 API_UPSTREAM 으로 프록시(동일 출처)
FROM nginxinc/nginx-unprivileged:1.28-alpine AS runtime
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 8080
