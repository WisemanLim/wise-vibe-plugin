# 시험 소유권 / Test ownership

통합관리 repo 는 **빌드·배포 시험만** 소유한다. 기능 시험과 결과는 서브 프로젝트 repo 가 소유한다.

| 위치 | 소유 시험 | 결과 저장 |
|---|---|---|
| `<sub-repo>/test/dev-env/` | 서브 repo 표준 환경 검증 1회 | `scenario.md` · `result.md` |
| `<sub-repo>/test/impl/<Nth>/` | 구현 차수별 단위·계약·기능 시험 | `scenario.md` · `result.md` (로그 비커밋) |
| `<sub-repo>/test/integration/` | 다른 서브 프로젝트에 대한 **소비자 계약** 시험·브라우저 E2E (공급자 소스 접근 금지) | 소비자 repo |
| root `test/deploy/` | 배포·릴리스만: 스크립트 문법, 소스 아카이브 회귀, 비밀 init/status 회귀, local/원격 배포 리허설, 백업·복원·회전(도입 시) | `scenario.md` · `result.md` |

- root 에 `test/impl/` 을 두지 않는다.
- 통합 검증은 별도 demo stack 없이 `release/release.sh up` 으로 띄운 환경에서 합성 데이터로 한다.
