---
name: wds-ui-design
description: >
  프론트엔드가 있는 프로젝트의 UI/UX 방향을 안내한다: 목적별 레퍼런스 사이트(국내 포함), 디자인 시스템·접근성
  (KWCAG 2.2 / WCAG 2.2 AA), 플랫폼별 디자인 스택 델타, PRD 디자인 섹션 보강. 미학·UI 코드 품질은 공식
  frontend-design 스킬에 위임한다. "UI 디자인", "UX", "레퍼런스 사이트", "디자인 시스템", "접근성" 요청 시 사용.
license: Internal
compatibility: Claude Code · Cursor 2.4+ · Antigravity 2.0+ · GitHub Copilot · Codex.
metadata:
  version: "2.0.0"
  source: "github.com/WisemanLim/pub-wise-dev-std (ui-design-advisor + /ui-design 통합, frontend-design 위임)"
argument-hint: "[web|mobile|ios|android|flutter] [dashboard|saas|consumer|public] [--prd]"
allowed-tools: Read Glob Grep Edit
---
# wds-ui-design — 프론트엔드 디자인 안내

> 인자: `$ARGUMENTS` — `[web|mobile|ios|android|flutter] [dashboard|saas|consumer|public] [--prd]`

## 위임 원칙 (공식 Skill 우선)

| 영역 | 담당 |
|------|------|
| 미학 방향·타이포·컬러·레이아웃·실제 UI 코드 품질 | **공식 위임** — Anthropic `frontend-design` 스킬/플러그인(설치 시), 테마는 `theme-factory`, 브랜드는 조직 brand 스킬 |
| 국내 레퍼런스 사이트·KWCAG 2.2 접근성·플랫폼별(SwiftUI/Compose/Flutter/RN) 디자인 스택 델타·PRD 디자인 섹션 | **고유** — 아래 본문 |

`frontend-design` 이 있으면 구현 단계(wds-implement)에서 UI 코드를 쓸 때 그 지침을 먼저 따르고, 이 스킬은 레퍼런스·접근성·스택 델타만 덧붙인다.
없으면 이 스킬 본문만으로 진행한다.

이 스킬은 프론트엔드가 포함된 프로젝트에서 **디자인 의사결정 지원 로직과 레퍼런스**를 담는다.  
스택 자체(Next.js/React/Tailwind)는 wds-recommend 가 결정하고, 이 스킬은 그 위에  
**디자인 방향·영감 출처·컴포넌트 패턴·접근성·애니메이션** 델타를 얹는다.

## 0. 적용 조건 (trigger)

아래 조건 중 하나 이상이면 이 스킬을 활성화한다:

- PRD `## 3. 범위` 또는 `## 4. 사용자 경험` 에 화면/인터페이스/UI/UX/웹/앱/대시보드 언급
- recommend 결과 프로파일의 `layers.frontend` 가 존재(`node-next-nest`, `react-native-app`, `flutter-app`, `ios-swiftui`, `android-compose`)
- 사용자 요청에 "디자인", "UI", "UX", "컴포넌트", "화면", "인터페이스", "레퍼런스" 포함
- `wds-ui-design` 직접 호출

## 1. 레퍼런스 사이트 — 목적별 분류

### 1.1 글로벌 웹디자인 트렌드 / 어워드 🏆
**목적**: 전반적 방향성·트렌드 파악, 크리에이티브 아이디어 획득.

| 사이트 | URL | 활용 시점 |
|---|---|---|
| **Awwwards** | awwwards.com | 프로젝트 초반 방향성 설정. 어워드 수상작으로 업계 최고 수준 벤치마킹 |
| **Godly** | godly.website | 트렌디·임팩트 있는 해외 사이트 모아보기. 최신 인터랙션 트렌드 파악 |
| **Httpster** | httpster.net | 심플·감각적 실운영 사이트. 과장 없는 현실적 레퍼런스 |

> PRD `## 4. 사용자 경험` 에 "영감 레퍼런스" 항목 추가 시 1.1 사이트 링크를 후보로 제안한다.

