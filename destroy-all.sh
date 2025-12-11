#!/bin/bash

set -e  # 에러 발생 시 즉시 종료

MODULES=("iot" "elasticache" "eks" "vpc" "s3")

echo "=========================================="
echo "Factory Tycoon Cloud destroy script"
echo "=========================================="
echo ""

for module in "${MODULES[@]}"; do
  echo "========== [$module] 제거 중... =========="
  
  if [ ! -d "$module" ]; then
    echo "$module 디렉토리를 찾을 수 없습니다."
    exit 1
  fi
  
  cd "$module"
  
  # terraform init
  echo "→ terraform init"
  terraform init
  
  # terraform destroy
  echo "→ terraform destroy"
  terraform destroy -auto-approve
  
  cd ..
  echo "✅ [$module] 제거 완료"
  echo ""
done

echo "=========================================="
echo "destroy done"
echo "=========================================="
