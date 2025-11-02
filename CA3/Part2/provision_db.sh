#!/usr/bin/env bash
set -euo pipefail

APP_IP=${APP_IP:-192.168.244.167}
START_DB=${START_DB:-true}

echo "[DB] Updating packages..."
sudo apt-get update -y
sudo apt-get install -y openjdk-17-jre-headless ufw curl unzip netcat

H2_VERSION="2.3.232"
H2_DIR="/opt/h2"
H2_JAR="${H2_DIR}/h2-${H2_VERSION}.jar"

# --- Add custom SSH key ---
if [ -f /home/vagrant/db_ssh.pub ]; then
  echo "[DB] Adding custom SSH key..."
  mkdir -p /home/vagrant/.ssh
  grep -qxF "$(cat /home/vagrant/db_ssh.pub)" /home/vagrant/.ssh/authorized_keys || cat /home/vagrant/db_ssh.pub >> /home/vagrant/.ssh/authorized_keys
  chown -R vagrant:vagrant /home/vagrant/.ssh
  chmod 700 /home/vagrant/.ssh
  chmod 600 /home/vagrant/.ssh/authorized_keys
fi

# --- Install H2 ---
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
CREATE TABLE IF NOT EXISTS payroll_init (
  id INT PRIMARY KEY,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);
SQL

sudo -u vagrant /usr/bin/java -cp "${H2_JAR}" org.h2.tools.RunScript \
  -url "jdbc:h2:/data/h2/payrolldb" -user sa -password password -script "${SQL_FILE}" || true
rm -f "${SQL_FILE}"

# --- Systemd service ---
sudo tee /etc/systemd/system/h2.service >/dev/null <<SERVICE
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

# --- Firewall ---
echo "[DB] Configuring firewall..."
sudo ufw --force enable
sudo ufw default deny incoming
sudo ufw allow OpenSSH
sudo ufw allow from "${APP_IP}" to any port 9092 proto tcp

sudo systemctl daemon-reload
if [ "${START_DB}" = "true" ]; then
  echo "[DB] Starting H2 service..."
  sudo systemctl enable --now h2
else
  echo "[DB] Skipping H2 start due to START_DB=${START_DB}"
fi

echo "[DB] Done. H2 reachable from ${APP_IP}:9092 only."
