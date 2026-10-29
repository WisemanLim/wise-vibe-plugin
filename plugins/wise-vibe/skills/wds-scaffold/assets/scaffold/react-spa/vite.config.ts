// {{PROJECT_NAME}} — Vite SPA. /api 는 API_UPSTREAM 으로 프록시한다(동일 출처, CORS 없음).
// local 은 Vite dev server 가, prod 는 nginx 런타임(nginx/default.conf.template)이 같은 역할을 한다.
import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [react(), tailwindcss()],
  server: {
    proxy: { "/api": process.env.API_UPSTREAM ?? "http://127.0.0.1:8080" },
  },
  test: {
    environment: "jsdom",
    globals: true,
    include: ["test/**/*.test.{ts,tsx}"],
    setupFiles: ["test/setup.ts"],
  },
});
