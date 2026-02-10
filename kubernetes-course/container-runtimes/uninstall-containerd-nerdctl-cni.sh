#!/bin/bash
set -e

DRY_RUN=0
for arg in "$@"; do
    case "$arg" in
        -n|--dry-run)
            DRY_RUN=1
            ;;
        -h|--help)
            echo "Usage: $0 [--dry-run]"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            exit 1
            ;;
    esac
done

run_cmd() {
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "[dry-run] $*"
        return 0
    fi
    "$@"
}

# Function to safely wait for the apt lock
wait_for_apt() {
    if [ "$DRY_RUN" -eq 1 ]; then
        return 0
    fi
    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; do
        echo "Waiting for Ubuntu's background update to finish (apt lock)..."
        sleep 5
    done
}

echo "--- Uninstalling Containerd, Nerdctl, and CNI Plugins ---"

# 1. Stop and disable containerd
if systemctl is-active --quiet containerd; then
    run_cmd sudo systemctl stop containerd
fi
if systemctl is-enabled --quiet containerd; then
    run_cmd sudo systemctl disable containerd
fi

# 2. Remove containerd.io
wait_for_apt
run_cmd sudo apt-get remove -y containerd.io
run_cmd sudo apt-get autoremove -y

# 3. Remove Docker repository and keyring
run_cmd sudo rm -f /etc/apt/sources.list.d/docker.list
run_cmd sudo rm -f /etc/apt/keyrings/docker.gpg

# 4. Remove nerdctl binary
run_cmd sudo rm -f /usr/local/bin/nerdctl

# 5. Remove CNI plugins
run_cmd sudo rm -rf /opt/cni/bin

# 6. Refresh apt metadata
wait_for_apt
run_cmd sudo apt-get update

echo "--------------------------------"
echo "Containerd Status: $(systemctl is-active containerd 2>/dev/null || echo inactive)"
echo "Nerdctl Path: $(command -v nerdctl || echo not found)"
echo "CNI Directory: $(if [ -d /opt/cni/bin ]; then echo present; else echo removed; fi)"
