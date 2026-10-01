// {{PROJECT_NAME}} — flavor → API base (EAS profile / app.json extra 로 주입)
import Constants from "expo-constants";

const extra = (Constants.expoConfig?.extra ?? {}) as Record<string, string>;

export const Env = {
  appEnv: extra.appEnv ?? process.env.EXPO_PUBLIC_APP_ENV ?? "local",
  flavor: extra.flavor ?? process.env.EXPO_PUBLIC_FLAVOR ?? "local",
  apiBaseUrl: extra.apiBaseUrl ?? process.env.EXPO_PUBLIC_API_BASE_URL ?? "http://localhost:8000",
};
