#!/bin/bash

set -e

START_TIME=$SECONDS

MODULES=("vpc" "security-groups" "eks" "elasticache" "iot" "opensearch" "lambda")

echo "=========================================="
echo "Factory Tycoon Cloud deploy script"
echo "=========================================="
echo ""

for module in "${MODULES[@]}"; do
  echo "========== [$module] 배포 중... =========="

  if [ ! -d "$module" ]; then
    echo "$module 디렉토리를 찾을 수 없습니다."
    exit 1
  fi

  cd "$module"
  
  if [ "$module" = "lambda" ] && [ -f "build.sh" ]; then
    echo "→ Lambda 의존성 빌드 중..."
    ./build.sh
  fi

  echo "→ terraform init -reconfigure"
  terraform init -reconfigure

  if [ "$module" = "eks" ]; then
    echo "→ terraform apply (stage 1: EKS/IRSA/kubeconfig)"
    terraform apply -auto-approve \
      -target=module.eks \
      -target=aws_iam_policy.alb_controller \
      -target=module.alb_irsa \
      -target=null_resource.update_kubeconfig

    CLUSTER_NAME="$(terraform output -raw cluster_name 2>/dev/null)"
    AWS_REGION="$(awk -F'\"' '/^[[:space:]]*aws_region[[:space:]]*=/{print $2}' terraform.tfvars 2>/dev/null)"

    cd ..

    if [ -n "$CLUSTER_NAME" ] && [ -n "$AWS_REGION" ]; then
      echo "→ wait: EKS cluster active ($CLUSTER_NAME, $AWS_REGION)"
      aws eks wait cluster-active --name "$CLUSTER_NAME" --region "$AWS_REGION"

      echo "→ wait: Kubernetes API ready"
      set +e
      for i in {1..30}; do
        kubectl get ns >/dev/null 2>&1
        if [ $? -eq 0 ]; then
          break
        fi
        sleep 10
      done
      kubectl get ns >/dev/null 2>&1
      if [ $? -ne 0 ]; then
        echo "Kubernetes API not ready after waiting; aborting."
        exit 1
      fi
      set -e
    else
      echo "EKS wait skipped (could not determine cluster_name/aws_region)"
    fi

    cd "$module"
    echo "→ terraform apply (stage 2: remaining, incl. aws-load-balancer-controller)"
    terraform apply -auto-approve
    cd ..
  else
    echo "→ terraform plan"
    terraform plan -out=tfplan

    echo "→ terraform apply"
    terraform apply -auto-approve tfplan

    rm -f tfplan
    cd ..
  fi

  echo "[$module] 배포 완료"
  echo ""
done

# ============================
# Argo CD Bootstrap
# ============================
echo "========== [argocd] bootstrap =========="

if [ ! -d "argocd" ]; then
  echo "argocd 디렉토리를 찾을 수 없습니다."
  exit 1
fi

cd argocd

chmod +x argocd.sh
./argocd.sh

cd ..
echo "[argocd] bootstrap 완료"
echo ""

# ============================
# Wait for Ingress ALB (for CloudFront origin)
# ============================
INGRESS_NAMESPACE="${INGRESS_NAMESPACE:-default}"
INGRESS_NAME="${INGRESS_NAME:-factory-ingress}"
ALB_WAIT_MAX_TRIES="${ALB_WAIT_MAX_TRIES:-60}"
ALB_WAIT_SLEEP_SEC="${ALB_WAIT_SLEEP_SEC:-10}"

echo "========== [cloudfront] wait for ingress ALB =========="
ALB_DNS_NAME=""
set +e
for i in $(seq 1 "$ALB_WAIT_MAX_TRIES"); do
  ALB_DNS_NAME="$(kubectl get ingress -n "$INGRESS_NAMESPACE" "$INGRESS_NAME" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)"
  if [ -n "$ALB_DNS_NAME" ]; then
    break
  fi
  sleep "$ALB_WAIT_SLEEP_SEC"
done
set -e

if [ -n "$ALB_DNS_NAME" ]; then
  echo "Ingress ALB ready: $ALB_DNS_NAME"
else
  echo "Ingress ALB not ready after wait; continuing without explicit alb_dns_name."
fi
echo ""

REMAINING_MODULES=("cloudfront")

for module in "${REMAINING_MODULES[@]}"; do
  echo "========== [$module] 배포 중... =========="

  cd "$module"
  
  terraform init -reconfigure
  if [ -n "$ALB_DNS_NAME" ]; then
    terraform plan -out=tfplan -var="alb_dns_name=$ALB_DNS_NAME"
    terraform apply -auto-approve tfplan
  else
    terraform plan -out=tfplan
    terraform apply -auto-approve tfplan
  fi

  rm -f tfplan
  cd ..

  echo "[$module] 배포 완료"
  echo ""
done
