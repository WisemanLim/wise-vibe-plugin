#pragma once
#include <string>

// GET /health 응답 본문 (env 주입: APP_ENV, DB_ENGINE)
std::string health_json(const std::string& env, const std::string& db_engine);
