// {{PROJECT_NAME}} — 의존성 없는 최소 HTTP 서버 (POSIX socket). 프레임워크(Drogon 등)는 implement 단계에서 선택.
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>

#include <cstdlib>
#include <cstring>
#include <iostream>
#include <string>

#include "health.hpp"

static std::string env_or(const char* key, const char* def) {
  const char* v = std::getenv(key);
  return v ? v : def;
}

static int probe() {  // 컨테이너 헬스체크: GET /health == 200 → 0
  int fd = socket(AF_INET, SOCK_STREAM, 0);
  sockaddr_in addr{};
  addr.sin_family = AF_INET;
  addr.sin_port = htons(8080);
  inet_pton(AF_INET, "127.0.0.1", &addr.sin_addr);
  if (connect(fd, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) != 0) return 1;
  const char* req = "GET /health HTTP/1.0\r\n\r\n";
  send(fd, req, std::strlen(req), 0);
  char buf[64] = {0};
  recv(fd, buf, sizeof(buf) - 1, 0);
  close(fd);
  return std::strncmp(buf, "HTTP/1.1 200", 12) == 0 ? 0 : 1;
}

int main(int argc, char** argv) {
  if (argc > 1 && std::string(argv[1]) == "--healthcheck") return probe();
  int server = socket(AF_INET, SOCK_STREAM, 0);
  int yes = 1;
  setsockopt(server, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes));
  sockaddr_in addr{};
  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = INADDR_ANY;
  addr.sin_port = htons(8080);
  if (bind(server, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) != 0 || listen(server, 64) != 0) {
    std::perror("bind/listen");
    return 1;
  }
  std::cout << "listening on :8080" << std::endl;
  for (;;) {
    int client = accept(server, nullptr, nullptr);
    if (client < 0) continue;
    char buf[1024] = {0};
    recv(client, buf, sizeof(buf) - 1, 0);
    bool is_health = std::strncmp(buf, "GET /health", 11) == 0;
    std::string body = is_health ? health_json(env_or("APP_ENV", "local"), env_or("DB_ENGINE", "sqlite"))
                                 : std::string("{\"error\":\"not found\"}");
    std::string res = std::string(is_health ? "HTTP/1.1 200 OK" : "HTTP/1.1 404 Not Found") +
                      "\r\nContent-Type: application/json\r\nContent-Length: " + std::to_string(body.size()) +
                      "\r\nConnection: close\r\n\r\n" + body;
    send(client, res.data(), res.size(), 0);
    close(client);
  }
}
