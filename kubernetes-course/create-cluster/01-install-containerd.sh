#!/bin/bash

#############################################
# Containerd Installation Script (FIXED)
# Installs: containerd + nerdctl + CNI plugins
# Fixed: CNI download URL issue
#############################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Containerd Installation${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Which version do you want to install?"
echo ""
echo -e "${GREEN}1)${NC} containerd 1.7.30 ${YELLOW}(LTS - Production)${NC}"
echo -e "${GREEN}2)${NC} containerd 2.2.1 ${YELLOW}(Latest)${NC}"
echo ""
read -p "Enter choice [1 or 2]: " VERSION_CHOICE

case $VERSION_CHOICE in
    1)
        CONTAINERD_VERSION="1.7.30"
        VERSION_TYPE="LTS"
        ;;
    2)
        CONTAINERD_VERSION="2.2.1"
        VERSION_TYPE="Latest"
        ;;
    *)
        echo "Defaulting to 1.7.30 (LTS)"
        CONTAINERD_VERSION="1.7.30"
        VERSION_TYPE="LTS"
        ;;
esac

# Component versions
RUNC_VERSION="1.2.3"
CNI_PLUGINS_VERSION="1.6.1"      # Note: 1.6.1 has issues, use 1.7.1
NERDCTL_VERSION="2.0.3"
PAUSE_IMAGE="registry.k8s.io/pause:3.10.1"

echo ""
echo "Installing:"
echo "  Containerd: ${CONTAINERD_VERSION} (${VERSION_TYPE})"
echo "  Runc: ${RUNC_VERSION}"
echo "  CNI Plugins: ${CNI_PLUGINS_VERSION}"
echo "  Nerdctl: ${NERDCTL_VERSION}"
echo -e "${BLUE}========================================${NC}"

# Check root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Run as root${NC}"
   exit 1
fi

# Check if already installed
if command -v containerd &> /dev/null; then
    CURRENT=$(containerd --version | awk '{print $3}' | sed 's/v//')
    echo -e "${YELLOW}Already installed: v${CURRENT}${NC}"
    read -p "Reinstall? (y/N) " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
    systemctl stop containerd 2>/dev/null || true
fi

cd /tmp

# ============================================
# STEP 1: Install containerd
# ============================================
echo -e "${YELLOW}[1/8] Installing containerd...${NC}"

CONTAINERD_URL="https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz"

curl -L -O "${CONTAINERD_URL}"
tar Cxzvf /usr/local containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz
rm -f containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz

echo -e "${GREEN}✓ Containerd installed${NC}"

# ============================================
# STEP 2: Install runc
# ============================================
echo -e "${YELLOW}[2/8] Installing runc...${NC}"

RUNC_URL="https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.amd64"
curl -L -o /usr/local/sbin/runc "${RUNC_URL}"
chmod +x /usr/local/sbin/runc

echo -e "${GREEN}✓ Runc installed${NC}"

# ============================================
# STEP 3: Install CNI plugins (FIXED!)
# ============================================
echo -e "${YELLOW}[3/8] Installing CNI plugins...${NC}"

# IMPORTANT NOTE: Version 1.6.1 had duplicate release issues
# Use 1.7.1 instead for better stability
CNI_ACTUAL_VERSION="1.7.1"
echo "Note: Using CNI v${CNI_ACTUAL_VERSION} (1.6.1 had release issues)"

# Correct URL format with .tgz extension
CNI_URL="https://github.com/containernetworking/plugins/releases/download/v${CNI_ACTUAL_VERSION}/cni-plugins-linux-amd64-v${CNI_ACTUAL_VERSION}.tgz"

echo "Downloading: ${CNI_URL}"

mkdir -p /opt/cni/bin

# Download and extract
curl -L "${CNI_URL}" | tar -C /opt/cni/bin -xz

# Verify
if [ -f /opt/cni/bin/bridge ]; then
    PLUGIN_COUNT=$(ls /opt/cni/bin | wc -l)
    echo -e "${GREEN}✓ CNI plugins installed (${PLUGIN_COUNT} plugins)${NC}"
else
    echo -e "${RED}✗ Failed to install CNI plugins${NC}"
    exit 1
fi

# ============================================
# STEP 4: Install nerdctl
# ============================================
echo -e "${YELLOW}[4/8] Installing nerdctl...${NC}"

NERDCTL_URL="https://github.com/containerd/nerdctl/releases/download/v${NERDCTL_VERSION}/nerdctl-${NERDCTL_VERSION}-linux-amd64.tar.gz"
curl -L "${NERDCTL_URL}" | tar -C /usr/local/bin -xz nerdctl
chmod +x /usr/local/bin/nerdctl

echo -e "${GREEN}✓ Nerdctl installed${NC}"

# ============================================
# STEP 5: Create systemd service
# ============================================
echo -e "${YELLOW}[5/8] Creating systemd service...${NC}"

cat <<'EOF' > /etc/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
echo -e "${GREEN}✓ Service created${NC}"

# ============================================
# STEP 6: Configure containerd
# ============================================
echo -e "${YELLOW}[6/8] Configuring containerd...${NC}"

mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml

# Fix SystemdCgroup
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Fix pause image
sed -i "s|sandbox_image = \".*\"|sandbox_image = \"${PAUSE_IMAGE}\"|" /etc/containerd/config.toml

echo -e "${GREEN}✓ Configured${NC}"

# ============================================
# STEP 7: Pull pause image
# ============================================
echo -e "${YELLOW}[7/8] Pulling pause image...${NC}"

systemctl start containerd
sleep 3

/usr/local/bin/ctr image pull ${PAUSE_IMAGE}
echo -e "${GREEN}✓ Pause image ready${NC}"

# ============================================
# STEP 8: Enable service
# ============================================
echo -e "${YELLOW}[8/8] Enabling service...${NC}"

systemctl enable containerd
systemctl restart containerd
sleep 3

echo -e "${GREEN}✓ Service running${NC}"

# ============================================
# Verification
# ============================================
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${BLUE}========================================${NC}"

containerd --version
runc --version | head -1
nerdctl --version

echo ""
echo "CNI Plugins (in /opt/cni/bin):"
ls -1 /opt/cni/bin | nl

echo ""
echo "Configuration:"
grep "SystemdCgroup = true" /etc/containerd/config.toml && echo "✓ Systemd cgroup"
grep "sandbox_image" /etc/containerd/config.toml | head -1

echo ""
systemctl status containerd --no-pager | head -5

echo ""
echo -e "${GREEN}Ready for Kubernetes!${NC}"
echo "Next: ./02-install-kubelet.sh"