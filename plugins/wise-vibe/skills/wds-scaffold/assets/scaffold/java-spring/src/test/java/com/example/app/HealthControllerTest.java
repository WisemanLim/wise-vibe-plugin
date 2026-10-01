package com.example.app;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
        properties = "spring.datasource.url=jdbc:sqlite:/tmp/test.db")
@ActiveProfiles("local")
class HealthControllerTest {
    @Autowired TestRestTemplate rest;

    @Test
    void healthOk() {
        assertThat(rest.getForEntity("/health", String.class).getStatusCode().value()).isEqualTo(200);
    }
}
