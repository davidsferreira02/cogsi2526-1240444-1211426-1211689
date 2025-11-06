#!/usr/bin/env bash
set -euo pipefail

DB_HOST=${DB_HOST:-ca3-db.cogsi}
BUILD_APP=${BUILD_APP:-true}
START_APP=${START_APP:-true}
APP_PROJECT_DIR=${APP_PROJECT_DIR:-/workspace/CA2/Part2}

echo "[APP] Updating packages..."
sudo apt-get update -y
sudo apt-get install -y openjdk-17-jdk maven gradle curl jq netcat dnsutils

# --- Resolve DB hostname ---
echo "[APP] Resolving DB hostname: ${DB_HOST}"
for i in {1..20}; do
  DB_IP=$(getent ahostsv4 "${DB_HOST}" | awk '{print $1; exit}') || true
  if [[ -n "${DB_IP}" ]]; then
    echo "[APP] Resolved ${DB_HOST} -> ${DB_IP}"
    break
  fi
  echo "[APP] Waiting for ${DB_HOST} DNS entry... (${i}/20)"
  sleep 2
done
if [[ -z "${DB_IP:-}" ]]; then
  echo "[APP][WARN] Could not resolve ${DB_HOST}. The app may fail to connect to DB."
fi

# --- Configure Spring Boot application.properties ---
APP_RESOURCES_DIR="${APP_PROJECT_DIR}/app/src/main/resources"
APP_PROPS="${APP_RESOURCES_DIR}/application.properties"

if [ -f "$APP_PROPS" ]; then
  echo "[APP] Configuring application.properties for H2 at ${DB_HOST}:9092"
  sudo sed -i \
    -e "s|^spring.datasource.url=.*|spring.datasource.url=jdbc:h2:tcp://${DB_HOST}:9092/./payrolldb|" \
    -e "s|^spring.datasource.driverClassName=.*|spring.datasource.driverClassName=org.h2.Driver|" \
    -e "s|^spring.datasource.username=.*|spring.datasource.username=sa|" \
    -e "s|^spring.datasource.password=.*|spring.datasource.password=password|" \
    -e "s|^spring.jpa.hibernate.ddl-auto=.*|spring.jpa.hibernate.ddl-auto=update|" \
    "$APP_PROPS"
else
  echo "[APP][WARN] application.properties not found at ${APP_PROPS}."
fi

# --- Build application ---
if [ "${BUILD_APP}" = "true" ]; then
  echo "[APP] Building Spring Boot application..."
  pushd "$APP_PROJECT_DIR" >/dev/null
  ./gradlew bootJar || (echo "[APP][ERROR] Gradle build failed" && exit 1)
  popd >/dev/null
else
  echo "[APP] Skipping build (BUILD_APP=${BUILD_APP})"
fi

# --- Find built JAR ---
APP_JAR=$(find "${APP_PROJECT_DIR}/app/build/libs" -maxdepth 1 -name "*.jar" | head -n 1)
if [ -z "$APP_JAR" ]; then
  echo "[APP][ERROR] No JAR found under ${APP_PROJECT_DIR}/app/build/libs"
  exit 1
fi
echo "[APP] Using jar: $(basename "$APP_JAR")"

# --- Wait for DB service readiness ---
echo "[APP] Waiting for H2 DB (${DB_HOST}:9092)..."
for i in $(seq 1 60); do
  if nc -z "${DB_HOST}" 9092 2>/dev/null; then
    echo "[APP] H2 is up."
    break
  fi
  echo "[APP] H2 not ready yet... (${i}/60)"
  sleep 2
done

# --- Systemd service for the app ---
sudo tee /etc/systemd/system/ca3-app.service >/dev/null <<SERVICE
[Unit]
Description=CA3 Spring Boot App
After=network.target h2.service

[Service]
User=vagrant
WorkingDirectory=${APP_PROJECT_DIR}
ExecStart=/usr/bin/java -jar ${APP_JAR}
Restart=on-failure
RestartSec=5
Environment=JAVA_TOOL_OPTIONS=-XX:+UseG1GC

[Install]
WantedBy=multi-user.target
SERVICE

sudo systemctl daemon-reload
if [ "${START_APP}" = "true" ]; then
  echo "[APP] Starting application service..."
  sudo systemctl enable --now ca3-app
else
  echo "[APP] Skipping app start (START_APP=${START_APP})"
fi

echo "[APP] ✅ Done. App reachable at http://localhost:8080"
