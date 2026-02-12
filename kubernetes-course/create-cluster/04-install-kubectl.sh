#!/bin/bash

#############################################
# Kubectl Installation Script (Kubernetes 1.35)
# Installs kubectl - the Kubernetes CLI tool
# Kubectl is used to manage and interact with clusters
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
echo -e "${BLUE}Kubectl Installation (K8s ${K8S_VERSION})${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}" 
   exit 1
fi

# Check if kubectl is already installed
if command -v kubectl &> /dev/null; then
    echo -e "${YELLOW}Kubectl is already installed${NC}"
    kubectl version --client
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

# Step 2: Install kubectl
echo -e "${YELLOW}[2/3] Installing kubectl...${NC}"
apt-get update -y
apt-get install -y kubectl

# Hold kubectl to prevent automatic updates
apt-mark hold kubectl

echo -e "${GREEN}✓ Kubectl installed and held at current version${NC}"

# Step 3: Set up bash completion (optional)
echo -e "${YELLOW}[3/3] Setting up bash completion...${NC}"

# Install bash-completion if not present
if ! dpkg -l | grep -q bash-completion; then
    apt-get install -y bash-completion
fi

# Add kubectl completion to bashrc for all users
kubectl completion bash | tee /etc/bash_completion.d/kubectl > /dev/null

# Add alias 'k' for kubectl
cat <<EOF >> /etc/profile.d/kubectl-alias.sh
# Kubectl alias
alias k='kubectl'
complete -F __start_kubectl k
EOF

echo -e "${GREEN}✓ Bash completion configured${NC}"

# Verify installation
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Kubectl Installation Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo "Kubectl version:"
kubectl version --client

echo ""
echo "Kubectl binary info:"
ls -lh $(which kubectl)

echo ""
echo -e "${YELLOW}Kubectl is a command-line tool for:${NC}"
echo "  - Managing Kubernetes resources (pods, deployments, services)"
echo "  - Viewing cluster information"
echo "  - Debugging applications"
echo "  - Port forwarding and exec into containers"

echo ""
echo -e "${YELLOW}Common kubectl commands:${NC}"
echo "  kubectl get nodes              # List nodes"
echo "  kubectl get pods               # List pods"
echo "  kubectl describe pod <name>    # Pod details"
echo "  kubectl logs <pod-name>        # View logs"
echo "  kubectl exec -it <pod> -- bash # Shell into pod"

echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  - Kubectl looks for config at: ~/.kube/config"
echo "  - This file is created after 'kubeadm init'"
echo "  - Alias 'k' available (reload shell: source /etc/profile.d/kubectl-alias.sh)"
echo "  - Bash completion enabled"

echo ""
echo -e "${YELLOW}Notes:${NC}"
echo "  - Kubectl can be installed on ANY machine (not just cluster nodes)"
echo "  - You can manage multiple clusters from one kubectl installation"
echo "  - Worker nodes don't need kubectl (only admin machines)"

echo ""
echo "Next step: Initialize cluster or install CNI"
echo "  Master: sudo kubeadm init --pod-network-cidr=10.244.0.0/16"
echo "  Then:   ./05-install-cni-flannel.sh"