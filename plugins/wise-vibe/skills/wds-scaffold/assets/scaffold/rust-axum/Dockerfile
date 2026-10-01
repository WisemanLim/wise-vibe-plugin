# {{PROJECT_NAME}} — rust-axum (multi-stage: dev = local 모드, runtime = prod 모드)
FROM rust:1 AS dev
WORKDIR /src
COPY . .
RUN cargo build
EXPOSE 3000
CMD ["cargo", "run"]

FROM dev AS build
RUN cargo build --release

FROM debian:bookworm-slim AS runtime
RUN useradd -r -u 10001 app && mkdir -p /app/data && chown app /app/data
COPY --from=build /src/target/release/server /app/server
USER app
EXPOSE 3000
ENTRYPOINT ["/app/server"]
