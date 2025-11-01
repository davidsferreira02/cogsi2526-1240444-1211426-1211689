#!/usr/bin/env bash
set -euo pipefail

DB_IP=${DB_IP:-192.168.56.10}
BUILD_APP=${BUILD_APP:-true}
START_APP=${START_APP:-true}
APP_PROJECT_DIR=${APP_PROJECT_DIR:-/workspace/CA2/Part2}

echo "[APP] Updating packages..."
sudo apt-get update -y
sudo apt-get install -y openjdk-17-jdk maven gradle curl jq netcat

# Ensure app properties point to H2 server mode
APP_RESOURCES_DIR="${APP_PROJECT_DIR}/app/src/main/resources"
APP_PROPS="${APP_RESOURCES_DIR}/application.properties"

if [ -f "$APP_PROPS" ]; then
  echo "[APP] Configuring application.properties to use H2 server at ${DB_IP}:9092"
  sudo sed -i \
    -e "s|^spring.datasource.url=.*|spring.datasource.url=jdbc:h2:tcp://${DB_IP}:9092/./payrolldb|" \
    -e "s|^spring.datasource.driverClassName=.*|spring.datasource.driverClassName=org.h2.Driver|" \
    -e "s|^spring.datasource.username=.*|spring.datasource.username=sa|" \
    -e "s|^spring.datasource.password=.*|spring.datasource.password=password|" \
    -e "s|^spring.jpa.hibernate.ddl-auto=.*|spring.jpa.hibernate.ddl-auto=update|" \
    "$APP_PROPS"
else
  echo "[APP][WARN] application.properties not found at ${APP_PROPS}. Skipping DB URL update."
fi

if [ "${BUILD_APP}" = "true" ]; then
  echo "[APP] Building Spring Boot application..."
  pushd "$APP_PROJECT_DIR" >/dev/null
  ./gradlew bootJar
  popd >/dev/null
else
  echo "[APP] Skipping build due to BUILD_APP=${BUILD_APP}"
fi

# Wait for H2 server readiness
echo "[APP] Waiting for H2 server at ${DB_IP}:9092..."
for i in $(seq 1 60); do
  if nc -z "${DB_IP}" 9092 2>/dev/null; then
    echo "[APP] H2 is up."
    break
  fi
  echo "[APP] H2 not ready yet... (${i}/60)"
  sleep 2
done

# Create a systemd service to run the Spring Boot app
# Use deterministic jar name produced by Gradle bootJar configuration
APP_JAR="${APP_PROJECT_DIR}/app/build/libs/app.jar"
if [ ! -f "$APP_JAR" ]; then
  echo "[APP][ERROR] Expected Spring Boot jar not found at ${APP_JAR}. Aborting service creation."
  ls -l "${APP_PROJECT_DIR}/app/build/libs" || true
  exit 1
fi

sudo tee /etc/systemd/system/ca3-app.service >/dev/null <<SERVICE
[Unit]
Description=CA3 Spring Boot App
After=network.target

[Service]
User=vagrant
WorkingDirectory=${APP_PROJECT_DIR}
ExecStartPre=/bin/bash -c '/usr/bin/timeout 60 bash -c "until nc -z ${DB_IP} 9092; do sleep 2; done"'
ExecStart=/usr/bin/java -jar ${APP_JAR}
Restart=on-failure
Environment=JAVA_TOOL_OPTIONS=-XX:+UseG1GC

[Install]
WantedBy=multi-user.target
SERVICE

sudo systemctl daemon-reload
if [ "${START_APP}" = "true" ]; then
  echo "[APP] Starting application service..."
  sudo systemctl enable --now ca3-app
else
  echo "[APP] Skipping app start due to START_APP=${START_APP}"
fi

echo "[APP] Done. App should be reachable on host at http://localhost:8080"
