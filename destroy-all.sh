#!/bin/bash

set -e  # 에러 발생 시 즉시 종료

START_TIME=$SECONDS

MODULES=("argocd" "lambda" "opensearch" "iot" "elasticache" "eks" "security-groups" "vpc")

echo "=========================================="
echo "Factory Tycoon Cloud destroy script"
echo "=========================================="
echo ""

# VPC 리소스 사전 정리 (IGW 분리 전 필수)
echo "→ VPC 리소스 정리 중..."
set +e

# Elastic IP 해제
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=sf-vpc" --query 'Vpcs[0].VpcId' --output text --region ap-northeast-2 2>/dev/null)
if [ "$VPC_ID" != "None" ] && [ -n "$VPC_ID" ]; then
  echo "  - VPC ID: $VPC_ID"
  
  # Elastic IP 해제
  ALLOCATION_IDS=$(aws ec2 describe-addresses --filters "Name=vpc-id,Values=$VPC_ID" --query 'Addresses[*].AllocationId' --output text --region ap-northeast-2 2>/dev/null)
  if [ -n "$ALLOCATION_IDS" ] && [ "$ALLOCATION_IDS" != "" ]; then
    for ALLOC_ID in $ALLOCATION_IDS; do
      echo "  - Releasing Elastic IP: $ALLOC_ID"
      aws ec2 release-address --allocation-id "$ALLOC_ID" --region ap-northeast-2 2>/dev/null || true
    done
  fi
  
  # ENI 정리 (NAT Gateway 등에서 사용)
  ENI_IDS=$(aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=$VPC_ID" --query 'NetworkInterfaces[?Status==`available`].NetworkInterfaceId' --output text --region ap-northeast-2 2>/dev/null)
  if [ -n "$ENI_IDS" ] && [ "$ENI_IDS" != "" ]; then
    for ENI_ID in $ENI_IDS; do
      echo "  - Deleting ENI: $ENI_ID"
      aws ec2 delete-network-interface --network-interface-id "$ENI_ID" --region ap-northeast-2 2>/dev/null || true
    done
  fi
fi

set -e

echo ""
kubectl delete application factory-tycoon-ingress -n argocd 2>/dev/null || true

echo "→ Wait: Ingress controller to remove ALB (takes ~30-60 seconds)"
set +e
for i in {1..60}; do
  ALB_COUNT=$(aws ec2 describe-load-balancers --region ap-northeast-2 --query "LoadBalancers[?Tags[?Key=='elbv2.k8s.aws/cluster']].LoadBalancerArn | length(@)" 2>/dev/null || echo "0")
  if [ "$ALB_COUNT" -eq "0" ]; then
    echo "✓ ALB successfully removed"
    break
  fi
  echo "  Waiting... ALB still exists ($ALB_COUNT found), waiting..."
  sleep 2
done
set -e

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
