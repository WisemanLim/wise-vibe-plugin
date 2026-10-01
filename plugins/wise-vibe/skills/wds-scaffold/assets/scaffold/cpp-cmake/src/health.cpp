#include "health.hpp"

std::string health_json(const std::string& env, const std::string& db_engine) {
  return "{\"status\":\"ok\",\"env\":\"" + env + "\",\"db\":{\"engine\":\"" + db_engine + "\"}}";
}
