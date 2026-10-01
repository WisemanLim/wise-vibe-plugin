// 서버 측 API 베이스 (compose 내부: http://api:4000)
export const apiBase = (env: Record<string, string | undefined> = process.env) =>
  env.API_BASE ?? 'http://api:4000';