### 1.2 UI 패턴 및 컴포넌트 참고 🧩
**목적**: 특정 UI 요소(버튼·카드·모달·메뉴 등) 구현 패턴 탐색.

| 사이트 | URL | 활용 시점 |
|---|---|---|
| **UIverse** | uiverse.io | 버튼·카드·로더 등 트렌디 컴포넌트 + 바로 쓸 수 있는 HTML/CSS/Tailwind 코드 |
| **유아이볼 (UIBall)** | uiball.com / 국내 큐레이션 | 모바일·웹 스크린 단위 스크린샷. MAU별·기능별 분류 → 특정 기능 기획 시 비교 |

> recommend 후 컴포넌트 설계 단계에서 UIverse 코드 패턴을 Shadcn/ui 스타일로 변환 권장.

### 1.3 코드 중심 구현 예제 💻
**목적**: 인터랙션·애니메이션 구현 방법 직접 참고.

| 사이트 | URL | 활용 시점 |
|---|---|---|
| **CodePen** | codepen.io | 전 세계 개발자의 HTML/CSS/JS 인터랙션·애니메이션 라이브 데모. 바로 포크·실험 가능 |
| **Free Frontend** | freefrontend.com | 메뉴·슬라이더·버튼 등 UI 요소 무료 CSS/JS 구현 예제 모음 |

> scaffold 후 `components/` 디렉터리 초안 작성 시 CodePen 패턴을 React 컴포넌트로 변환 권장.

### 1.4 국내 레퍼런스 및 포트폴리오 🇰🇷
**목적**: 국내 사용자 대상 서비스의 UX 패턴·트렌드 파악.

| 사이트 | URL | 활용 시점 |
|---|---|---|
| **GDWEB (지디웹)** | gdweb.co.kr | 국내 최장수 웹디자인 레퍼런스. 업종별 국내 최신 트렌드 파악 |
| **Behance** | behance.net | 디자이너 포트폴리오 플랫폼. 기획 의도·UI 흐름 상세 공유 |
| **디자이너스** | designers.kr | 국내 웹·앱 디자인 레퍼런스. 서비스 카테고리·UI 패턴별 필터링 가능 |

> 한국 서비스 프로젝트(govtech·finance·healthcare·commerce)는 1.4 를 **1순위** 레퍼런스로 안내.

## 2. 상황별 레퍼런스 추천

| 상황 | 1순위 | 보조 |
|---|---|---|
| 신규 SaaS MVP 방향 설정 | Awwwards, Godly | Behance |
| 특정 컴포넌트 구현 | UIverse | CodePen, Free Frontend |
| 국내 서비스 UX 벤치마킹 | 디자이너스, GDWEB | 유아이볼 |
| 인터랙션·애니메이션 아이디어 | Godly, CodePen | Awwwards |
| 업무용·대시보드 UI | Behance, 유아이볼 | UIverse |
| 모바일 앱 화면 기획 | 유아이볼 | Behance, 디자이너스 |
| 빠른 컴포넌트 코드 복붙 | UIverse, Free Frontend | CodePen |

## 3. 프론트엔드 디자인 스택 델타 (wds-recommend 연동)

wds-recommend 추천 위에 얹는 디자인 레이어 선택 기준.

### 3.1 웹 (Next.js + React)

| 레이어 | 1순위 | 대안 | 근거 |
|---|---|---|---|
| 컴포넌트 라이브러리 | **Shadcn/ui** | Radix UI (headless) | 접근성 내장, Tailwind 호환, 코드 소유권 |
| 애니메이션 | **Framer Motion** | CSS transitions | 선언형 API, React 통합, 레이아웃 애니메이션 |
| 아이콘 | **Lucide React** | Heroicons | Shadcn/ui 기본 번들 |
| 폰트 | **next/font** (Google Fonts) | local font | 자동 최적화·CLS 방지 |
| 이미지 | **next/image** | — | 자동 WebP·lazy load·크기 최적화 |
| 상태(UI) | **Zustand** | Jotai | 보일러플레이트 최소 |
| 차트/대시보드 | **Recharts** | Chart.js | React 친화적 SVG 기반 |
| 테이블 | **TanStack Table** | — | 헤드리스, 정렬·필터·가상화 내장 |

