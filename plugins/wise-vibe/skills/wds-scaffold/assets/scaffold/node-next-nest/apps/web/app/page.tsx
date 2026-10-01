import { apiBase } from '../lib/api';

export const dynamic = 'force-dynamic';

export default async function Home() {
  let health = 'unreachable';
  try {
    const res = await fetch(`${apiBase()}/health`, { cache: 'no-store' });
    health = JSON.stringify(await res.json());
  } catch {}
  return (
    <main style={{ padding: 32, fontFamily: 'system-ui' }}>
      <h1>{{PROJECT_NAME}}</h1>
      <p>api /health: <code>{health}</code></p>
    </main>
  );
}
