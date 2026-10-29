# dev-env 시나리오 / scenario — {{PROJECT_NAME}} ({{PROFILE_ID}})

| id | 목적 / purpose | 명령 / command | 기대 / expected | 우선 |
|----|----------------|----------------|-----------------|------|
| ENV-01 | 도구·설정 점검 | `make preflight` | `Preflight OK` | P0 |
| ENV-02 | local 기동 | `make local-all` | web running/healthy | P0 |
| ENV-03 | 화면 응답 | `curl -fsS http://127.0.0.1:{{APP_PORT}}/` | HTTP 200 | P0 |
| ENV-04 | API 프록시 | `curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:{{APP_PORT}}/api/v1/health` | API 기동 시 200, 미기동 시 502 (화면은 `API: unreachable`) | P0 |
| ENV-05 | 단위 시험·타입 | `make test` | exit 0 | P0 |
| ENV-06 | prod 기동 (nginx) | `make prod-all` | web healthy, `/healthz` 200 | P1 |
| ENV-07 | 보안 헤더 | `curl -sI http://127.0.0.1:{{APP_PORT}}/` | CSP·X-Frame-Options·nosniff·Referrer-Policy | P1 |
| ENV-08 | 정리 | `make local-stop && make prod-stop` | 컨테이너 없음 | P1 |