### 3.2 모바일 (React Native / Expo)

| 레이어 | 1순위 | 근거 |
|---|---|---|
| UI 컴포넌트 | **NativeWind** + Expo 기본 | Tailwind 문법 그대로 모바일 적용 |
| 애니메이션 | **React Native Reanimated v3** | 네이티브 스레드 실행, 60fps |
| 네비게이션 | **Expo Router** (파일 기반) | Next.js 와 동일 패러다임 |
| 아이콘 | **@expo/vector-icons** | Expo 내장 |

### 3.3 Flutter

| 레이어 | 1순위 | 근거 |
|---|---|---|
| 디자인 시스템 | **Material 3** (기본) | Flutter 공식, 테마 토큰 체계 |
| 상태 관리 | **Riverpod** | 타입 안전, 테스트 용이 |
| 애니메이션 | **implicit animations** + **AnimationController** | Flutter 내장, 선언형 |

### 3.4 iOS (SwiftUI)

| 레이어 | 선택 | 근거 |
|---|---|---|
| 디자인 시스템 | **Apple HIG** 준수 | 앱스토어 심사·UX 일관성 |
| 애니메이션 | **withAnimation** / **matchedGeometryEffect** | SwiftUI 내장 |

### 3.5 Android (Compose)

| 레이어 | 선택 | 근거 |
|---|---|---|
| 디자인 시스템 | **Material You (Material 3)** | 동적 색상·팔레트, Compose 기본 |
| 애니메이션 | **AnimatedVisibility** / **animate*AsState** | Compose 내장 |

## 4. 접근성(Accessibility) 최소 기준

모든 프론트엔드 구현 시 아래를 기본 요구사항으로 포함한다.

- **WCAG 2.1 AA** 준수 (색상 대비 4.5:1, 키보드 탐색, aria-label)
- **Shadcn/ui** / **Radix UI** 사용 시 접근성 내장 — 별도 구현 불필요
- 이미지 `alt`, 인터랙티브 요소 `role`, 폼 `label` 필수
- 국내 공공/의료/금융 도메인: **웹 접근성 인증마크(KWCAG 2.1)** 요구사항 추가

## 5. PRD 디자인 섹션 보강 템플릿

프론트엔드가 포함된 PRD 에 아래 섹션을 `## 4. 사용자 경험` 하위에 추가 제안한다:

```md
### 디자인 방향
- 목표 분위기: (예: 신뢰감 있는 B2B / 트렌디한 소비자앱 / 간결한 대시보드)
- 레퍼런스 사이트: (Awwwards/Godly/GDWEB/Behance 중 선택 + 특정 사례 URL)
- 참고 서비스: (경쟁사 또는 유사 서비스 명칭)

### UI 패턴 우선순위
- 핵심 컴포넌트: (예: 대시보드 카드, 무한스크롤 피드, 멀티스텝 폼)
- 인터랙션 수준: (정적 / 마이크로 애니메이션 / 풀 트랜지션)

### 접근성 요구
- 최소 기준: WCAG 2.1 AA (기본값)
- 추가: (공공/의료/금융이면 KWCAG 2.1)
```

## 6. 출력 후 안내

wds-ui-design 를 통해 디자인 방향이 정해지면:

> 디자인 스택 델타가 결정됐습니다.  
> - **PRD** 에 `### 디자인 방향` 섹션을 추가했다면 `wds-recommend` 로 이어가세요.  
> - **recommend** 완료 후라면 `wds-scaffold` 로 구조를 생성하세요.  
>   (Shadcn/ui + Framer Motion 기준이면 scaffold 시 `components/ui/` 초안을 함께 생성합니다.)

## 참고 사이트 빠른 목록

```
트렌드·어워드:  awwwards.com / godly.website / httpster.net
컴포넌트:       uiverse.io / uiball.com (유아이볼)
코드 예제:      codepen.io / freefrontend.com
국내 레퍼런스:  gdweb.co.kr / behance.net / designers.kr
```
