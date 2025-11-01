#!/bin/bash

CLONE_REPO="${CLONE_REPO:-true}"
BUILD_PROJECT="${BUILD_PROJECT:-true}"
START_SERVICES="${START_SERVICES:-true}"

# Install necessary packages and show versions for validation
sudo apt-get update -y
sudo apt-get install -y git openjdk-17-jdk maven gradle
java -version
javac -version
mvn -v
gradle -v

REPO_NAME="cogsi2526-1240444-1211426-1211689"
REPO_ROOT="/vagrant/${REPO_NAME}"

if [ "$CLONE_REPO" = true ]; then
  mkdir -p /vagrant
  if [ ! -d "$REPO_ROOT/.git" ]; then
    echo "[provision] Cloning repository into $REPO_ROOT"
    git clone https://github.com/davidsferreira02/cogsi2526-1240444-1211426-1211689.git "$REPO_ROOT"
  else
    echo "[provision] Repository already exists, pulling latest changes."
    git -C "$REPO_ROOT" pull --ff-only
  fi
else
  echo "[provision] Repository sync skipped."
fi

sudo mkdir -p /vagrant/data/h2
sudo chown -R vagrant:vagrant /vagrant/data/h2

if [ "$BUILD_PROJECT" = true ]; then
  if [ ! -d "$REPO_ROOT" ]; then
    echo "[provision] Repository missing at $REPO_ROOT, cannot build." >&2
    exit 1
  fi

  sudo apt-get install -y xvfb
  git -C "$REPO_ROOT" switch VagrantRepoInstall

  PART1_DIR="$REPO_ROOT/CA2/Part1/gradle_basic_demo-main"
  if [ -d "$PART1_DIR" ]; then
    echo "[provision] Building Part1 in $PART1_DIR"
    (cd "$PART1_DIR" && xvfb-run ./gradlew build)
  else
    echo "[provision] Skipped Part1 build, directory not found: $PART1_DIR"
  fi

  PART2_DIR="$REPO_ROOT/CA2/Part2"
  if [ -d "$PART2_DIR" ]; then
    echo "[provision] Building Part2 in $PART2_DIR"
    (cd "$PART2_DIR" && ./gradlew bootJar)
  else
    echo "[provision] Skipped Part2 build, directory not found: $PART2_DIR"
  fi
else
  echo "[provision] Project build skipped."
fi

if [ true = true ]; then
  echo "[provision] Starting services..."
  
  # Start Chat Server (Part1) in background
  PART1_DIR="$REPO_ROOT/CA2/Part1/gradle_basic_demo-main"
  if [ -d "$PART1_DIR" ]; then
    echo "[provision] Starting Chat Server on port 59001..."
    cd "$PART1_DIR"
    nohup ./gradlew runServer > /vagrant/chat-server.log 2>&1 &
    echo "[provision] Chat Server started. Logs: /vagrant/chat-server.log"
  else
    echo "[provision] Part1 directory not found, skipping Chat Server"
  fi

  # Start Spring Boot Payroll App (Part2) in background
  PART2_DIR="$REPO_ROOT/CA2/Part2"
  if [ -d "$PART2_DIR" ]; then
    echo "[provision] Starting Spring Boot Payroll application on port 8080..."
    cd "$PART2_DIR"
    SPRING_DATASOURCE_URL=jdbc:h2:/vagrant/data/h2/payroll \
    SPRING_H2_CONSOLE_ENABLED=true \
    nohup ./gradlew bootRun > /vagrant/payroll-app.log 2>&1 &
    echo "[provision] Payroll application started. Logs: /vagrant/payroll-app.log"
    echo "[provision] H2 Console: http://localhost:8080/h2-console"
  else
    echo "[provision] Part2 directory not found, skipping Payroll App"
  fi
  
  echo "[provision] Services started in background."
else
  echo "[provision] Service startup skipped."
fi
