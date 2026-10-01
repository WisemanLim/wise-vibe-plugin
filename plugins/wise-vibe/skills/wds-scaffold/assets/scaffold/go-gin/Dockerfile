# {{PROJECT_NAME}} — go-gin (multi-stage: dev = local 모드, runtime = prod 모드)
FROM golang:1.24 AS dev
WORKDIR /src
ENV GOFLAGS=-mod=mod
COPY go.mod go.sum* ./
RUN go mod download || true
COPY . .
RUN go mod tidy
EXPOSE 8080
CMD ["sh", "-c", "go mod tidy && go run ./cmd/server"]

FROM dev AS build
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/server ./cmd/server

# make db-* 타겟이 컨테이너 셸을 쓰므로 distroless 대신 alpine (정적 바이너리)
FROM alpine:3.20 AS runtime
RUN adduser -D -u 10001 app && mkdir -p /app/data && chown app /app/data
COPY --from=build /out/server /server
USER app
EXPOSE 8080
ENTRYPOINT ["/server"]
