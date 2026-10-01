# {{PROJECT_NAME}} — cpp-cmake (multi-stage: dev = local 모드, runtime = prod 모드)
FROM ubuntu:24.04 AS dev
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential cmake ninja-build curl ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /src
COPY . .
RUN cmake --preset debug && cmake --build build/debug
EXPOSE 8080
CMD ["sh", "-c", "cmake --preset debug >/dev/null && cmake --build build/debug && ./build/debug/server"]

FROM dev AS build
RUN cmake --preset release && cmake --build build/release

# 빌드 스테이지와 같은 libstdc++(GLIBCXX) 를 보장하려고 동일 베이스 사용
FROM ubuntu:24.04 AS runtime
RUN useradd -r -u 10001 app && mkdir -p /app/data && chown app /app/data
COPY --from=build /src/build/release/server /app/server
USER app
EXPOSE 8080
ENTRYPOINT ["/app/server"]
