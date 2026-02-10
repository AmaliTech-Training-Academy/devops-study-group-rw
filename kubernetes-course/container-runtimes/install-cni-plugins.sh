#!/bin/bash
set -e

# Verified Versions for February 2026
CNI_VER="1.6.2"

echo "--- Installing CNI Plugins ---"

# 1. Install CNI Plugins
echo "Downloading CNI Plugins v${CNI_VER}..."
sudo mkdir -p /opt/cni/bin
CNI_URL="https://github.com/containernetworking/plugins/releases/download/v${CNI_VER}/cni-plugins-linux-amd64-v${CNI_VER}.tgz"
curl -L -f -o cni-plugins.tgz "$CNI_URL"
sudo tar -C /opt/cni/bin -xzf cni-plugins.tgz
rm cni-plugins.tgz

# 2. Final Verification
echo "--------------------------------"
echo "CNI Plugins in /opt/cni/bin:"
ls /opt/cni/bin | grep -E 'bridge|loopback|host-local'
