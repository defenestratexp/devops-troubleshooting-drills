#!/usr/bin/env bash
# Local throwaway Kubernetes for the b* exercises. Nothing here touches k8slab,
# plexn9n or utilitybox - it is a cluster-in-docker on this machine only.
#
# NOTE: PATH is exported FIRST and the installers are not allowed to abort the
# script. k3d's own install.sh writes the binary correctly and then exits
# non-zero if ~/.local/bin is not already on PATH, which under `set -e` kills
# the run even though the install succeeded.
set -u
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

if ! command -v k3d >/dev/null; then
  echo "installing k3d to ~/.local/bin"
  curl -sS https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh \
    | USE_SUDO=false K3D_INSTALL_DIR="$HOME/.local/bin" bash || true
fi
command -v k3d >/dev/null || { echo "ERROR: k3d still not on PATH"; exit 1; }

if ! command -v kubectl >/dev/null; then
  echo "installing kubectl to ~/.local/bin"
  v=$(curl -sS https://dl.k8s.io/release/stable.txt)
  curl -sSLo "$HOME/.local/bin/kubectl" "https://dl.k8s.io/release/$v/bin/linux/amd64/kubectl"
  chmod +x "$HOME/.local/bin/kubectl"
fi
command -v kubectl >/dev/null || { echo "ERROR: kubectl still not on PATH"; exit 1; }

if ! k3d cluster list 2>/dev/null | grep -q '^practice'; then
  k3d cluster create practice --agents 1 --wait
fi
kubectl cluster-info
kubectl get nodes
echo
echo "k3d and kubectl are in ~/.local/bin, which .bashrc already puts on PATH"
echo "for interactive shells. Teardown when done:  k3d cluster delete practice"
