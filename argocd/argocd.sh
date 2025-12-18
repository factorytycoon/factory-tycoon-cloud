set -e

terraform init -reconfigure

echo "▶ Step 1. Install Argo CD core resources"

terraform apply -auto-approve \
  -target=helm_release.argocd \
  -target=kubernetes_namespace_v1.argocd \
  -target=kubernetes_secret_v1.argocd_repo

echo "▶ Step 2. Apply remaining resources (Applications)"

terraform apply -auto-approve
