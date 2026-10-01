# {{PROJECT_NAME}} — java-spring (multi-stage: dev = local 모드, runtime = prod 모드)
FROM gradle:8.10-jdk21 AS dev
WORKDIR /src
COPY settings.gradle.kts build.gradle.kts ./
RUN gradle dependencies --no-daemon -q || true
COPY src src
EXPOSE 8080
CMD ["gradle", "bootRun", "--no-daemon", "--project-cache-dir", "/tmp/gradle-run"]

FROM dev AS build
RUN gradle bootJar --no-daemon -x test

FROM eclipse-temurin:21-jre-alpine AS runtime
WORKDIR /app
RUN adduser -D -u 10001 app && mkdir -p /app/data && chown app /app/data
COPY --from=build /src/build/libs/*.jar app.jar
USER app
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
