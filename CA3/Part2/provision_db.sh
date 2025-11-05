#!/usr/bin/env bash
set -euo pipefail

APP_HOST=${APP_HOST:-ca3-app.cogsi}
START_DB=${START_DB:-true}

echo "[DB] Updating packages..."
sudo apt-get update -y
sudo apt-get install -y openjdk-17-jre-headless ufw curl unzip dnsutils

H2_VERSION="2.3.232"
H2_DIR="/opt/h2"
H2_JAR="${H2_DIR}/h2-${H2_VERSION}.jar"

if [ ! -f "$H2_JAR" ]; then
  echo "[DB] Installing H2 ${H2_VERSION}..."
  sudo mkdir -p "$H2_DIR"
  sudo curl -fsSL -o "$H2_JAR" "https://repo1.maven.org/maven2/com/h2database/h2/${H2_VERSION}/h2-${H2_VERSION}.jar"
  sudo chmod 0644 "$H2_JAR"
fi

sudo mkdir -p /data/h2
sudo chown vagrant:vagrant /data/h2

SQL_FILE="/tmp/init_payrolldb.sql"
cat > "${SQL_FILE}" <<'SQL'
-- minimal init: create a marker table so H2 creates the DB files
CREATE TABLE IF NOT EXISTS payroll_init (
  id INT PRIMARY KEY,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);
SQL

# Run as vagrant so files are owned correctly; use the local (filesystem) JDBC URL to create files under /data/h2
sudo -u vagrant /usr/bin/java -cp "${H2_JAR}" org.h2.tools.RunScript \
  -url "jdbc:h2:/data/h2/payrolldb" -user sa -password password -script "${SQL_FILE}" || true
rm -f "${SQL_FILE}"

# Create systemd service for H2 server mode
cat << SERVICE | sudo tee /etc/systemd/system/h2.service >/dev/null
[Unit]
Description=H2 Database Server
After=network.target

[Service]
User=vagrant
ExecStart=/usr/bin/java -cp ${H2_JAR} org.h2.tools.Server -tcp -tcpAllowOthers -tcpPort 9092 -baseDir /data/h2
Restart=on-failure

[Install]
WantedBy=multi-user.target
SERVICE

# --- Resolve the App hostname to IP ---
echo "[DB] Resolving app hostname: ${APP_HOST}"
for i in {1..10}; do
  APP_IP=$(getent ahostsv4 "${APP_HOST}" | awk '{print $1; exit}') || true
  if [[ -n "${APP_IP}" ]]; then
    echo "[DB] Resolved ${APP_HOST} -> ${APP_IP}"
    break
  fi
  echo "[DB] Waiting for ${APP_HOST} DNS entry..."
  sleep 2
done

if [[ -z "${APP_IP:-}" ]]; then
  echo "[DB][WARN] Could not resolve ${APP_HOST}, opening H2 port on private network interface instead."
  PRIV_IF=$(ip -o -4 addr show | awk '$2!="lo" && $4!~/^10\.0\.2\./ {print $2; exit}')
fi

echo "[DB] Enabling firewall..."
sudo ufw --force enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH

if [[ -n "${APP_IP:-}" ]]; then
  sudo ufw allow from "${APP_IP}" to any port 9092 proto tcp
else
  sudo ufw allow in on "${PRIV_IF}" to any port 9092 proto tcp
fi

sudo systemctl daemon-reload
if [ "${START_DB}" = "true" ]; then
  echo "[DB] Starting H2 service..."
  sudo systemctl enable --now h2
else
  echo "[DB] Skipping H2 service start due to START_DB=${START_DB}"
fi

echo "[DB] Done. H2 should be reachable from ${APP_HOST} (${APP_IP:-unknown}):9092 only."