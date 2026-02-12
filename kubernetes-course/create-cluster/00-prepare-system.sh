#!/bin/bash

#############################################
# System Preparation for Kubernetes 1.35+
# Updated for modern Kubernetes (swap optional, cgroup v2 required)
# Run this BEFORE installing any K8s components
#############################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Kubernetes 1.35 System Preparation${NC}"
echo -e "${BLUE}========================================${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}" 
   exit 1
fi

# Step 1: Update system
echo -e "${YELLOW}[1/8] Updating system packages...${NC}"
apt-get update -y
# apt-get upgrade -y

# Step 2: Install basic dependencies
echo -e "${YELLOW}[2/8] Installing basic dependencies...${NC}"
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common

# Step 3: Verify cgroup v2 (REQUIRED for K8s 1.35)
echo -e "${YELLOW}[3/8] Verifying cgroup v2...${NC}"
if [ -f /sys/fs/cgroup/cgroup.controllers ]; then
    echo -e "${GREEN}✓ Running cgroup v2 (required)${NC}"
else
    echo -e "${RED}✗ ERROR: cgroup v1 detected!${NC}"
    echo -e "${RED}Kubernetes 1.35+ requires cgroup v2${NC}"
    echo ""
    echo "To enable cgroup v2, add to /etc/default/grub:"
    echo "  GRUB_CMDLINE_LINUX=\"systemd.unified_cgroup_hierarchy=1\""
    echo "Then run: update-grub && reboot"
    exit 1
fi

# Step 4: Check swap status (optional in modern K8s)
echo -e "${YELLOW}[4/8] Checking swap status...${NC}"
if [ $(swapon -s | wc -l) -gt 0 ]; then
    echo -e "${YELLOW}⚠ Swap is enabled${NC}"
    echo "Kubernetes 1.34+ supports swap (GA feature)"
    echo "You can keep swap enabled if desired"
    read -p "Disable swap anyway? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        swapoff -a
        sed -i '/ swap / s/^/#/' /etc/fstab
        echo -e "${GREEN}✓ Swap disabled${NC}"
    else
        echo -e "${YELLOW}✓ Swap kept enabled (will configure kubelet for LimitedSwap mode)${NC}"
    fi
else
    echo -e "${GREEN}✓ Swap is already disabled${NC}"
fi

# Step 5: Load required kernel modules
echo -e "${YELLOW}[5/8] Loading kernel modules...${NC}"
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

echo -e "${GREEN}✓ Kernel modules loaded${NC}"

# Step 6: Set up required sysctl params
echo -e "${YELLOW}[6/8] Configuring sysctl parameters...${NC}"
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sysctl --system
echo -e "${GREEN}✓ Sysctl configured${NC}"

# Step 7: Disable firewall (optional, for testing)
echo -e "${YELLOW}[7/8] Checking firewall...${NC}"
if systemctl is-active --quiet ufw; then
    echo "UFW is active. Consider configuring it for K8s or disabling temporarily"
    read -p "Disable UFW? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ufw disable
        echo -e "${GREEN}✓ Firewall disabled${NC}"
    fi
else
    echo -e "${GREEN}✓ No active firewall${NC}"
fi

# Step 8: Verify prerequisites
echo -e "${YELLOW}[8/8] Verifying prerequisites...${NC}"
echo ""

echo "System checks:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check cgroup v2
if [ -f /sys/fs/cgroup/cgroup.controllers ]; then
    echo -e "${GREEN}✓ cgroup v2: Enabled (required)${NC}"
else
    echo -e "${RED}✗ cgroup v2: Missing (required!)${NC}"
fi

# Check swap
if [ $(swapon -s | wc -l) -eq 0 ]; then
    echo -e "${GREEN}✓ Swap: Disabled${NC}"
else
    echo -e "${YELLOW}⚠ Swap: Enabled (supported in K8s 1.34+)${NC}"
fi

# Check kernel modules
echo "Kernel modules:"
lsmod | grep -E "br_netfilter|overlay" && echo -e "${GREEN}✓ Required modules loaded${NC}"

# Check sysctl
echo ""
echo "Sysctl settings:"
sysctl net.bridge.bridge-nf-call-iptables net.ipv4.ip_forward | grep "= 1" && echo -e "${GREEN}✓ Network settings correct${NC}"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}System Preparation Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. ./01-install-containerd.sh"
echo "  2. ./02-install-kubelet.sh"
echo "  3. ./03-install-kubeadm.sh"
echo "  4. ./04-install-kubectl.sh"