#!/bin/bash
set -e

# Verified Versions for February 2026
NERDCTL_VER="2.2.1"
CNI_VER="1.6.2"

# Function to safely wait for the apt lock
wait_for_apt() {
    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; do
        echo "Waiting for Ubuntu's background update to finish (apt lock)..."
        sleep 5
    done
}

echo "--- Installing Containerd, Nerdctl, and CNI Plugins ---"

# 1. Setup Docker Repository
wait_for_apt
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 2. Install containerd.io
wait_for_apt
sudo apt-get update
sudo apt-get install -y containerd.io
sudo systemctl enable --now containerd

# 3. Allow non-root access to containerd socket (ctr/nerdctl)
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

# 4. Install CNI Plugins (Crucial for Networking)
echo "Downloading CNI Plugins v${CNI_VER}..."
sudo mkdir -p /opt/cni/bin
CNI_URL="https://github.com/containernetworking/plugins/releases/download/v${CNI_VER}/cni-plugins-linux-amd64-v${CNI_VER}.tgz"
curl -L -f -o cni-plugins.tgz "$CNI_URL"
sudo tar -C /opt/cni/bin -xzf cni-plugins.tgz
rm cni-plugins.tgz

# 5. Install nerdctl
echo "Downloading nerdctl v${NERDCTL_VER}..."
NERD_URL="https://github.com/containerd/nerdctl/releases/download/v${NERDCTL_VER}/nerdctl-${NERDCTL_VER}-linux-amd64.tar.gz"
curl -L -f -o nerdctl.tar.gz "$NERD_URL"
sudo tar Cxzf /usr/local/bin nerdctl.tar.gz nerdctl
rm nerdctl.tar.gz

# 6. Final Verification
echo "--------------------------------"
echo "Containerd Status: $(systemctl is-active containerd)"
echo "Nerdctl Version (group test):"
sg containerd -c "nerdctl --version" || true
echo "Note: If the group test fails, run 'newgrp containerd' or re-login."
echo "CNI Plugins in /opt/cni/bin:"
ls /opt/cni/bin | grep -E 'bridge|loopback|host-local'
