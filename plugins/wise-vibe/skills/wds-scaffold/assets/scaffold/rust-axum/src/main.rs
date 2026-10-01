// {{PROJECT_NAME}} — axum entrypoint. 설정은 env 주입(.env.local | .env.prod).
use axum::{routing::get, Json, Router};
use serde_json::{json, Value};
use std::io::{Read, Write};

fn env_or(key: &str, default: &str) -> String {
    std::env::var(key).unwrap_or_else(|_| default.to_string())
}

pub fn app() -> Router {
    Router::new().route("/health", get(health))
}

async fn health() -> Json<Value> {
    Json(json!({
        "status": "ok",
        "env": env_or("APP_ENV", "local"),
        "db": { "engine": env_or("DB_ENGINE", "sqlite") }
    }))
}

/// 컨테이너 헬스체크: GET /health 가 200 이면 0 (런타임 이미지에 curl 없음)
fn probe() -> i32 {
    let Ok(mut s) = std::net::TcpStream::connect("127.0.0.1:3000") else { return 1 };
    let _ = s.write_all(b"GET /health HTTP/1.0\r\nHost: localhost\r\n\r\n");
    let mut buf = String::new();
    let _ = s.read_to_string(&mut buf);
    if buf.starts_with("HTTP/1.0 200") || buf.starts_with("HTTP/1.1 200") { 0 } else { 1 }
}

#[tokio::main]
async fn main() {
    if std::env::args().any(|a| a == "--healthcheck") {
        std::process::exit(probe());
    }
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app()).await.unwrap();
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::{body::Body, http::Request};
    use tower::ServiceExt;

    #[tokio::test]
    async fn health_ok() {
        let res = app().oneshot(Request::get("/health").body(Body::empty()).unwrap()).await.unwrap();
        assert_eq!(res.status(), 200);
    }
}
