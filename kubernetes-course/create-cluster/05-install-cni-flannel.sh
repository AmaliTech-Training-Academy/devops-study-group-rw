#!/bin/bash

#############################################
# CNI Plugin Installation - Flannel
# Installs Flannel CNI for pod networking
# Run AFTER 'kubeadm init' on master node
#############################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Flannel version
FLANNEL_VERSION="latest"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Flannel CNI Installation${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}" 
   exit 1
fi

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed!${NC}"
    echo "Please install kubectl first:"
    echo "  Run: ./04-install-kubectl.sh"
    exit 1
fi

# Check if kubeconfig exists
if [ ! -f ~/.kube/config ] && [ ! -f /etc/kubernetes/admin.conf ]; then
    echo -e "${RED}Error: Kubernetes cluster not initialized!${NC}"
    echo "Please run 'kubeadm init' first"
    echo ""
    echo "Example:"
    echo "  sudo kubeadm init --pod-network-cidr=10.244.0.0/16"
    echo ""
    echo "Then copy kubeconfig:"
    echo "  mkdir -p ~/.kube"
    echo "  sudo cp /etc/kubernetes/admin.conf ~/.kube/config"
    echo "  sudo chown \$(id -u):\$(id -g) ~/.kube/config"
    exit 1
fi

# Use root's kubeconfig if regular user's doesn't exist
if [ ! -f ~/.kube/config ]; then
    export KUBECONFIG=/etc/kubernetes/admin.conf
fi

# Check if cluster is accessible
echo -e "${YELLOW}[1/5] Checking cluster connectivity...${NC}"
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Cannot connect to cluster!${NC}"
    echo "Make sure kubeadm init completed successfully"
    exit 1
fi

echo -e "${GREEN}✓ Cluster is accessible${NC}"

# Check current node status
echo ""
echo "Current node status:"
kubectl get nodes

# Step 2: Check if CNI is already installed
echo ""
echo -e "${YELLOW}[2/5] Checking for existing CNI...${NC}"

if kubectl get pods -n kube-system | grep -E "flannel|calico|weave|cilium" &> /dev/null; then
    echo -e "${YELLOW}⚠ CNI plugin already appears to be installed${NC}"
    kubectl get pods -n kube-system | grep -E "flannel|calico|weave|cilium"
    read -p "Continue with Flannel installation anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Step 3: Download Flannel manifest
echo -e "${YELLOW}[3/5] Downloading Flannel manifest...${NC}"

FLANNEL_URL="https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml"

curl -LO "$FLANNEL_URL"

echo -e "${GREEN}✓ Flannel manifest downloaded${NC}"

# Step 4: Apply Flannel
echo -e "${YELLOW}[4/5] Installing Flannel CNI...${NC}"

kubectl apply -f kube-flannel.yml

echo -e "${GREEN}✓ Flannel applied to cluster${NC}"

# Clean up
rm -f kube-flannel.yml

# Step 5: Wait for Flannel pods to be ready
echo -e "${YELLOW}[5/5] Waiting for Flannel pods to be ready...${NC}"

echo "This may take 1-2 minutes..."
sleep 10

# Wait up to 2 minutes for flannel to be ready
for i in {1..24}; do
    if kubectl get pods -n kube-system -l app=flannel | grep -q "Running"; then
        echo -e "${GREEN}✓ Flannel pods are running${NC}"
        break
    fi
    echo "Waiting... ($i/24)"
    sleep 5
done

# Verify installation
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Flannel CNI Installation Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo "CNI Pods status:"
kubectl get pods -n kube-system -l app=flannel

echo ""
echo "DaemonSet status:"
kubectl get daemonset -n kube-system -l app=flannel

echo ""
echo "Node status:"
kubectl get nodes

echo ""
echo "Checking CNI files on host:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -d /opt/cni/bin ]; then
    echo "CNI binaries (/opt/cni/bin):"
    ls -lh /opt/cni/bin | head -10
else
    echo -e "${YELLOW}⚠ /opt/cni/bin not found (will be created by Flannel pod)${NC}"
fi

echo ""
if [ -d /etc/cni/net.d ]; then
    echo "CNI configuration (/etc/cni/net.d):"
    ls -lh /etc/cni/net.d
else
    echo -e "${YELLOW}⚠ /etc/cni/net.d not found (will be created by Flannel pod)${NC}"
fi

echo ""
echo -e "${YELLOW}What Flannel does:${NC}"
echo "  1. Runs as DaemonSet (one pod per node)"
echo "  2. Copies CNI binaries to /opt/cni/bin/"
echo "  3. Creates CNI config in /etc/cni/net.d/"
echo "  4. Manages pod networking (IP assignment, routing)"
echo "  5. Uses VXLAN for overlay network (default)"

echo ""
echo -e "${YELLOW}Network details:${NC}"
echo "  - Pod network CIDR: 10.244.0.0/16 (from kubeadm init)"
echo "  - Each node gets: 10.244.X.0/24 subnet"
echo "  - Backend: VXLAN (overlay network)"

echo ""
echo -e "${GREEN}Cluster is now ready! Nodes should show 'Ready' status.${NC}"
echo ""
echo "Test your cluster:"
echo "  kubectl run nginx --image=nginx"
echo "  kubectl get pods -o wide"