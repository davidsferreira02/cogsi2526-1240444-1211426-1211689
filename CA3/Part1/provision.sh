#!/bin/bash

# Install necessary packages and show versions for validation
sudo apt-get update -y
sudo apt-get install -y git default-jdk maven gradle
java -version
javac -version
mvn -v
gradle -v

cd /vagrant
if [ ! -d "cogsi2526-1240444-1211426-1211689" ]; then
  git clone https://github.com/davidsferreira02/cogsi2526-1240444-1211426-1211689.git cogsi2526-1240444-1211426-1211689
else
  cd cogsi2526-1240444-1211426-1211689
  git pull
fi