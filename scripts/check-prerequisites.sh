#!/usr/bin/env bash
set -uo pipefail

# =========================
# Configuration
# =========================
MIN_PODMAN_VERSION="4.0.0"
MIN_TRIVY_VERSION="0.45.0"
MIN_KUBECTL_VERSION="1.27.0"
MIN_GIT_VERSION="2.30.0"
MIN_JQ_VERSION="1.6"
MIN_MINIKUBE_VERSION="1.32.0"

# =========================
# Colors
# =========================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# =========================
# Helpers
# =========================
fail() {
  echo -e "${YELLOW}⚠ FAILED (continuing):${NC} $1"
}

pass() {
  echo -e "${GREEN}✔ $1${NC}"
}

warn() {
  echo -e "${YELLOW}⚠ $1${NC}"
}

version_ge() {
  [ "$(printf '%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}

check_cmd() {
  command -v "$1" >/dev/null 2>&1 \
    && pass "$1 is installed" \
    || fail "$1 is not installed"
}

run_check() {
  local description="$1"
  shift
  if "$@"; then
    pass "$description"
  else
    fail "$description"
  fi
}

# =========================
# Banner
# =========================
echo "=================================================="
echo " Bookstore DevSecOps – Prerequisite Check"
echo " Kubernetes + Minikube Edition (Non-blocking)"
echo "=================================================="

# =========================
# Podman
# =========================
check_cmd podman
PODMAN_VERSION=$(podman version --format '{{.Client.Version}}' 2>/dev/null || echo "")
if [[ -n "$PODMAN_VERSION" ]] && version_ge "$PODMAN_VERSION" "$MIN_PODMAN_VERSION"; then
  pass "Podman $PODMAN_VERSION"
else
  fail "Podman >= $MIN_PODMAN_VERSION required"
fi

# =========================
# Trivy
# =========================
check_cmd trivy
TRIVY_VERSION=$(trivy --version 2>/dev/null | awk '{print $2}' || echo "")
if [[ -n "$TRIVY_VERSION" ]] && version_ge "$TRIVY_VERSION" "$MIN_TRIVY_VERSION"; then
  pass "Trivy $TRIVY_VERSION"
else
  fail "Trivy >= $MIN_TRIVY_VERSION required"
fi

# =========================
# kubectl
# =========================
check_cmd kubectl
KUBECTL_VERSION=$(kubectl version --client -o json 2>/dev/null | jq -r '.clientVersion.gitVersion' | sed 's/^v//' || echo "")
if [[ -n "$KUBECTL_VERSION" ]] && version_ge "$KUBECTL_VERSION" "$MIN_KUBECTL_VERSION"; then
  pass "kubectl $KUBECTL_VERSION"
else
  fail "kubectl >= $MIN_KUBECTL_VERSION required"
fi

# =========================
# Minikube
# =========================
check_cmd minikube
MINIKUBE_VERSION=$(minikube version --short 2>/dev/null | sed 's/v//' || echo "")
if [[ -n "$MINIKUBE_VERSION" ]] && version_ge "$MIN_MINIKUBE_VERSION" "$MIN_MINIKUBE_VERSION"; then
  pass "Minikube $MINIKUBE_VERSION"
else
  fail "Minikube >= $MIN_MINIKUBE_VERSION required"
fi

# =========================
# Git
# =========================
check_cmd git
GIT_VERSION=$(git version 2>/dev/null | awk '{print $3}' || echo "")
if [[ -n "$GIT_VERSION" ]] && version_ge "$GIT_VERSION" "$MIN_GIT_VERSION"; then
  pass "Git $GIT_VERSION"
else
  fail "Git >= $MIN_GIT_VERSION required"
fi

# =========================
# jq
# =========================
check_cmd jq
JQ_VERSION=$(jq --version 2>/dev/null | sed 's/jq-//' || echo "")
if [[ -n "$JQ_VERSION" ]] && version_ge "$JQ_VERSION" "$MIN_JQ_VERSION"; then
  pass "jq $JQ_VERSION"
else
  fail "jq >= $MIN_JQ_VERSION required"
fi

# =========================
# Minikube Status
# =========================
run_check "Minikube is running" minikube status >/dev/null 2>&1

# =========================
# kubectl Context Validation
# =========================
CURRENT_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "")
if [[ "$CURRENT_CONTEXT" == "minikube" ]]; then
  pass "kubectl context is minikube"
else
  fail "kubectl context is '$CURRENT_CONTEXT' (expected: minikube)"
fi

# =========================
# Kubernetes Connectivity
# =========================
run_check "Connected to Kubernetes cluster" kubectl get nodes >/dev/null 2>&1

# =========================
# Summary
# =========================
echo "--------------------------------------------------"
echo -e "${GREEN}✔ Prerequisite check completed (non-blocking)${NC}"
echo "Any failures above were logged but did NOT stop execution."
echo "You may still proceed with:"
echo "  ./scripts/build-images.sh"
echo "--------------------------------------------------"
