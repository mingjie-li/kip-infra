#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <client-prefix>"
  exit 1
fi

PREFIX="$1"
NAMESPACE="$PREFIX"

kubectl delete httproute signoz -n "$NAMESPACE" --ignore-not-found

helm uninstall signoz -n "$NAMESPACE" --ignore-not-found --wait

kubectl delete namespace "$NAMESPACE" --ignore-not-found

echo "SigNoz uninstalled and namespace '${NAMESPACE}' deleted"
