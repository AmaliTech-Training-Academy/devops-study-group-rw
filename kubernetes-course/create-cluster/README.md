# Kubernetes 1.35 Modular Installation Scripts

Complete set of installation scripts for Kubernetes 1.35 on Ubuntu/Debian systems.

## 📋 Features

- **Modular Design**: Each component in a separate script
- **Modern K8s 1.35**: Updated for latest Kubernetes features
- **Swap Support**: Optional swap configuration (GA in 1.34+)
- **Cgroup v2**: Required for Kubernetes 1.35+
- **Containerd 2.x**: Latest container runtime

## 🚀 Quick Start

### Prerequisites
- Ubuntu 22.04+ or Debian 12+
- 2 GB RAM minimum (4 GB recommended)
- 2 CPUs minimum
- Root or sudo access

### Installation Order
```bash
# 1. Prepare system (required first)
sudo ./00-prepare-system.sh

# 2. Install container runtime
sudo ./01-install-containerd.sh

# 3. Install kubelet
sudo ./02-install-kubelet.sh

# 4. Install kubeadm
sudo ./03-install-kubeadm.sh

# 5. Install kubectl (optional but recommended)
sudo ./04-install-kubectl.sh

# 6. Initialize cluster (master node only)
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# 7. Set up kubeconfig
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 8. Install CNI plugin (choose one)
sudo ./05-install-cni-flannel.sh
# OR
sudo ./06-install-cni-calico.sh
```

## 📁 Script Descriptions

| Script | Purpose | When to Run |
|--------|---------|-------------|
| `00-prepare-system.sh` | System prerequisites | First, on all nodes |
| `01-install-containerd.sh` | Container runtime | After system prep |
| `02-install-kubelet.sh` | Node agent | After containerd |
| `03-install-kubeadm.sh` | Cluster tool | After kubelet |
| `04-install-kubectl.sh` | CLI tool | Optional, on admin machines |
| `05-install-cni-flannel.sh` | Flannel networking | After kubeadm init |
| `06-install-cni-calico.sh` | Calico networking | Alternative to Flannel |

## 🆕 What's New in K8s 1.35

- **Swap Support**: GA (no need to disable swap)
- **In-Place Pod Resize**: Stable (resize pods without restart)
- **Cgroup v1 Removed**: Must use cgroup v2
- **Containerd 1.x Deprecated**: Use 2.x for future compatibility
- **Gang Scheduling**: Alpha support for all-or-nothing job scheduling

## ⚙️ Configuration Options

### Swap Configuration

Swap is now supported! The kubelet can run with swap enabled using `LimitedSwap` mode.

If swap is detected, `02-install-kubelet.sh` will automatically configure:
```yaml
failSwapOn: false
memorySwap:
  swapBehavior: LimitedSwap
```

### CNI Choice

**Flannel** (Simple, VXLAN overlay):
- Easy to set up
- Good for most clusters
- VXLAN encapsulation

**Calico** (Advanced, BGP routing):
- Better performance (native routing)
- Network policies included
- More complex setup

## 🔍 Verification
```bash
# Check all components
kubectl get nodes
kubectl get pods -n kube-system
kubectl get componentstatuses

# Test with a pod
kubectl run nginx --image=nginx
kubectl get pods -o wide
```

## 🐛 Troubleshooting

### Node shows NotReady
```bash
# Check CNI installation
kubectl get pods -n kube-system | grep -E "flannel|calico"

# Check kubelet logs
sudo journalctl -u kubelet -f
```

### Cgroup v2 error
```bash
# Verify cgroup v2
[ -f /sys/fs/cgroup/cgroup.controllers ] && echo "cgroup v2" || echo "cgroup v1"

# Enable cgroup v2 (requires reboot)
sudo nano /etc/default/grub
# Add: GRUB_CMDLINE_LINUX="systemd.unified_cgroup_hierarchy=1"
sudo update-grub
sudo reboot
```

## 📚 References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kubernetes 1.35 Release Notes](https://kubernetes.io/blog/2025/12/17/kubernetes-v1-35-release/)
- [Containerd Documentation](https://containerd.io/)

## 📝 License

These scripts are provided as-is for educational purposes.