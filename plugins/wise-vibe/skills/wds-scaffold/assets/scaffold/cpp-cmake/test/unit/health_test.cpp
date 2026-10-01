#include <cassert>
#include <iostream>

#include "health.hpp"

int main() {
  auto body = health_json("local", "sqlite");
  assert(body.find("\"status\":\"ok\"") != std::string::npos);
  assert(body.find("\"engine\":\"sqlite\"") != std::string::npos);
  std::cout << "health_test OK" << std::endl;
  return 0;
}
