#!/bin/bash

#############################################
# Kubeadm Installation Script (Kubernetes 1.35)
# Installs kubeadm - the cluster bootstrapping tool
# Kubeadm initializes and joins nodes to cluster
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
echo -e "${BLUE}Kubeadm Installation (K8s ${K8S_VERSION})${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}" 
   exit 1
fi

# Check if kubelet is installed
if ! command -v kubelet &> /dev/null; then
    echo -e "${RED}Error: Kubelet is not installed!${NC}"
    echo "Please install kubelet first:"
    echo "  Run: ./02-install-kubelet.sh"
    exit 1
fi

# Check if kubeadm is already installed
if command -v kubeadm &> /dev/null; then
    echo -e "${YELLOW}Kubeadm is already installed${NC}"
    kubeadm version
    read -p "Do you want to reinstall? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Step 1: Check if repository exists
echo -e "${YELLOW}[1/3] Checking Kubernetes repository...${NC}"

if [ ! -f /etc/apt/sources.list.d/kubernetes.list ]; then
    echo -e "${YELLOW}Kubernetes repository not found. Adding it...${NC}"
    
    mkdir -p /etc/apt/keyrings
    
    curl -fsSL https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key | \
        gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ /" | \
        tee /etc/apt/sources.list.d/kubernetes.list
    
    echo -e "${GREEN}✓ Repository added${NC}"
else
    echo -e "${GREEN}✓ Repository already exists${NC}"
fi

# Step 2: Install kubeadm
echo -e "${YELLOW}[2/3] Installing kubeadm...${NC}"
apt-get update -y
apt-get install -y kubeadm

# Hold kubeadm to prevent automatic updates
apt-mark hold kubeadm

echo -e "${GREEN}✓ Kubeadm installed and held at current version${NC}"

# Step 3: Verify installation
echo -e "${YELLOW}[3/3] Verifying installation...${NC}"

# Check binary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Kubeadm Installation Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo "Kubeadm version:"
kubeadm version -o short

echo ""
echo "Kubeadm binary info:"
ls -lh $(which kubeadm)
file $(which kubeadm)

echo ""
echo "Kubeadm is a single compiled binary containing:"
echo "  - init (initialize master node)"
echo "  - join (join worker nodes)"
echo "  - upgrade (upgrade cluster)"
echo "  - reset (reset node)"
echo "  - token (manage tokens)"
echo "  - certs (manage certificates)"

echo ""
echo -e "${YELLOW}Pre-flight checks:${NC}"
kubeadm init phase preflight 2>&1 | head -10 || true

echo ""
echo -e "${YELLOW}What kubeadm will do:${NC}"
echo "  Master node: kubeadm init --pod-network-cidr=10.244.0.0/16"
echo "  Worker node: kubeadm join <master-ip>:6443 --token <token> --discovery-token-ca-cert-hash <hash>"

echo ""
echo -e "${YELLOW}Important for K8s 1.35:${NC}"
echo "  - Cgroup v2 required (cgroup v1 support removed)"
echo "  - Containerd 2.x recommended (1.x deprecated)"
if [ $(swapon -s | wc -l) -gt 0 ]; then
    echo "  - Swap support: ENABLED (LimitedSwap mode)"
else
    echo "  - Swap: Disabled (traditional approach)"
fi

echo ""
echo "Next step: Install kubectl (optional but recommended)"
echo "  Run: ./04-install-kubectl.sh"
echo ""
echo "Or initialize cluster:"
echo "  Master: sudo kubeadm init --pod-network-cidr=10.244.0.0/16"