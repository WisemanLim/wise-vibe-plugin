# {{PROJECT_NAME}} — 통합관리 repo

> 생성: `wise-vibe` 플러그인 `wds-scaffold` · 프로파일 `workspace`
> English: [README.en.md](README.en.md)

이 repo 는 **PRD·문서·배포 스크립트·릴리스·배포 시험만** 가진다. 서비스 코드는 아래 서브 프로젝트 repo 에 있고,
이 repo 는 그것들을 추적하지 않는다(`.gitignore`). 서브 프로젝트 목록의 정본은 `release/services.tsv` 다.

| 디렉터리 | 별도 git repo | 구성 | 게시 포트 (release.sh) |
|---|---|---|---|
{{SERVICES_ROWS}}

서브 repo 는 `wds-scaffold <profile> --workspace {{PROJECT_NAME}}` 로 만들어야 prod 공유 네트워크(`{{PROJECT_NAME}}-net`)와 배포 이미지 태그(`API_IMAGE`/`WEB_IMAGE`)가 맞는다.

## 구조

```
PRD.md                       제품 요구 (wds-prd)
docs/                        통합 결정 — TEST-OWNERSHIP.md
release/services.tsv         서브 프로젝트 목록 (repo · short · component · image_var · has_db · host_port)
release/release.sh           doctor · build · up · deploy · status · down · rollback
release/deploy.env.example   배포 입력 기본값 (비밀 없음) → release/deploy.env (ignore)
scripts/prod-secrets.sh      대상 머신에서 .env.prod / .secrets 생성·점검 (값 미출력, 지문만)
scripts/secret-scan.sh       gitleaks — root + 서브 repo
test/deploy/                 배포 시험만 (scenario.md · result.md · 회귀 시험)
DEPLOY-PROD-GUIDE.md         운영 배포 절차
```

## 빠른 시작

```bash
make test                                   # 배포 스크립트 회귀 시험 (Docker 불필요)
make doctor                                 # 이 머신 사전 점검
release/release.sh up --env dev --yes       # 이 머신에서 모든 서브 프로젝트를 prod 모드로 기동
release/release.sh status
release/release.sh down                     # 볼륨·비밀 유지
```

서비스 개발은 각 서브 repo 에서 `make local-all` / `make test` 로 한다. 시험 소유권: [docs/TEST-OWNERSHIP.md](docs/TEST-OWNERSHIP.md).
