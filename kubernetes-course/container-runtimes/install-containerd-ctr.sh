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

# 3. Allow non-root access to containerd socket (ctr)
CONTAINERD_GROUP="containerd"
TARGET_USER="${SUDO_USER:-$USER}"

if ! getent group "$CONTAINERD_GROUP" >/dev/null 2>&1; then
    sudo groupadd --system "$CONTAINERD_GROUP"
fi

sudo usermod -aG "$CONTAINERD_GROUP" "$TARGET_USER"

sudo mkdir -p /etc/systemd/system/containerd.service.d
sudo tee /etc/systemd/system/containerd.service.d/10-socket-permissions.conf > /dev/null <<'EOF'
[Service]
ExecStartPost=/bin/sh -c 'for i in 1 2 3 4 5; do [ -S /run/containerd/containerd.sock ] && break || sleep 1; done; chgrp containerd /run/containerd/containerd.sock; chmod 660 /run/containerd/containerd.sock'
EOF

sudo systemctl daemon-reload
sudo systemctl restart containerd

# Wait for socket to be ready and permissions applied
sleep 2

# Verify socket permissions
if [ -S /run/containerd/containerd.sock ]; then
    sudo chgrp containerd /run/containerd/containerd.sock
    sudo chmod 660 /run/containerd/containerd.sock
fi

# 4. Final Verification
echo "--------------------------------"
echo "Containerd Status: $(systemctl is-active containerd)"
echo "ctr Version (group test):"
sg containerd -c "ctr --version" || true
echo "Note: If the group test fails, run 'newgrp containerd' or re-login."
