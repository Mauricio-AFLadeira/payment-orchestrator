#!/bin/sh
# Loop de desenvolvimento dentro do container.
#
# 1. Compila uma vez e sobe a aplicação com `spring-boot:run` (debug remoto na 5005).
# 2. Em paralelo, a cada 2s verifica se algo em src/main ou no pom.xml mudou; se mudou, recompila.
# 3. Se compilou, toca target/classes/.reloadtrigger e o spring-boot-devtools reinicia a aplicação
#    (uma vez só; com erro de compilação a versão anterior continua no ar).
#
# Polling em vez de inotify: eventos de arquivo nem sempre atravessam o volume no macOS/Windows.
set -e

MARKER=target/.last-compile
TRIGGER=target/classes/.reloadtrigger

./mvnw -q -B compile
touch "$MARKER"

(
  while true; do
    sleep 2
    if [ -n "$(find src/main pom.xml -newer "$MARKER" -type f 2>/dev/null | head -n 1)" ]; then
      touch "$MARKER"
      echo "[dev] mudança detectada, recompilando..."
      if ./mvnw -q -B compile; then
        touch "$TRIGGER"
      else
        echo "[dev] erro de compilação, aguardando correção..."
      fi
    fi
  done
) &

exec ./mvnw -q -B spring-boot:run \
  -Dspring-boot.run.jvmArguments="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"
