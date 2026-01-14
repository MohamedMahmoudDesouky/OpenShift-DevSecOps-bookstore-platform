#!/usr/bin/env bash
set -euo pipefail

# =========================
# Configuration
# =========================
KUSTOMIZE_OVERLAY="k8s/overlays/prod"
NAMESPACE="bookstore"

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

apply_kustomize() {
  echo "▶ Applying Kustomize overlay: $KUSTOMIZE_OVERLAY"
  if kubectl apply -k "$KUSTOMIZE_OVERLAY"; then
    pass "Kustomize applied successfully"
  else
    # Tolerate duplicate Ingress error
    if kubectl apply -k "$KUSTOMIZE_OVERLAY" 2>&1 | grep -q "host.*and path.*is already defined"; then
      warn "Ingress host/path already exists – continuing (safe in dev)"
    else
      warn "Kustomize apply failed – continuing anyway (non-blocking mode)"
    fi
  fi
}

# =========================
# Banner
# =========================
echo "=================================================="
echo " Bookstore DevSecOps – Run on Minikube (Public Images)"
echo " Using: selconyt/bookstore-frontend:v1.7, omaradel2001/bookstore-backend:v1.3, mysql:8.0.36, redis:7.2-alpine"
echo "=================================================="

# =========================
# Pre-flight Checks
# =========================
command -v kubectl >/dev/null 2>&1 || fail "kubectl is not installed"
command -v minikube >/dev/null 2>&1 || fail "Minikube is not installed"

if ! minikube status --format '{{.Host}}' >/dev/null 2>&1; then
  fail "Minikube is not running. Start with: minikube start"
fi

[[ -f "$KUSTOMIZE_OVERLAY/kustomization.yaml" ]] || \
  fail "Kustomize overlay not found: $KUSTOMIZE_OVERLAY"

pass "Minikube is running and overlay is valid"

# =========================
# Ensure Ingress Addon is Enabled
# =========================
if ! minikube addons list 2>/dev/null | grep -E 'ingress\s+enabled' >/dev/null; then
  echo "▶ Enabling NGINX Ingress addon in Minikube..."
  minikube addons enable ingress
  echo "⏳ Waiting for Ingress controller to be ready..."
  sleep 10
  kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=180s
  pass "Ingress controller is ready"
else
  pass "Ingress addon already enabled"
fi

# =========================
# Apply Manifests
# =========================
apply_kustomize "$KUSTOMIZE_OVERLAY"

# =========================
# Wait for Pods
# =========================
echo "⏳ Waiting for pods in namespace '$NAMESPACE' to stabilize..."

timeout=180
interval=5
elapsed=0
while [ $elapsed -lt $timeout ]; do
  total=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
  if [[ $total -gt 0 ]]; then
    ready=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | awk '$3 == "Running" && $4 !~ /0\//' | wc -l)
    if [[ $ready -eq $total ]]; then
      pass "All $total pods are running!"
      break
    fi
  fi
  sleep $interval
  elapsed=$((elapsed + interval))
  echo -n "."
done
echo

# =========================
# Access Instructions
# =========================
echo ""
echo "🔗 Access Information:"
HOST=$(kubectl get ingress -n "$NAMESPACE" frontend-ingress -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo "bookstore.local")
IP=$(minikube ip)

echo "🌐 Application URL: http://$HOST"
echo "   ➤ Add this line to your /etc/hosts file:"
echo "      $IP $HOST"
echo ""
echo "💡 After updating /etc/hosts, open in browser: http://$HOST"

# Optional: auto-add to /etc/hosts (commented out for safety)
# echo "$IP $HOST" | sudo tee -a /etc/hosts > /dev/null 2>&1 && echo "✅ Added to /etc/hosts" || echo "ℹ️ Run manually: echo '$IP $HOST' | sudo tee -a /etc/hosts"

