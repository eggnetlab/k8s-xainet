#!/bin/bash
# Installs the host tools needed by k8s-xainet on Debian/Ubuntu (amd64, arm64):
# minikube, kurtosis, kubectl
#
# Docker must already be installed and working.
# Run it as a normal user, not with sudo: it asks for your sudo password once,
# when it needs it, and never stores it.
#
# Versions can be overridden from the environment, for example:
#   MINIKUBE_VERSION=1.39.0 ./install-deps.sh
set -euo pipefail

MINIKUBE_VERSION="${MINIKUBE_VERSION:-1.39.0}"
KURTOSIS_VERSION="${KURTOSIS_VERSION:-1.22.2}"
# Keep close to K8S_VERSION in minikube/.env.example (one minor version apart is fine).
KUBECTL_VERSION="${KUBECTL_VERSION:-1.37.1}"

TMP="$(mktemp -d)"
chmod 755 "$TMP"
trap 'rm -rf "$TMP"' EXIT

install_completion() { # command name
    local tool=$1
    local dir="${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions"
    mkdir -p "$dir"
    if "$tool" completion bash >"$dir/$tool.new" 2>/dev/null; then
        mv "$dir/$tool.new" "$dir/$tool"
    else
        rm -f "$dir/$tool.new"
        warn "could not generate the bash completion for $tool"
    fi
}

curl="curl -fsSL --retry 3"

sudo -v

echo "==> install minikube"
$curl -o $TMP/minikube_${MINIKUBE_VERSION}-0_amd64.deb https://github.com/kubernetes/minikube/releases/download/v$MINIKUBE_VERSION/minikube_$MINIKUBE_VERSION-0_amd64.deb
sudo apt-get install -y -qq --no-install-recommends $TMP/minikube_$MINIKUBE_VERSION-0_amd64.deb
install_completion minikube

echo "==> install kurtosis"
$curl -o $TMP/kurtosis-cli_${KURTOSIS_VERSION}_linux_amd64.deb https://github.com/kurtosis-tech/kurtosis-cli-release-artifacts/releases/download/${KURTOSIS_VERSION}/kurtosis-cli_${KURTOSIS_VERSION}_linux_amd64.deb
sudo apt-get install -y -qq --no-install-recommends $TMP/kurtosis-cli_${KURTOSIS_VERSION}_linux_amd64.deb
install_completion kurtosis

echo "==> install kubectl"
$curl -o $TMP/kubectl_${KUBECTL_VERSION} https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl
sudo install -m 0755 $TMP/kubectl_${KUBECTL_VERSION} /usr/local/bin/kubectl
install_completion kubectl

echo "==> Dependencies installed."
echo "Open a new shell to load the bash completions."
