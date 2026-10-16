# syntax=docker/dockerfile:1

ARG JAVA_VERSION=25

# ---------------------------------------------------------------------------
# base: JDK + usuário não-root (compartilhado por dev e build)
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
# dev: código montado por volume, recompila e reinicia sozinho (devtools)
# ---------------------------------------------------------------------------
FROM base AS dev
USER app
# Manifesto primeiro: mudar código não invalida o cache das dependências.
COPY --chown=app:app mvnw pom.xml ./
COPY --chown=app:app .mvn .mvn
RUN ./mvnw -q -B dependency:go-offline
EXPOSE 8080 5005
HEALTHCHECK --interval=10s --timeout=3s --start-period=120s --retries=5 \
  CMD wget -qO- http://localhost:8080/actuator/health/liveness || exit 1
CMD ["sh", "docker/dev.sh"]

# ---------------------------------------------------------------------------
# build: gera o jar executável
# ---------------------------------------------------------------------------
FROM base AS build
COPY mvnw pom.xml ./
COPY .mvn .mvn
RUN --mount=type=cache,target=/root/.m2 ./mvnw -q -B dependency:go-offline
COPY src src
RUN --mount=type=cache,target=/root/.m2 ./mvnw -q -B package -DskipTests \
 && cp target/payment-orchestrator-*.jar /app/app.jar

# ---------------------------------------------------------------------------
# prod: só a JRE e o jar, sem Maven, sem código-fonte, sem devtools
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
# MaxRAMPercentage: a JVM dimensiona o heap pelo limite de memória do container.
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "-jar", "app.jar"]
