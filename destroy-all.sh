#!/bin/bash

set -e  # 에러 발생 시 즉시 종료

START_TIME=$SECONDS

MODULES=("lambda" "opensearch" "iot" "elasticache" "argocd" "eks" "security-groups" "vpc")

echo "=========================================="
echo "Factory Tycoon Cloud destroy script"
echo "=========================================="
echo ""

kubectl delete application factory-tycoon-ingress -n argocd

for module in "${MODULES[@]}"; do
  echo "========== [$module] 제거 중... =========="
  
  if [ ! -d "$module" ]; then
    echo "$module 디렉토리를 찾을 수 없습니다."
    exit 1
  fi
  
  cd "$module"
  
  # IoT 리소스 사전 정리
  if [ "$module" = "iot" ]; then
    echo "→ IoT attachment 사전 정리"
    set +e
    for policy in $(aws iot list-policies --region ap-northeast-2 --query 'policies[?starts_with(policyName, `ft-policy`)].policyName' --output text 2>/dev/null); do
      for target in $(aws iot list-targets-for-policy --policy-name "$policy" --region ap-northeast-2 --query 'targets[]' --output text 2>/dev/null); do
        aws iot detach-policy --policy-name "$policy" --target "$target" --region ap-northeast-2 2>/dev/null || true
      done
    done
    for thing in $(aws iot list-things --region ap-northeast-2 --query 'things[?starts_with(thingName, `ft-`)].thingName' --output text 2>/dev/null); do
      for principal in $(aws iot list-thing-principals --thing-name "$thing" --region ap-northeast-2 --query 'principals[]' --output text 2>/dev/null); do
        aws iot detach-thing-principal --thing-name "$thing" --principal "$principal" --region ap-northeast-2 2>/dev/null || true
      done
    done
    set -e
  fi
  
  # terraform init
  echo "→ terraform init"
  terraform init -reconfigure
  
  # terraform destroy
  echo "→ terraform destroy"
  terraform destroy -auto-approve
  
  cd ..
  echo "[$module] 제거 완료"
  echo ""
done

ELAPSED=$((SECONDS - START_TIME))
MINUTES=$((ELAPSED / 60))
SECONDS_REMAINING=$((ELAPSED % 60))

echo "=========================================="
echo "destroy done"
echo "총 소요시간: ${MINUTES}분 ${SECONDS_REMAINING}초"
echo "=========================================="
