#!/usr/bin/env bash
set -uo pipefail

# =========================
# Configuration
# =========================
PROJECT_NAME="bookstore"
REGISTRY="local"
VERSION="1.0.0"

FRONTEND_IMAGE="${REGISTRY}/${PROJECT_NAME}-frontend:${VERSION}"
BACKEND_IMAGE="${REGISTRY}/${PROJECT_NAME}-backend:${VERSION}"
DATABASE_IMAGE="${REGISTRY}/${PROJECT_NAME}-database:${VERSION}"

DOCKER_DIR="docker"
FRONTEND_DIR="${DOCKER_DIR}/frontend"
BACKEND_DIR="${DOCKER_DIR}/backend"
DATABASE_DIR="${DOCKER_DIR}/database"

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
  echo -e "${RED}❌ FAILED:${NC} $1"
}

pass() {
  echo -e "${GREEN}✔ $1${NC}"
}

run_step() {
  local description="$1"
  shift
  echo "▶ $description"
  if "$@"; then
    echo -e "${GREEN}✔ SUCCESS${NC}: $description"
  else
    echo -e "${YELLOW}⚠ FAILED (continuing)${NC}: $description"
  fi
}

# =========================
# Banner
# =========================
echo "=================================================="
echo " Bookstore DevSecOps – Build Images"
echo " Non-blocking • Podman • Minikube"
echo "=================================================="

# =========================
# Pre-flight Checks
# =========================
command -v podman >/dev/null 2>&1 || fail "Podman is not installed"
command -v minikube >/dev/null 2>&1 || fail "Minikube is not installed"

[[ -d "$FRONTEND_DIR" ]] || fail "Missing directory: $FRONTEND_DIR"
[[ -d "$BACKEND_DIR" ]] || fail "Missing directory: $BACKEND_DIR"
[[ -d "$DATABASE_DIR" ]] || fail "Missing directory: $DATABASE_DIR"

# =========================
# Validate Tag
# =========================
if [[ "$VERSION" == "latest" ]]; then
  fail "Usage of :latest tag is forbidden"
else
  pass "Image tags validated (no :latest)"
fi

# =========================
# Build Images
# =========================
run_step "Build Frontend Image" \
  podman build -f "${FRONTEND_DIR}/dockerfile" -t "$FRONTEND_IMAGE" "$FRONTEND_DIR"

run_step "Build Backend Image" \
  podman build -f "${BACKEND_DIR}/dockerfile" -t "$BACKEND_IMAGE" "$BACKEND_DIR"

run_step "Build Database Image" \
  podman build -f "${DATABASE_DIR}/dockerfile" -t "$DATABASE_IMAGE" "$DATABASE_DIR"

# =========================
# Validate Non-root User
# =========================
echo "🔍 Validating container users..."

for IMAGE in "$FRONTEND_IMAGE" "$BACKEND_IMAGE" "$DATABASE_IMAGE"; do
  USER_ID=$(podman inspect "$IMAGE" --format '{{.Config.User}}' 2>/dev/null || echo "")
  if [[ -z "$USER_ID" || "$USER_ID" == "0" ]]; then
    echo -e "${YELLOW}⚠ Image $IMAGE runs as root or could not be inspected${NC}"
  else
    pass "Image $IMAGE runs as non-root user (UID: $USER_ID)"
  fi
done

# =========================
# Backend Image Size Check
# =========================
BACKEND_SIZE_MB=$(podman image inspect "$BACKEND_IMAGE" \
  --format '{{.Size}}' 2>/dev/null | awk '{print int($1/1024/1024)}')

if [[ -n "$BACKEND_SIZE_MB" && "$BACKEND_SIZE_MB" -le 150 ]]; then
  pass "Backend image size ${BACKEND_SIZE_MB}MB (within limit)"
else
  echo -e "${YELLOW}⚠ Backend image size check failed or exceeds limit${NC}"
fi

# =========================
# Load Images into Minikube
# =========================
run_step "Load frontend image into Minikube" minikube image load "$FRONTEND_IMAGE"
run_step "Load backend image into Minikube" minikube image load "$BACKEND_IMAGE"
run_step "Load database image into Minikube" minikube image load "$DATABASE_IMAGE"

# =========================
# Summary
# =========================
echo "--------------------------------------------------"
echo -e "${GREEN}✔ Build script completed (non-blocking mode)${NC}"
echo "Failures (if any) were logged but execution continued."
echo "--------------------------------------------------"
