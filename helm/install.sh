helm repo add signoz https://charts.signoz.io
helm repo update


helm upgrade signoz signoz/signoz \
   --namespace kip-002 --create-namespace \
   --wait \
   --timeout 1h \
   -f values.yaml


helm uninstall signoz -n kip-001