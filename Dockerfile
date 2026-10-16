# syntax=docker/dockerfile:1

ARG JAVA_VERSION=25

# ---------------------------------------------------------------------------
# base: JDK + non-root user (shared by dev and build)
# ---------------------------------------------------------------------------
FROM eclipse-temurin:${JAVA_VERSION}-jdk-alpine AS base
ARG UID=1000
ARG GID=1000
RUN addgroup -g ${GID} app \
 && adduser -D -u ${UID} -G app app \
 && mkdir -p /app /home/app/.m2 \
 && chown -R app:app /app /home/app/.m2
WORKDIR /app

# ---------------------------------------------------------------------------
# dev: source mounted as a volume, recompiles and restarts automatically (devtools)
# ---------------------------------------------------------------------------
FROM base AS dev
USER app
# Manifest first: changing code does not invalidate the dependency cache.
COPY --chown=app:app mvnw pom.xml ./
COPY --chown=app:app .mvn .mvn
RUN ./mvnw -q -B dependency:go-offline
EXPOSE 8080 5005
HEALTHCHECK --interval=10s --timeout=3s --start-period=120s --retries=5 \
  CMD wget -qO- http://localhost:8080/actuator/health/liveness || exit 1
CMD ["sh", "docker/dev.sh"]

# ---------------------------------------------------------------------------
# build: produces the executable jar
# ---------------------------------------------------------------------------
FROM base AS build
COPY mvnw pom.xml ./
COPY .mvn .mvn
RUN --mount=type=cache,target=/root/.m2 ./mvnw -q -B dependency:go-offline
COPY src src
RUN --mount=type=cache,target=/root/.m2 ./mvnw -q -B package -DskipTests \
 && cp target/payment-orchestrator-*.jar /app/app.jar

# ---------------------------------------------------------------------------
# prod: only the JRE and the jar; no Maven, no sources, no devtools
# ---------------------------------------------------------------------------
FROM eclipse-temurin:${JAVA_VERSION}-jre-alpine AS prod
ARG UID=1000
ARG GID=1000
RUN addgroup -g ${GID} app && adduser -D -u ${UID} -G app app
WORKDIR /app
COPY --from=build --chown=app:app /app/app.jar app.jar
USER app
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=3s --start-period=30s --retries=5 \
  CMD wget -qO- http://localhost:8080/actuator/health/liveness || exit 1
# MaxRAMPercentage: the JVM sizes the heap from the container memory limit.
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "-jar", "app.jar"]
