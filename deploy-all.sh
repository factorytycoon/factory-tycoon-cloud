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

  echo "→ terraform plan"
  terraform plan -out=tfplan

  echo "→ terraform apply"
  terraform apply -auto-approve tfplan

  rm -f tfplan
  cd ..

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

REMAINING_MODULES=("cloudfront")

for module in "${REMAINING_MODULES[@]}"; do
  echo "========== [$module] 배포 중... =========="

  cd "$module"
  
  terraform init -reconfigure
  terraform plan -out=tfplan
  terraform apply -auto-approve tfplan

  rm -f tfplan
  cd ..

  echo "[$module] 배포 완료"
  echo ""
done
