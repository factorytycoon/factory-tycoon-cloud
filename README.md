# Factory Tycoon Cloud Infrastructure

Terraform을 사용하여 AWS에 Smart Factory 시뮬레이션 게임을 위한 EKS 클러스터를 구축하는 프로젝트입니다.

## 디렉토리 구조
```
factory-tycoon-cloud/
├── vpc/                    # VPC 인프라 (네트워크 기반)
│   ├── main.tf            # VPC, Subnet, IGW, NAT Gateway 정의
│   ├── providers.tf
│   ├── variables.tf
│   ├── versions.tf
│   └── outputs.tf
│
├── eks/                    # EKS 클러스터 (Kubernetes)
│   ├── main.tf            # EKS 클러스터 및 노드그룹 정의
│   ├── providers.tf
│   ├── variables.tf
│   ├── terraform.tfvars   # VPC ID 및 Subnet ID 설정
│   ├── versions.tf
│   └── outputs.tf
│
└── README.md
```

## 아키텍처 개요

### VPC 구성
- **CIDR**: 10.0.0.0/16
- **Public Subnets**: 2개 (ap-northeast-2a, 2c)
  - 10.0.1.0/24, 10.0.2.0/24
- **Private Subnets**: 2개 (ap-northeast-2a, 2c)
  - 10.0.10.0/24, 10.0.20.0/24
- **NAT Gateway**: Public Subnet에 배치
- **Internet Gateway**: VPC에 연결

### EKS 구성
- **Kubernetes 버전**: 1.29
- **노드그룹 2개**:
  - **FE/MQTT 노드그룹**: t3.small (Frontend & MQTT 브로커용)
  - **BE 노드그룹**: t3.small (Backend & DB용)
- **배포 위치**: Private Subnets
- **접근**: Public Endpoint 활성화

## 사전 준비
- Terraform 1.5+
- AWS CLI v2 (`aws configure`로 자격증명 설정)
- kubectl
- AWS 계정 권한: VPC, IAM, EKS, EC2 생성 권한

## 배포 가이드

### 1단계: VPC 인프라 배포

```bash
# VPC 디렉토리로 이동
cd vpc

# 초기화 및 검증
terraform init
terraform validate

# 배포 계획 확인
terraform plan

# VPC 배포 (약 5분 소요)
terraform apply

# VPC ID 및 Subnet ID 확인
terraform output
```

출력 예시:
```
vpc_id = "vpc-044da7bca7878d0c0"
private_subnets = [
  "subnet-0731f398a458c8b30",
  "subnet-0a2d9f07c4af15fda"
]
public_subnets = [
  "subnet-xxxxx",
  "subnet-xxxxx"
]
```

### 2단계: EKS 클러스터 배포

```bash
# EKS 디렉토리로 이동
cd ../eks

# terraform.tfvars 파일에 VPC ID와 Private Subnet ID 입력
# (1단계에서 출력된 값 사용)
```

`terraform.tfvars` 예시:
```hcl
cluster_name = "smart-eks"

vpc_id = "vpc-044da7bca7878d0c0"

private_subnets = [
  "subnet-0731f398a458c8b30",
  "subnet-0a2d9f07c4af15fda"
]

aws_region = "ap-northeast-2"
```

```bash
# 초기화 및 검증
terraform init
terraform validate

# EKS 배포 (약 15~20분 소요)
terraform apply

# kubeconfig 설정
aws eks update-kubeconfig --name smart-eks --region ap-northeast-2

# 노드 확인
kubectl get nodes
```

### 3단계: 클러스터 확인

```bash
# 노드 상세 정보 확인
kubectl get nodes -o wide

# 노드 레이블 확인
kubectl get nodes --show-labels

# Frontend/MQTT 노드 확인
kubectl get nodes -l role=frontend

# Backend 노드 확인
kubectl get nodes -l role=backend
```

## 리소스 삭제

**중요**: 반드시 역순으로 삭제해야 합니다!

```bash
# 1) Kubernetes 리소스 먼저 삭제 (LoadBalancer, PVC 등)
kubectl get svc --all-namespaces
kubectl get pvc --all-namespaces
# 필요시 삭제: kubectl delete svc <service-name>

# 2) EKS 클러스터 삭제
cd eks
terraform destroy

# 3) VPC 삭제
cd ../vpc
terraform destroy
```

## 비용 안내
- **EKS 클러스터**: 시간당 ~$0.10
- **NAT Gateway**: 시간당 ~$0.045 + 데이터 처리 비용
- **t3.small 노드** (2개): 시간당 ~$0.042 (각 $0.021)
- **EBS 볼륨**: GB당 $0.10/월

**예상 월 비용**: 약 $100~150 (24시간 가동 시)

## 주의사항
- VPC를 먼저 생성해야 EKS 배포가 가능합니다
- `terraform.tfvars`에 올바른 VPC ID와 Private Subnet ID를 입력해야 합니다
- NAT Gateway는 고정 비용이 발생하므로 테스트 후 반드시 삭제하세요
- EKS 삭제 전에 Kubernetes 리소스(LoadBalancer, PVC)를 먼저 삭제해야 합니다
- Private Subnet에 노드가 배치되므로 외부 접근은 LoadBalancer를 통해서만 가능합니다

## 트러블슈팅

### VPC 삭제 시 오류 발생
```bash
# ENI(Network Interface)가 남아있는 경우
# AWS Console > EC2 > Network Interfaces에서 수동 삭제 후 재시도
```

### EKS 노드가 안 뜰 때
```bash
# IAM 권한 확인
aws sts get-caller-identity

# 노드그룹 상태 확인
aws eks describe-nodegroup --cluster-name smart-eks --nodegroup-name fe-mqtt-nodegroup
```

### kubectl 연결 안 될 때
```bash
# kubeconfig 재설정
aws eks update-kubeconfig --name smart-eks --region ap-northeast-2 --alias smart-eks

# 클러스터 상태 확인
aws eks describe-cluster --name smart-eks --query cluster.status
```