#!/bin/bash

set -e  # 에러 발생 시 즉시 종료

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
    # Lambda 모듈일 경우 의존성 빌드 먼저 실행
    if [ "$module" = "lambda" ]; then
      echo "→ Lambda 의존성 빌드 중..."
      if [ -f "build.sh" ]; then
        ./build.sh
        echo "→ Lambda 의존성 빌드 완료"
      else
        echo "[!] build.sh를 찾을 수 없습니다. 건너뜁니다."
      fi
    fi
  
  
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

ELAPSED=$((SECONDS - START_TIME))
MINUTES=$((ELAPSED / 60))
SECONDS_REMAINING=$((ELAPSED % 60))

echo "=========================================="
echo "deploy done"
echo "총 소요시간: ${MINUTES}분 ${SECONDS_REMAINING}초"
echo "=========================================="
