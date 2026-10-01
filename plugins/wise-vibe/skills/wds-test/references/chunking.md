# wds-test 참고 / reference — result 템플릿 · 청킹

## A. result.md 템플릿 / template

```markdown
# 시험 결과 / Test Result — <area> <Nth>
- 일자 Date / 대상 Target(profile) / 커밋 Commit
## 요약 / Summary
- 전체 Total: N, 통과 Pass: N, 실패 Fail: N, 최종 Verdict: PASS|FAIL
## 케이스 / Cases
| id | 결과 result | 비고 note |
## 발견 오류 및 수정 / Bugs & Fixes
| round | 오류 bug | 원인 cause | 수정 fix | 재시험 retest |
## 첨부 / Logs
- logs/ 참조
```

## B. 청킹 전략 / Chunking Strategy

시험 케이스가 많아 단일 실행이 비효율적일 때 기능 영역(feature area) 단위로 분할해 빠르게 처리한다.

### B.1 청킹 결정 기준

| 조건 | 처리 |
|---|---|
| 총 케이스 수(TC) ≤ N (기본 15) | 단일 실행 — `test/impl/<Nth>/` 직접 사용 |
| TC > N | 청크 분할 — `test/impl/<Nth>/chunk-<K>/` 사용 |
| `--chunk N` 인자 있음 | N 값으로 기준 재정의 |

### B.2 청크 분할 방법

우선순위 순서로 분할 경계를 결정한다:

1. **기능 그룹 기준 (권장)** — 라우터 prefix / 컨트롤러 / PRD 기능 항목별로 1청크.
   예: `chunk-1=인증`, `chunk-2=상품`, `chunk-3=주문`
2. **디렉터리·모듈 기준** — 소스 디렉터리 구조를 그대로 청크 경계로 사용.
3. **케이스 수 균등 분할** — 위 기준 적용 불가 시 TC를 N씩 순서대로 분할.

분할 수: `⌈TC / N⌉` 청크. 청크 번호: `chunk-1`, `chunk-2`, …

### B.3 청크별 디렉터리 구조

```
test/impl/<Nth>/
├── scenario.md        # 전체 시험 범위 요약 (청크 목록 포함)
├── result.md          # 합산 최종 결과
├── chunk-1/
│   ├── scenario.md    # 해당 청크 시나리오
│   ├── result.md      # 해당 청크 결과
│   └── logs/
├── chunk-2/
│   ├── scenario.md
│   ├── result.md
│   └── logs/
└── …
```

단일 실행(TC ≤ N)이면 청크 디렉터리 없이 기존 구조(`scenario.md`, `result.md`, `logs/`)를 그대로 사용.

### B.4 합산 result.md 추가 항목

청크 분할 시 `test/impl/<Nth>/result.md` 에 아래 표 추가:

```markdown
## 청크별 결과 / Chunk Results
| 청크 | 영역 | 총 | PASS | FAIL | 판정 |
|---|---|---|---|---|---|
| chunk-1 | 인증 | 5 | 5 | 0 | PASS |
| chunk-2 | 상품 | 8 | 7 | 1 | FAIL |
| 합산 | — | 13 | 12 | 1 | FAIL |
```

### B.5 청크 간 의존성 처리

- 앞 청크 실패가 뒤 청크 전제조건(예: 인증 토큰 발급)을 깨면 **의존 청크를 건너뛰고** 독립 청크 먼저 실행.
- 건너뛴 청크는 결과 표에 `SKIP (의존 청크 FAIL)` 으로 기록.
- 의존 청크가 수정 후 PASS 되면 건너뛴 청크를 이어서 실행.

