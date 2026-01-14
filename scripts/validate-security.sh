#!/usr/bin/env bash
set -uo pipefail

NAMESPACE="bookstore"

echo "===== Runtime Security Validation ====="

kubectl get pods -n "$NAMESPACE"
kubectl get networkpolicy -n "$NAMESPACE"