#!/bin/bash
set -e

# Verified Versions for February 2026
CNI_VER="1.6.2"
NERDCTL_VER="2.2.1"

# Function to safely wait for the apt lock
wait_for_apt() {
    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; do
        echo "Waiting for Ubuntu's background update to finish (apt lock)..."
        sleep 5
    done
}

echo "--- Installing CNI Plugins and nerdctl ---"

# 1. Install CNI Plugins
echo "Downloading CNI Plugins v${CNI_VER}..."
sudo mkdir -p /opt/cni/bin
CNI_URL="https://github.com/containernetworking/plugins/releases/download/v${CNI_VER}/cni-plugins-linux-amd64-v${CNI_VER}.tgz"
curl -L -f -o cni-plugins.tgz "$CNI_URL"
sudo tar -C /opt/cni/bin -xzf cni-plugins.tgz
rm cni-plugins.tgz

# 2. Install nerdctl
wait_for_apt
echo "Downloading nerdctl v${NERDCTL_VER}..."
NERD_URL="https://github.com/containerd/nerdctl/releases/download/v${NERDCTL_VER}/nerdctl-${NERDCTL_VER}-linux-amd64.tar.gz"
curl -L -f -o nerdctl.tar.gz "$NERD_URL"
sudo tar Cxzf /usr/local/bin nerdctl.tar.gz nerdctl
rm nerdctl.tar.gz

# 3. Ensure containerd group access for nerdctl
CONTAINERD_GROUP="containerd"
TARGET_USER="${SUDO_USER:-$USER}"

if getent group "$CONTAINERD_GROUP" >/dev/null 2>&1; then
    # Add user to containerd group if not already a member
    if ! groups "$TARGET_USER" | grep -q "\b$CONTAINERD_GROUP\b"; then
        sudo usermod -aG "$CONTAINERD_GROUP" "$TARGET_USER"
        echo "Added $TARGET_USER to $CONTAINERD_GROUP group"
    fi
    
    # Verify socket permissions if containerd is running
    if [ -S /run/containerd/containerd.sock ]; then
        sudo chgrp containerd /run/containerd/containerd.sock
        sudo chmod 660 /run/containerd/containerd.sock
    fi
fi

# 4. Final Verification
echo "--------------------------------"
echo "Nerdctl Version (group test):"
if getent group "$CONTAINERD_GROUP" >/dev/null 2>&1; then
    sg containerd -c "nerdctl --version" || echo "Group access not yet active - run 'newgrp containerd' or re-login"
else
    echo "$(nerdctl --version) (no containerd group - may require sudo)"
fi
echo "CNI Plugins in /opt/cni/bin:"
ls /opt/cni/bin | grep -E 'bridge|loopback|host-local'
echo "Note: nerdctl requires a running containerd."
