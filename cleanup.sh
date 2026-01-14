#!/usr/bin/env bash
set -uo pipefail

NAMESPACE="bookstore"

echo "===== Cleanup Environment ====="

kubectl delete ns "$NAMESPACE" --ignore-not-found
minikube stop