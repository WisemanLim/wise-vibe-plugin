// {{PROJECT_NAME}} — gin entrypoint. 설정은 env 주입(.env.local | .env.prod).
package main

import (
	"flag"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
)

func main() {
	healthcheck := flag.Bool("healthcheck", false, "GET /health 후 종료코드로 결과 반환 (컨테이너 헬스체크용)")
	flag.Parse()
	if *healthcheck {
		os.Exit(probe("http://127.0.0.1:8080/health"))
	}
	_ = newRouter().Run(":8080")
}

func newRouter() *gin.Engine {
	r := gin.Default()
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "ok",
			"env":    env("APP_ENV", "local"),
			"db":     gin.H{"engine": env("DB_ENGINE", "sqlite")},
		})
	})
	return r
}

func probe(url string) int {
	client := http.Client{Timeout: 2 * time.Second}
	res, err := client.Get(url)
	if err != nil || res.StatusCode != http.StatusOK {
		return 1
	}
	return 0
}

func env(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}
