#!/bin/sh
# Development loop inside the container.
#
# 1. Compiles once and starts the app with `spring-boot:run` (remote debug on 5005).
# 2. In parallel, every 2s checks whether src/main or pom.xml changed; if so, recompiles.
# 3. On success, touches target/classes/.reloadtrigger and spring-boot-devtools restarts the app
#    (once; on a compilation error the previous version keeps running).
#
# Polling instead of inotify: file events do not always cross the volume on macOS/Windows.
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
      echo "[dev] change detected, recompiling..."
      if ./mvnw -q -B compile; then
        touch "$TRIGGER"
      else
        echo "[dev] compilation error, waiting for a fix..."
      fi
    fi
  done
) &

exec ./mvnw -q -B spring-boot:run \
  -Dspring-boot.run.jvmArguments="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"
