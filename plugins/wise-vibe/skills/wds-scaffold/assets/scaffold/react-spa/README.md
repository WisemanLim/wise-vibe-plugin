# {{PROJECT_NAME}}

> 생성: `wise-vibe` 플러그인 `wds-scaffold` · 프로파일 `react-spa` — {{PROFILE_TITLE}}
> English: [README.en.md](README.en.md)

DB 는 없다. 모든 데이터는 API(`/api`)를 거친다 — 화면 전용 업무 로직을 두지 않는다.

## 실행 모델

| 모드 | compose 파일 | env 파일 | 서버 | 이미지 스테이지 |
|------|--------------|----------|------|----------------|
| local | `docker-compose.yml` + `docker-compose.local.yml` | `.env.local` (커밋) | Vite dev server (HMR) | `dev` (소스 바인드) |
| prod | `docker-compose.yml` + `docker-compose.prod.yml` | `.env.prod` (비커밋) | nginx 비root, 읽기 전용 FS | `runtime` |

`/api` 는 `API_UPSTREAM` 으로 프록시된다(동일 출처 — CORS 없음, 토큰이 다른 출처로 가지 않음). 응답에 CSP·X-Frame-Options·nosniff·Referrer-Policy 헤더가 붙는다.
API 는 `GET /api/v1/health` 를 제공해야 첫 화면의 연결 상태가 `ok` 가 된다.

## 빠른 시작

```bash
make preflight
make local-all
open http://127.0.0.1:{{APP_PORT}}
make test               # vitest + tsc
make local-stop
```

## Make 타겟

| 타겟 | 설명 |
|------|------|
| `make <mode>-all / -build / -logs / -stop / -restart / -ps` | 수명주기 (`mode` = local \| prod) |
| `make test` | 단위 시험(Vitest) + 타입 검사 |
| `make build-web` | 운영 정적 빌드 (`dist/`) |
| `make shell [ENV=]` | 컨테이너 셸 |
| `make deploy` | prod 롤아웃 |
| `make preflight / help` | 점검 / 목록 |

E2E 는 Playwright (`e2e/`, `pnpm e2e`, 브라우저 설치 `pnpm exec playwright install firefox`).

## 시험

`test/` 단일 트리 — `test/dev-env/`, `test/impl/<Nth>/`. 단위 시험은 `test/*.test.tsx`. 규칙은 `test/README.md`.