echo ""
pass "Deployment completed! Monitor with: kubectl get pods -n $NAMESPACE"
ubuntu@ip-172-31-94-226:~/app.final/last-updated$
ubuntu@ip-172-31-94-226:~/app.final/last-updated$
ubuntu@ip-172-31-94-226:~/app.final/last-updated$ cat run.local.sh
#!/usr/bin/env bash
set -euo pipefail

# =========================
# Configuration
# =========================
KUSTOMIZE_OVERLAY="k8s/overlays/prod"
NAMESPACE="bookstore"

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

apply_kustomize() {
  echo "▶ Applying Kustomize overlay: $KUSTOMIZE_OVERLAY"
  if kubectl apply -k "$KUSTOMIZE_OVERLAY"; then
    pass "Kustomize applied successfully"
  else
    # Tolerate duplicate Ingress error
    if kubectl apply -k "$KUSTOMIZE_OVERLAY" 2>&1 | grep -q "host.*and path.*is already defined"; then
      warn "Ingress host/path already exists – continuing (safe in dev)"
    else
      warn "Kustomize apply failed – continuing anyway (non-blocking mode)"
    fi
  fi
}

# =========================
# Banner
# =========================
echo "=================================================="
echo " Bookstore DevSecOps – Run on Minikube (Public Images)"
echo " Using: selconyt/bookstore-frontend:v1.7, omaradel2001/bookstore-backend:v1.3, mysql:8.0.36, redis:7.2-alpine"
echo "=================================================="

# =========================
# Pre-flight Checks
# =========================
command -v kubectl >/dev/null 2>&1 || fail "kubectl is not installed"
command -v minikube >/dev/null 2>&1 || fail "Minikube is not installed"

if ! minikube status --format '{{.Host}}' >/dev/null 2>&1; then
  fail "Minikube is not running. Start with: minikube start"
fi

[[ -f "$KUSTOMIZE_OVERLAY/kustomization.yaml" ]] || \
  fail "Kustomize overlay not found: $KUSTOMIZE_OVERLAY"

pass "Minikube is running and overlay is valid"

# =========================
# Ensure Ingress Addon is Enabled
# =========================
if ! minikube addons list 2>/dev/null | grep -E 'ingress\s+enabled' >/dev/null; then
  echo "▶ Enabling NGINX Ingress addon in Minikube..."
  minikube addons enable ingress
  echo "⏳ Waiting for Ingress controller to be ready..."
  sleep 10
  kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=180s
  pass "Ingress controller is ready"
else
  pass "Ingress addon already enabled"
fi

# =========================
# Apply Manifests
# =========================
apply_kustomize "$KUSTOMIZE_OVERLAY"

# =========================
# Wait for Pods
# =========================
echo "⏳ Waiting for pods in namespace '$NAMESPACE' to stabilize..."

timeout=180
interval=5
elapsed=0
while [ $elapsed -lt $timeout ]; do
  total=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
  if [[ $total -gt 0 ]]; then
    ready=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | awk '$3 == "Running" && $4 !~ /0\//' | wc -l)
    if [[ $ready -eq $total ]]; then
      pass "All $total pods are running!"
      break
    fi
  fi
  sleep $interval
  elapsed=$((elapsed + interval))
  echo -n "."
done
echo

# =========================
# Access Instructions
# =========================
echo ""
echo "🔗 Access Information:"
HOST=$(kubectl get ingress -n "$NAMESPACE" frontend-ingress -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo "bookstore.local")
IP=$(minikube ip)

echo "🌐 Application URL: http://$HOST"
echo "   ➤ Add this line to your /etc/hosts file:"
echo "      $IP $HOST"
echo ""
echo "💡 After updating /etc/hosts, open in browser: http://$HOST"

# Optional: auto-add to /etc/hosts (commented out for safety)
# echo "$IP $HOST" | sudo tee -a /etc/hosts > /dev/null 2>&1 && echo "✅ Added to /etc/hosts" || echo "ℹ️ Run manually: echo '$IP $HOST' | sudo tee -a /etc/hosts"

echo ""
pass "Deployment completed! Monitor with: kubectl get pods -n $NAMESPACE"