# Domain overlay schema (업종/업태 확장 지점 / industry extension point)

각 `domains/*.yaml` 는 하나의 **도메인 오버레이**다. KSIC 대분류(업태)를 기준으로
그 업종에서 개발 표준에 **추가로 얹어야 하는 것**(규제·데이터등급·선호스택·인프라·시험)을
순수 데이터로 담는다. `profiles/*.yaml`(스택) 과 **직교(orthogonal)** 한다:
프로파일은 "무엇으로 만드나(스택)", 도메인은 "어떤 업종이라 무엇을 더 지켜야 하나".

> A domain overlay is pure data keyed by **KSIC section (업태)**. It does NOT replace a
> stack profile — it biases profile selection and injects domain deltas (regulation,
> data classes, infra, tests). `recommend` resolves **profile × domain** together.
> Add a new `*.yaml` here = add a new selectable domain. No command/skill code change.

분류 근거 / classification basis: `.doc` 의 KSIC·ISIC·NACE·NAICS 통합표.
KSIC(통계청) 를 internal canonical 로 쓰고 ISIC/NACE/NAICS 를 병기한다.

## 필드 (fields)

```yaml
id: finance                       # 고유 ID = 파일명(확장자 제외). kebab-case.
title: "금융·보험 (Fintech)"       # 사람이 읽는 이름
status: stable                    # stable | preview | experimental
ksic_section: K                   # KSIC 대분류 1글자 (A~U). 업태 키.
ksic_divisions: [64, 65, 66]      # 관련 중분류 2자리 (선택)
classification:                   # 4체계 병기 (.doc 통합표 근거)
  isic: K
  nace: K
  naics: "52"
summary: >                        # 1~2문장: 이 업종 SW의 핵심 성격
  결제·원장 정합성과 감사가속도보다 우선. ...

keywords:                         # PRD/업종 매칭 키워드 (한/영). recommend 가 점수화에 사용.
  - 금융 / finance / fintech
  - 결제 / payment / PG
  - 보험 / insurance

recommended_profiles:             # 이 도메인이 선호하는 스택 프로파일 (우선순위). 매칭 시 가점.
  - { id: go-gin,         why: "고처리량 결제/거래 코어, 멱등·정합성" }
  - { id: python-fastapi, why: "리스크/사기탐지 ML, 정산 분석 API" }
  - { id: node-next-nest, why: "고객 포털/BFF, 어드민" }

stack_overrides:                  # 베이스 프로파일에 더하는 도메인 기술 (스캐폴더가 compose/문서에 반영)
  database:   "PostgreSQL (원장=ACID/이벤트소싱+Outbox)"
  messaging:  "Apache Kafka (이벤트), Redis Streams (멱등키)"
  security:   "HSM/KMS, crypto-agility(PQC 대비)"
  observability: "불변 감사로그 + SIEM"

korea_regulations:                # 한국 규제 — 개발환경에 미치는 영향 1줄씩 (1순위 근거)
  - { name: "전자금융감독규정",  since: "2025-02-05", impact: "망분리 위험기반 예외, 클라우드/SaaS 분리기준" }
  - { name: "신용정보법",        impact: "개인신용정보 가명/익명 처리, 비프로드 반출 통제" }
  - { name: "ISMS-P",            impact: "접근로그·변경관리·암호화 증적 파이프라인" }

global_compliance:                # 국제 기준 (병행)
  - "PCI-DSS 4.0.1 (2025-03-31 전면 의무)"
  - "SOC 2 Type II"

data_classes:                     # 도메인 데이터 민감도 분류 (COMPLIANCE.md 로 출력)
  - { name: "개인신용정보", level: "규제대상", note: "신용정보법, 비프로드 금지" }
  - { name: "결제/카드데이터(CHD)", level: "규제대상", note: "PCI-DSS scope, 토큰화" }
  - { name: "거래원장/감사로그", level: "무결성", note: "append-only" }

infra_patterns:                   # 이 업종 인프라 필수 패턴
  - "CDE 네트워크 분리(VPC/네트워크정책), 위험기반 망분리"
  - "멱등키 + 정산 대사(reconciliation) 잡"
  - "Transactional Outbox (exactly-once 이벤트)"

dev_env_special:                  # 비-프로덕션/개발환경 특수 요구
  - "비프로드 데이터 마스킹/가명처리 (개인신용정보 반입 금지)"
  - "결제/ KYC 샌드박스 + 합성 규제 테스트데이터"
  - "코드→배포 불변 감사추적 (ISMS-P 증적)"

testing_additions:                # 도메인 특화 시험 케이스 (test/ 에 추가)
  - "멱등 결제: 중복요청 1건만 반영"
  - "정산 대사: 외부 레일 vs 원장 일치"

references:                       # 출처 (서베이 URL). 트렌드 갱신 시 재확인.
  - "https://www.fsc.go.kr/no010101/82885"
  - "https://www.pcisecuritystandards.org/"
```

## 규칙 (rules)

- `id` 는 파일명(확장자 제외)과 일치, `ksic_section` 은 KSIC 대분류 1글자.
- `recommended_profiles` 는 **기존 profiles/ 의 id** 만 참조 (없는 id 금지).
- 도메인은 스택을 **교체하지 않고 편향(bias)** 한다. 강한 도메인 결합형(역할분리 RAG 등)은
  여전히 `profiles/*.yaml` + `extends:` 로 만든다 (예: `bio-rag-research`).
- `korea_regulations` 가 1순위 근거, `global_compliance` 는 병행. 둘 다 출처를 `references` 에.
- `dev_env_special` / `data_classes` 는 스캐폴더가 `COMPLIANCE.md` 로 출력한다.
- 규제/버전은 변한다 — `since`/출처를 남기고, `--trends` 사용 시 WebSearch 로 재확인.
