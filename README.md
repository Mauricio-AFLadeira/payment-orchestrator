# payment-orchestrator

Esqueleto de uma API REST de orquestração de pagamentos em Java + Spring Boot, integrada à Juspay e com banco relacional. Projeto de estudo: cada etapa é construída e discutida separadamente (arquitetura, boas práticas, segurança e escalabilidade).

## Requisitos

Docker e Docker Compose. Não é preciso instalar Java nem Maven na máquina: tudo roda dentro do container.

## Como rodar

```bash
make setup
make up
```

A API sobe em http://localhost:8080 (health check em `/actuator/health`).

A primeira subida demora cerca de um minuto (download de dependências e primeira compilação). Depois disso, cada alteração em `src/main` é recompilada e a aplicação reinicia em uns 2 segundos.

## Comandos

| Comando | O que faz |
|---|---|
| `make` / `make help` | Lista os comandos |
| `make setup` | Cria o `.env`, ativa o pre-commit hook e builda a imagem |
| `make up` | Sobe app + Postgres |
| `make down` | Derruba o ambiente |
| `make logs` | Acompanha os logs da aplicação |
| `make shell` | Shell dentro do container da aplicação |
| `make db-shell` | `psql` no banco de desenvolvimento |
| `make lint` | Verifica a formatação (Spotless) |
| `make fmt` | Formata o código |
| `make test` | Roda os testes (ainda não configurados) |
| `make build-prod` | Gera a imagem de produção |
| `make reset` | Derruba tudo e **apaga os dados locais** |

### Debug pela IDE

O container expõe a JDWP na porta `5005`. No IntelliJ: *Run → Edit Configurations → Remote JVM Debug*, host `localhost`, porta `5005`.

## Estrutura

```
src/main/java/dev/payments/orchestrator
├── domain/                     # regras de negócio puras (sem Spring, JPA ou Juspay)
├── application/                # casos de uso + portas (port.in / port.out)
├── adapter/
│   ├── in/web/                 # controllers REST e DTOs da API
│   └── out/
│       ├── persistence/        # JPA, repositórios, mapeamento entidade <-> domínio
│       └── gateway/juspay/     # cliente da Juspay
└── config/                     # configuração do Spring
src/main/resources
├── application.yml
└── db/migration/               # migrações Flyway (V1__..., V2__...)
docker/dev.sh                   # loop de dev: compila ao salvar + devtools reinicia
```

Cada pacote tem um `package-info.java` explicando a responsabilidade dele e o que ele pode importar.

## Decisões

- **Java 25 (LTS) + Spring Boot 4.1.1**: versões estáveis mais recentes em out/2026. Imagens `eclipse-temurin:25-*-alpine`, com tag fixa (nunca `latest`).
- **Arquitetura hexagonal (ports & adapters)**: num orquestrador, o provedor de pagamento é um detalhe trocável. A Juspay fica isolada em `adapter/out/gateway/juspay`, e o domínio não conhece os tipos dela. Um segundo provedor entra como pacote irmão, sem mexer no domínio.
- **PostgreSQL 18**: transações ACID, constraints e `SELECT ... FOR UPDATE` são o que um sistema de pagamentos precisa. A partir da versão 18 o volume é montado em `/var/lib/postgresql`.
- **Flyway controla o schema, Hibernate só valida** (`ddl-auto: validate`): toda mudança de banco é um arquivo versionado e revisável.
- **`open-in-view: false`**: evita consultas lazy disparadas fora da camada de serviço.
- **`DATABASE_PASSWORD` sem valor padrão**: sem a variável a aplicação não sobe. Segredo nunca fica em código, `ARG`, `ENV` ou camada de imagem.
- **Graceful shutdown + `init: true`**: requisições de pagamento em andamento terminam antes do container parar.
- **Spotless + Palantir Java Format** (4 espaços, próximo do estilo Spring): formatação automática, sem discussão de estilo em code review.
- **Hot reload por polling + trigger file do devtools**: eventos de arquivo nem sempre atravessam volumes no macOS/Windows, então o `docker/dev.sh` verifica mudanças a cada 2s. Ele só reinicia a aplicação quando a compilação passa, e reinicia uma vez só.
- **Imagem de produção**: só a JRE e o jar, rodando com usuário não-root e `MaxRAMPercentage=75` para respeitar o limite de memória do container.
- **Pacote base `dev.payments.orchestrator`**: nome neutro, fácil de renomear.

## Próximos passos

1. Modelagem do domínio de pagamento (estados, valores monetários, idempotência)
2. Primeira migração e persistência
3. Cliente Juspay (autenticação, timeouts, retries, webhooks)
4. Testes (JUnit + Testcontainers) e CI
5. Segurança (autenticação da API, segredos, PCI) e observabilidade
