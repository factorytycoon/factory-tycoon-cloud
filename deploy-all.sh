#!/bin/bash

set -e  # 에러 발생 시 즉시 종료

MODULES=("s3" "vpc" "security-groups" "eks" "elasticache" "iot" "opensearch")

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
  
  # terraform init
  echo "→ terraform init -reconfigure"
  terraform init -reconfigure
  
  # terraform plan
  echo "→ terraform plan"
  terraform plan -out=tfplan
  
  # terraform apply
  echo "→ terraform apply"
  terraform apply -auto-approve tfplan
  
  # 정리
  rm -f tfplan
  
  cd ..
  echo "[$module] 배포 완료"
  echo ""
done

echo "=========================================="
echo "deploy done"
echo "=========================================="
