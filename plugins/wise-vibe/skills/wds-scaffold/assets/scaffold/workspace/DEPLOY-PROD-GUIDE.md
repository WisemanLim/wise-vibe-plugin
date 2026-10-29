# {{PROJECT_NAME}} 운영 배포 가이드 (dev · prod, 단일 서버 compose)

> 생성: `wise-vibe` `wds-scaffold` workspace. 아래는 **구현된 명령**만 절차로 적는다. 미구현 기능은 마지막 표에 따로 둔다.
> 🔴 `.env.prod`, `.secrets/`, `release/deploy.env` 는 git·이미지·티켓·채팅에 넣지 않는다. 비밀은 사람이 정하지 않는다 — `scripts/prod-secrets.sh` 가 대상 머신에서 생성하고 지문만 출력한다.

## 1. 명령 (release/release.sh)

| 명령 | 하는 일 | 상태 |
|---|---|---|
| `doctor [--remote]` | OS·arch, docker·compose ≥ 2.20·buildx·openssl·make·curl·tar·git, podman shim 거부 | 구현 |
| `build [--platforms] [--version]` | 서비스별 runtime 이미지 → `release/dist/<svc>-<V>-<arch>.tar.gz` + `.sha256` | 구현 |
| `up [--env dev\|prod] [--version] [--rebuild]` | 비밀 init → 이미지 → prod compose 기동 → (DB 있는 서비스) `db-migrate ENV=prod` → healthcheck | 구현 |
| `deploy --host … [--env] [--build-on local\|remote] [--install-deps]` | ssh → OS/arch → 소스(git 가시 파일만) 전송 → 이미지 스트리밍 또는 원격 빌드 → 서버 `up` → `current` 전환 | 구현 |
| `status` / `down` `[--remote]` | 컨테이너·비밀 지문 / 중지(볼륨·비밀 유지) | 구현 |
| `rollback --to V --remote` | `current` 를 이전 릴리스로 전환 후 재기동. **DB 마이그레이션은 되돌리지 않음** | 구현 |

입력 우선순위: CLI > `release/deploy.env` > 질문 > 기본값. `--yes` 는 질문 없이 기본값, 필수값 누락 시 중단.
종료 코드: 0 성공 · 2 인수·설정 · 4 연결 · 5 검증 실패 · 8 미지원 (자동화용 고정 값).

## 2. 서버 디렉터리

```
/opt/{{PROJECT_NAME}}/
├── current -> releases/<V>
├── releases/<V>/                      # root + 서브 repo 의 git 가시 파일만
│   └── <sub-repo>/.env.prod -> ../../../shared/<sub-repo>/.env.prod
└── shared/ (0700)                     # 업그레이드·롤백에도 유지되는 비밀
    └── <sub-repo>/{.env.prod, .secrets/}
```

## 3. 절차

```bash
# 1) 작업 PC — 사전 점검과 배포 시험
make test && make secret-scan && make doctor
# 2) local 리허설 (prod 모드 그대로)
release/release.sh up --env dev --yes --version 0.1.0-dev
release/release.sh status
# 3) dev 서버 배포 (키 인증 ssh)
cp release/deploy.env.example release/deploy.env   # REMOTE_HOST 등 편집 (비밀 없음)
release/release.sh deploy --env dev --version 0.1.0
# 4) prod 배포 — dev 에서 확인한 같은 버전
release/release.sh deploy --env prod --host <user@prod-server> --version 0.1.0
```

## 4. 서브 프로젝트 · 노출 범위

| 디렉터리 | 별도 git repo | 구성 | 게시 포트 |
|---|---|---|---|
{{SERVICES_ROWS}}

- 모든 게시 포트는 `127.0.0.1`. 외부 공개는 호스트 리버스 프록시(TLS)로 웹 포트만.
- DB 는 호스트 포트를 열지 않는다. 서비스 간 통신은 `{{PROJECT_NAME}}-net` 별칭(`<repo>-<component>`).
- 웹은 `/api` 를 API 로 프록시(동일 출처), CSP·X-Frame-Options·nosniff·Referrer-Policy 헤더.

## 5. 미구현 (프로젝트별로 추가)

| 기능 | 비고 |
|---|---|
| 비밀 회전 `rotate` / `rotate-db` | `scripts/prod-secrets.sh` 확장 |
| 백업·복원·서버 이전 | `scripts/prod-backup.sh` / `prod-restore.sh` (pg_dump + gpg 번들) |
| 수용 시험 `release/test.sh` | 서브 repo 수용 시험이 생긴 뒤, root 는 호출만 |
| 서명·SBOM·출시 게이트, Helm·에어갭 | 릴리스 단계 |
