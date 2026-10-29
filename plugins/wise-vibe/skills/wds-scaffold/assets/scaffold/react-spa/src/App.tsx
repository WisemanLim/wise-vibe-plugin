// SPA 진입점 골격. 화면은 PRD 의 화면 목록·구현 순서대로 이 셸 위에 구성한다.
import { useEffect, useState } from "react";

type ApiState = "checking" | "ok" | "unreachable";

export function App() {
  const [api, setApi] = useState<ApiState>("checking");

  useEffect(() => {
    // API health (API 는 /api/v1/health 를 제공해야 한다) — 실패를 "정상"으로 표시하지 않는다(미확인 = unreachable)
    fetch("/api/v1/health")
      .then((res) => setApi(res.ok ? "ok" : "unreachable"))
      .catch(() => setApi("unreachable"));
  }, []);

  return (
    <main>
      <h1>{{PROJECT_NAME}}</h1>
      <p role="status">API: {api}</p>
    </main>
  );
}
