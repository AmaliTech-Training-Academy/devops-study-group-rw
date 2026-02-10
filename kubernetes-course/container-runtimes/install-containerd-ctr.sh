#!/bin/bash
set -e

# Function to safely wait for the apt lock
wait_for_apt() {
    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; do
        echo "Waiting for Ubuntu's background update to finish (apt lock)..."
        sleep 5
    done
}

echo "--- Installing Containerd (ctr included) ---"

# 1. Setup Docker Repository
wait_for_apt
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 2. Install containerd.io (includes ctr)
wait_for_apt
sudo apt-get update
sudo apt-get install -y containerd.io
sudo systemctl enable --now containerd

# 3. Final Verification
echo "--------------------------------"
echo "Containerd Status: $(systemctl is-active containerd)"
echo "ctr Version: $(ctr --version)"
