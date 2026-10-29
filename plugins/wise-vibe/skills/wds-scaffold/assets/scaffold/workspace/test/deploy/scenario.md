# 배포 시험 시나리오 — {{PROJECT_NAME}} 통합관리 repo

| id | 목적 | 명령 | 기대 |
|----|------|------|------|
| DEP-01 | 스크립트 문법 | `make test` (bash -n) | exit 0 |
| DEP-02 | 소스 아카이브 회귀 | `python3 -I test/deploy/test_source_archive.py` | 서브 repo 파일 포함, 비밀·state·node_modules·삭제 파일 제외, 한글 경로 유지 |
| DEP-03 | 비밀 init/status 회귀 | `python3 -I test/deploy/test_prod_secrets.py` | 값 생성·미출력·재실행 보존·신규 키 추가·0440·불일치 exit 5·shared symlink |
| DEP-04 | root 가 서브 repo 미추적 | `git status --short` | 서브 디렉터리 항목 0 |
| DEP-05 | 사전 점검 | `release/release.sh doctor` | `doctor OK` |
| DEP-06 | 로컬 dev 리허설 | `release/release.sh up --env dev --yes --version 0.1.0-dev` | 모든 서비스 healthy, DB 있는 서비스는 migrate 실행 |
| DEP-07 | 노출 범위 | `docker ps` 포트 확인 | 게시 포트 모두 127.0.0.1, db 포트 미게시 |
| DEP-08 | 이미지 내부 비밀 없음 | 각 이미지에서 `.env*`·`.secrets` 탐색 | 없음 |
| DEP-09 | 서비스 간 통신 | web → `/api/...` 프록시 | 공유 네트워크 별칭으로 200 |
| DEP-10 | 상태·중지 | `release.sh status` / `down` → `up` | 지문만 출력, 볼륨·비밀 지문 유지 |
| DEP-11 | 비밀 스캔 | `make secret-scan` | 발견 0 |

대상 서버가 필요한 항목: `deploy --host`, `rollback`, `--install-deps`, 멀티아키 `build`.
