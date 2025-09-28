#!/bin/bash

set -e

# Ensure required variables are set
if [ -z "$github_repo" ] || [ -z "$github_token" ]; then
  echo "Error: github_repo and github_token variables must be set."
  exit 1
fi

# Install dependencies
apt-get update -y
apt-get install -y curl jq git

# Create runner user if not exists
id -u runner &>/dev/null || useradd -m runner

# Create runner directory and set permissions
mkdir -p /home/runner/actions-runner
chown runner:runner /home/runner/actions-runner
cd /home/runner/actions-runner

# Download and extract GitHub Actions runner
sudo -u runner curl -o actions-runner-linux-x64-2.328.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.328.0/actions-runner-linux-x64-2.328.0.tar.gz
sudo -u runner tar xzf ./actions-runner-linux-x64-2.328.0.tar.gz

# Configure the runner
sudo -u runner ./config.sh --url "$github_repo" --token "$github_token"

# Run the runner in the background (as a service)
sudo -u runner nohup ./run.sh &

echo "GitHub Actions runner setup complete."
