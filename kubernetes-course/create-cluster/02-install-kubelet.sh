#!/bin/bash

#############################################
# Kubelet Installation Script (Kubernetes 1.35)
# Installs kubelet - the node agent
# Kubelet runs on every node and manages containers
#############################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Kubernetes version
K8S_VERSION="v1.35"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Kubelet Installation (K8s ${K8S_VERSION})${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}" 
   exit 1
fi

# Check if container runtime is installed
if ! systemctl is-active --quiet containerd; then
    echo -e "${RED}Error: Containerd is not running!${NC}"
    echo "Please install and start containerd first:"
    echo "  Run: ./01-install-containerd.sh"
    exit 1
fi

# Check containerd version
CONTAINERD_VERSION=$(containerd --version | awk '{print $3}')
if [[ $CONTAINERD_VERSION == v1.* ]]; then
    echo -e "${YELLOW}⚠ WARNING: Containerd 1.x detected${NC}"
    echo "Kubernetes 1.36+ will require containerd 2.x"
    echo "Consider upgrading containerd"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if kubelet is already installed
if command -v kubelet &> /dev/null; then
    echo -e "${YELLOW}Kubelet is already installed${NC}"
    kubelet --version
    read -p "Do you want to reinstall? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Step 1: Add Kubernetes repository
echo -e "${YELLOW}[1/4] Adding Kubernetes repository...${NC}"

# Create keyrings directory
mkdir -p /etc/apt/keyrings

# Download GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key | \
    gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add repository
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ /" | \
    tee /etc/apt/sources.list.d/kubernetes.list

echo -e "${GREEN}✓ Kubernetes repository added${NC}"

# Step 2: Install kubelet
echo -e "${YELLOW}[2/4] Installing kubelet...${NC}"
apt-get update -y
apt-get install -y kubelet

# Hold kubelet to prevent automatic updates
apt-mark hold kubelet

echo -e "${GREEN}✓ Kubelet installed and held at current version${NC}"

# Step 3: Configure kubelet for swap (if swap is enabled)
echo -e "${YELLOW}[3/4] Configuring kubelet...${NC}"

if [ $(swapon -s | wc -l) -gt 0 ]; then
    echo -e "${YELLOW}⚠ Swap is enabled${NC}"
    echo "Configuring kubelet for LimitedSwap mode (K8s 1.34+ feature)"
    
    mkdir -p /var/lib/kubelet
    cat <<EOF | tee /var/lib/kubelet/config.yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
failSwapOn: false
memorySwap:
  swapBehavior: LimitedSwap
EOF
    echo -e "${GREEN}✓ Kubelet configured for swap support${NC}"
else
    echo -e "${GREEN}✓ Swap disabled, using default kubelet configuration${NC}"
fi

# Step 4: Enable kubelet service
echo -e "${YELLOW}[4/4] Enabling kubelet service...${NC}"
systemctl enable kubelet

echo -e "${GREEN}✓ Kubelet service enabled${NC}"

# Verify installation
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Kubelet Installation Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo "Kubelet version:"
kubelet --version

echo ""
echo "Kubelet service status:"
systemctl status kubelet --no-pager | head -10

echo ""
echo -e "${YELLOW}Important Notes:${NC}"
echo "  - Kubelet service is enabled but NOT running yet"
echo "  - This is NORMAL - kubelet waits for cluster initialization"
echo "  - Kubelet will start automatically after 'kubeadm init' or 'kubeadm join'"

if [ $(swapon -s | wc -l) -gt 0 ]; then
    echo "  - Swap support: ENABLED (LimitedSwap mode)"
    echo "  - Config: /var/lib/kubelet/config.yaml"
fi

echo ""
echo "Expected logs before cluster init:"
echo "  'Waiting for node to be registered'"
echo "  'Unable to read config path'"
echo "These are NORMAL and expected"

echo ""
echo -e "${YELLOW}What kubelet needs to run properly:${NC}"
echo "  1. ✓ Container runtime (containerd) - installed"
echo "  2. ✗ Cluster configuration (from kubeadm) - pending"
echo "  3. ✗ CNI plugin (for networking) - pending"
echo ""
echo "Next step: Install kubeadm"
echo "  Run: ./03-install-kubeadm.sh"