import { render, screen, waitFor } from "@testing-library/react";
import { App } from "../src/App";

test("API 연결 실패를 unreachable 로 표시한다", async () => {
  vi.stubGlobal("fetch", vi.fn().mockRejectedValue(new Error("down")));
  render(<App />);
  expect(screen.getByRole("heading", { name: "{{PROJECT_NAME}}" })).toBeInTheDocument();
  await waitFor(() => expect(screen.getByRole("status")).toHaveTextContent("API: unreachable"));
});
