#!/usr/bin/env bash
set -euo pipefail

# =========================
# Configuration
# =========================
PROJECT_NAME="bookstore"
REGISTRY="local"
VERSION="1.0.0"

IMAGES=(
  "${REGISTRY}/${PROJECT_NAME}-frontend:${VERSION}"
  "${REGISTRY}/${PROJECT_NAME}-backend:${VERSION}"
  "${REGISTRY}/${PROJECT_NAME}-database:${VERSION}"
)

REPORT_DIR="security/reports"
SEVERITY="HIGH,CRITICAL"

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
  echo -e "${RED}❌ ERROR:${NC} $1"
  exit 1
}

pass() {
  echo -e "${GREEN}✔ $1${NC}"
}

warn() {
  echo -e "${YELLOW}⚠ $1${NC}"
}

# =========================
# Banner
# =========================
echo "=================================================="
echo " Bookstore DevSecOps – Security Scan (Trivy)"
echo " Images • SBOM • Secrets"
echo "=================================================="

# =========================
# Pre-flight Checks
# =========================
command -v trivy >/dev/null 2>&1 || fail "Trivy is not installed"
command -v podman >/dev/null 2>&1 || fail "Podman is not installed"

mkdir -p "$REPORT_DIR"
pass "Report directory ready: $REPORT_DIR"

# =========================
# Validate Images Exist
# =========================
for IMAGE in "${IMAGES[@]}"; do
  if ! podman image exists "$IMAGE"; then
    fail "Image not found: $IMAGE (run build-images.sh first)"
  fi
done
pass "All images exist"

# =========================
# Image Vulnerability Scan
# =========================
echo "🔍 Running image vulnerability scans..."

for IMAGE in "${IMAGES[@]}"; do
  NAME=$(echo "$IMAGE" | tr '/:' '__')

  echo "▶ Scanning $IMAGE"
  trivy image \
    --severity "$SEVERITY" \
    --exit-code 1 \
    --no-progress \
    --format table \
    -o "${REPORT_DIR}/${NAME}-vuln.txt" \
    "$IMAGE"

  pass "Vulnerability scan passed: $IMAGE"
done

# =========================
# SBOM Generation
# =========================
echo "📄 Generating SBOMs..."

for IMAGE in "${IMAGES[@]}"; do
  NAME=$(echo "$IMAGE" | tr '/:' '__')

  trivy image \
    --format spdx-json \
    -o "${REPORT_DIR}/${NAME}-sbom.json" \
    "$IMAGE"

  pass "SBOM generated: ${NAME}-sbom.json"
done

# =========================
# Secret Scanning (Source Tree)
# =========================
echo "🔐 Running secret scan on repository..."

trivy fs \
  --scanners secret \
  --exit-code 1 \
  --no-progress \
  --format table \
  -o "${REPORT_DIR}/secrets-scan.txt" \
  .

pass "Secret scan passed"

# =========================
# Summary Report
# =========================
SUMMARY_FILE="${REPORT_DIR}/scan-summary.txt"

{
  echo "Bookstore DevSecOps – Security Scan Summary"
  echo "=========================================="
  echo ""
  echo "Severity enforced : $SEVERITY"
  echo "Images scanned:"
  for IMAGE in "${IMAGES[@]}"; do
    echo "  - $IMAGE"
  done
  echo ""
  echo "Reports generated in: $REPORT_DIR"
} > "$SUMMARY_FILE"

pass "Security summary created: $SUMMARY_FILE"

# =========================
# Final Status
# =========================
echo "--------------------------------------------------"
echo -e "${GREEN}✔ All security scans passed successfully${NC}"
echo "You may proceed to Kubernetes deployment."
echo "--------------------------------------------------"
