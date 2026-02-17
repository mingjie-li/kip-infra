helm repo add signoz https://charts.signoz.io
helm repo update


helm upgrade signoz signoz/signoz \
   --namespace kip-001 --create-namespace \
   --wait \
   --timeout 1h \
   -f values.yaml


helm uninstall signoz -n kip-001