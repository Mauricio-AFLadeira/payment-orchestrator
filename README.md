# payment-orchestrator

Skeleton of a payment orchestration REST API in Java + Spring Boot, integrated with Juspay and backed by a relational database. This is a study project: each step is built and discussed separately (architecture, best practices, security and scalability).

## Requirements

Docker and Docker Compose. You don't need Java or Maven installed: everything runs inside the container.

## Running

```bash
make setup
make up
```

The API starts at http://localhost:8080 (health check at `/actuator/health`).

The first start takes about a minute (dependency download and first compilation). After that, every change under `src/main` is recompiled and the app restarts in about 2 seconds.

## Commands

| Command | What it does |
|---|---|
| `make` / `make help` | List commands |
| `make setup` | Create `.env`, enable the pre-commit hook and build the image |
| `make up` | Start app + Postgres |
| `make down` | Stop the environment |
| `make logs` | Follow application logs |
| `make shell` | Shell inside the app container |
| `make db-shell` | `psql` on the development database |
| `make lint` | Check formatting (Spotless) |
| `make fmt` | Format code |
| `make test` | Run tests (not configured yet) |
| `make build-prod` | Build the production image |
| `make reset` | Stop everything and **delete local data** |

### Debugging from the IDE

The container exposes JDWP on port `5005`. In IntelliJ: *Run → Edit Configurations → Remote JVM Debug*, host `localhost`, port `5005`.

## Structure

```
src/main/java/dev/payments/orchestrator
├── domain/                     # pure business rules (no Spring, JPA or Juspay)
├── application/                # use cases + ports (port.in / port.out)
├── adapter/
│   ├── in/web/                 # REST controllers and API DTOs
│   └── out/
│       ├── persistence/        # JPA, repositories, entity <-> domain mapping
│       └── gateway/juspay/     # Juspay client
└── config/                     # Spring configuration
src/main/resources
├── application.yml
└── db/migration/               # Flyway migrations (V1__..., V2__...)
docker/dev.sh                   # dev loop: compile on save + devtools restart
```

Each package has a `package-info.java` describing its responsibility and what it may import.

## Decisions

- **Java 25 (LTS) + Spring Boot 4.1.1**: latest stable versions as of Oct 2026. `eclipse-temurin:25-*-alpine` images with pinned tags (never `latest`).
- **Hexagonal architecture (ports & adapters)**: in an orchestrator, the payment provider is a replaceable detail. Juspay is isolated in `adapter/out/gateway/juspay` and the domain never sees its types. A second provider becomes a sibling package without touching the domain.
- **PostgreSQL 18**: ACID transactions, constraints and `SELECT ... FOR UPDATE` are what a payment system needs. Since version 18 the volume is mounted at `/var/lib/postgresql`.
- **Flyway owns the schema, Hibernate only validates** (`ddl-auto: validate`): every database change is a versioned, reviewable file.
- **`open-in-view: false`**: avoids lazy queries fired outside the service layer.
- **`DATABASE_PASSWORD` has no default**: without it the app does not start. Secrets never live in code, `ARG`, `ENV` or image layers.
- **Graceful shutdown + `init: true`**: in-flight payment requests finish before the container stops.
- **Spotless + Palantir Java Format** (4 spaces, close to Spring style): automatic formatting, no style debates in code review.
- **Polling hot reload + devtools trigger file**: file events don't always cross volumes on macOS/Windows, so `docker/dev.sh` checks for changes every 2s. It restarts the app only when compilation succeeds, and only once.
- **Production image**: only the JRE and the jar, running as a non-root user with `MaxRAMPercentage=75` to respect the container memory limit.
- **Base package `dev.payments.orchestrator`**: neutral name, easy to rename.

## Next steps

1. Payment domain modeling (states, monetary amounts, idempotency)
2. First migration and persistence
3. Juspay client (authentication, timeouts, retries, webhooks)
4. Tests (JUnit + Testcontainers) and CI
5. Security (API authentication, secrets, PCI) and observability
