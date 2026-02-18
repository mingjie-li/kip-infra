#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <client-prefix>"
  echo "  client-prefix  Used as the namespace and subdomain (e.g. 'acme' → namespace: acme, host: acme.api-dev.kube-intel.com)"
  exit 1
fi

PREFIX="$1"
NAMESPACE="$PREFIX"
GATEWAY_DOMAIN="api-dev.kube-intel.com"
GATEWAY_NAME="external-gateway-001"
GATEWAY_NAMESPACE="gateway-api"

helm repo add signoz https://charts.signoz.io
helm repo update

helm upgrade --install signoz signoz/signoz \
  --namespace "$NAMESPACE" --create-namespace \
  --wait \
  --timeout 1h \
  -f values.yaml

kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: signoz
  namespace: ${NAMESPACE}
spec:
  parentRefs:
  - name: ${GATEWAY_NAME}
    namespace: ${GATEWAY_NAMESPACE}
  hostnames:
  - "${PREFIX}.${GATEWAY_DOMAIN}"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: signoz
      port: 8080
EOF

kubectl apply -f - <<EOF
apiVersion: networking.gke.io/v1
kind: HealthCheckPolicy
metadata:
  name: signoz-health
  namespace: ${NAMESPACE}
spec:
  targetRef:
    group: ""
    kind: Service
    name: signoz
  default:
   config:
      type: HTTP
      httpHealthCheck:
        port: 8080
        requestPath: /api/v1/health
   checkIntervalSec: 15
   timeoutSec: 5
   healthyThreshold: 1
   unhealthyThreshold: 2
EOF


kubectl apply -f - <<EOF
apiVersion: networking.gke.io/v1
kind: HealthCheckPolicy
metadata:
  name: otel-collector-grpc-health
  namespace: ${NAMESPACE}
spec:
  targetRef:
    group: ""
    kind: Service
    name: signoz-otel-collector-grpc
  default:
   config:
      type: GRPC
      grpcHealthCheck:
        port: 4317
   checkIntervalSec: 15
   timeoutSec: 5
   healthyThreshold: 1
   unhealthyThreshold: 2
EOF

kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: signoz-otel-collector-grpc
  namespace: ${NAMESPACE}
spec:
  ports:
  - name: otlp
    port: 4317
    protocol: TCP
    targetPort: otlp
    appProtocol: kubernetes.io/h2c
  selector:
    app.kubernetes.io/component: otel-collector
    app.kubernetes.io/instance: signoz
    app.kubernetes.io/name: signoz
  sessionAffinity: None
  type: ClusterIP
EOF

kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: otel-collector
  namespace: ${NAMESPACE}
spec:
  parentRefs:
  - name: ${GATEWAY_NAME}
    namespace: ${GATEWAY_NAMESPACE}
  hostnames:
  - "${PREFIX}-otel.${GATEWAY_DOMAIN}"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: signoz-otel-collector-grpc
      port: 4317
EOF

echo "SigNoz installed in namespace '${NAMESPACE}'"
echo "HTTPRoute created → https://${PREFIX}.${GATEWAY_DOMAIN}"
