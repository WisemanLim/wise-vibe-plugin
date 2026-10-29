// E2E 는 순번 1(전 화면 골격) 이후 활성화. 브라우저 설치: pnpm exec playwright install firefox
import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "e2e",
  use: { baseURL: process.env.WEB_URL ?? "http://127.0.0.1:{{APP_PORT}}" },
});
