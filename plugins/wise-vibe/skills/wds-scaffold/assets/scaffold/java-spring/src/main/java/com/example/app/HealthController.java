package com.example.app;

import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {
    private final JdbcTemplate jdbc;
    private final String env;
    private final String engine;

    public HealthController(JdbcTemplate jdbc, @Value("${app.env}") String env, @Value("${app.db-engine}") String engine) {
        this.jdbc = jdbc;
        this.env = env;
        this.engine = engine;
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        String db;
        try {
            jdbc.queryForObject("SELECT 1", Integer.class);
            db = "ok";
        } catch (Exception e) {
            db = "error: " + e.getClass().getSimpleName();
        }
        boolean ok = db.equals("ok");
        return ResponseEntity.status(ok ? 200 : 503).body(Map.of(
                "status", ok ? "ok" : "degraded", "env", env,
                "db", Map.of("engine", engine, "status", db)));
    }
}
