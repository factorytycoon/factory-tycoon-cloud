#!/bin/bash

# required AWS CLI v2 and Session Manager Plugin
# curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
# sudo dpkg -i session-manager-plugin.deb


set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}OpenSearch Dashboard SSM 포트포워딩${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 1. 리전/클러스터/노드그룹 확인
REGION=${AWS_REGION:-ap-northeast-2}
CLUSTER_NAME=${CLUSTER_NAME:-factory-tycoon-eks}
NODEGROUP_NAME=${NODEGROUP_NAME:-fe-mqtt-nodegroup}
echo -e "${YELLOW}🌍 리전: $REGION${NC}"
echo -e "${YELLOW}🛰️  클러스터: $CLUSTER_NAME${NC}"
echo -e "${YELLOW}🧩 노드그룹: $NODEGROUP_NAME${NC}"

# 2. EKS 노드 ID 가져오기 (노드그룹 → 클러스터 순으로 탐색)
echo -e "${YELLOW}🔍 EKS 노드 검색 중...${NC}"

NODE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:eks:nodegroup-name,Values=$NODEGROUP_NAME" \
            "Name=tag:kubernetes.io/cluster/$CLUSTER_NAME,Values=owned,shared" \
            "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].InstanceId' \
  --output text \
  --region "$REGION" 2>/dev/null | awk 'NF {print $1; exit}')

if [ -z "$NODE_ID" ] || [ "$NODE_ID" = "None" ]; then
  # 노드그룹 태그가 다를 경우를 대비해 클러스터 태그만으로 재탐색
  NODE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:kubernetes.io/cluster/$CLUSTER_NAME,Values=owned,shared" \
              "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].InstanceId' \
    --output text \
    --region "$REGION" 2>/dev/null | awk 'NF {print $1; exit}')
fi

if [ -z "$NODE_ID" ] || [ "$NODE_ID" = "None" ]; then
  echo -e "${RED}❌ 실행 중인 EKS 노드를 찾을 수 없습니다!${NC}"
  echo ""
  echo "✅ 해결 방법:"
  echo "  1. 클러스터/노드그룹 이름을 확인하거나 환경 변수로 지정하세요:"
  echo "     CLUSTER_NAME=factory-tycoon-eks NODEGROUP_NAME=fe-mqtt-nodegroup ./opensearch-tunnel.sh"
  echo ""
  echo "  2. 수동으로 노드 ID 확인:"
  echo "     aws ec2 describe-instances --region $REGION \\\n+       --filters Name=tag:kubernetes.io/cluster/$CLUSTER_NAME,Values=owned,shared Name=instance-state-name,Values=running"
  exit 1
fi

echo -e "${GREEN}✅ 노드 ID: $NODE_ID${NC}"

# 3. 노드 상태 확인
echo -e "${YELLOW}🔎 SSM 접근성 확인 중...${NC}"

SSM_PING=$(aws ssm describe-instance-information \
  --instance-information-filter-list "key=InstanceIds,valueSet=$NODE_ID" \
  --region "$REGION" 2>/dev/null || echo "")

if [ -z "$SSM_PING" ]; then
  echo -e "${YELLOW}⚠️  SSM 에이전트가 아직 준비 중일 수 있습니다.${NC}"
  echo "    잠시 후 다시 시도해주세요."
  exit 1
fi

echo -e "${GREEN}✅ SSM 접근 가능${NC}"

# 4. OpenSearch 엔드포인트 동적 조회
echo -e "${YELLOW}🔍 OpenSearch 엔드포인트 조회 중...${NC}"

# VPC 도메인은 Endpoints.vpc 에 위치함. 없으면 공용 Endpoint로 폴백.
OPENSEARCH_ENDPOINT=$(aws opensearch describe-domain \
  --domain-name factory-tycoon-search \
  --query 'DomainStatus.Endpoints.vpc' \
  --output text \
  --region "$REGION" 2>/dev/null || echo "")

if [ -z "$OPENSEARCH_ENDPOINT" ] || [ "$OPENSEARCH_ENDPOINT" = "None" ] || [ "$OPENSEARCH_ENDPOINT" = "null" ]; then
  OPENSEARCH_ENDPOINT=$(aws opensearch describe-domain \
    --domain-name factory-tycoon-search \
    --query 'DomainStatus.Endpoint' \
    --output text \
    --region "$REGION" 2>/dev/null || echo "")
fi

if [ -z "$OPENSEARCH_ENDPOINT" ] || [ "$OPENSEARCH_ENDPOINT" = "None" ] || [ "$OPENSEARCH_ENDPOINT" = "null" ]; then
  echo -e "${RED}❌ OpenSearch 엔드포인트를 찾을 수 없습니다!${NC}"
  echo ""
  echo "✅ 해결 방법:"
  echo "  1. OpenSearch 배포 확인:"
  echo "     terraform -chdir=opensearch apply"
  echo ""
  echo "  2. 또는 수동으로 확인 (VPC 도메인은 Endpoints.vpc):"
  echo "     aws opensearch describe-domain --domain-name factory-tycoon-search --region $REGION --query 'DomainStatus.Endpoints'"
  exit 1
fi

echo -e "${GREEN}✅ OpenSearch: $OPENSEARCH_ENDPOINT${NC}"

LOCAL_PORT=9200
REMOTE_PORT=443

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}포트포워딩 설정${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "노드 ID: ${GREEN}$NODE_ID${NC}"
echo -e "OpenSearch: ${GREEN}$OPENSEARCH_ENDPOINT${NC}"
echo -e "로컬 포트: ${GREEN}$LOCAL_PORT${NC} → 리모트 포트: ${GREEN}$REMOTE_PORT${NC}"
echo ""

# 5. SSM 포트포워딩 시작
echo -e "${YELLOW}🔗 포트포워딩 시작 중...${NC}"
echo -e "${YELLOW}Ctrl+C를 눌러 종료할 수 있습니다.${NC}"
echo ""

aws ssm start-session \
  --target "$NODE_ID" \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters "{
    \"host\":[\"$OPENSEARCH_ENDPOINT\"],
    \"portNumber\":[\"$REMOTE_PORT\"],
    \"localPortNumber\":[\"$LOCAL_PORT\"]
  }" \
  --region "$REGION"

exit_code=$?

if [ $exit_code -eq 0 ]; then
  echo ""
  echo -e "${GREEN}✅ 포트포워딩 성공!${NC}"
else
  echo ""
  echo -e "${RED}❌ 포트포워딩 실패 (종료 코드: $exit_code)${NC}"
  exit 1
fi