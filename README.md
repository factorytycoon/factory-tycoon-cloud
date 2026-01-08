# Factory Tycoon Cloud

Terraform 기반 AWS 인프라 배포 및 관리

## 기술 스택

- Terraform
- AWS (EKS, EC2, S3, ElastiCache, OpenSearch, IoT Core, Lambda)
- Kubernetes
- ArgoCD
- Helm

## 주요 인프라

- **VPC**: 네트워크 구성 (서브넷, 라우팅 테이블)
- **EKS**: Kubernetes 클러스터 (버전 1.34)
- **EC2**: 추가 워크로드 인스턴스
- **ElastiCache**: Redis 클러스터
- **OpenSearch**: 로그 및 데이터 검색
- **IoT Core**: IoT 장치 통신
- **Lambda**: 서버리스 함수
- **S3**: 객체 저장소
- **ArgoCD**: GitOps 기반 배포

## 배포 방법

### 전체 배포

```bash
# 모든 인프라 배포 순서: VPC → SG → EKS → ElastiCache → IoT → OpenSearch → Lambda
$ ./deploy-all.sh
```

### 개별 배포

```bash
$ cd <module-name>
$ terraform init -reconfigure
$ terraform plan
$ terraform apply -auto-approve
```

## 모듈 구조

```
├── vpc/              # VPC, 서브넷, NAT Gateway
├── security-groups/  # 보안 그룹
├── eks/              # EKS 클러스터, IRSA, kubeconfig
├── elasticache/      # Redis 클러스터
├── iot/              # IoT Core, 인증서
├── opensearch/       # OpenSearch 도메인
├── lambda/           # Lambda 함수
├── s3/               # S3 버킷
├── cloudfront/       # CloudFront 배포
├── argocd/           # ArgoCD 설치 및 설정
└── ec2/              # 추가 EC2 인스턴스
```

## 환경 설정

각 모듈의 `terraform.tfvars` 파일 생성:

```terraform
aws_region       = "ap-northeast-2"
github_username  = "your-github-username"
github_pat       = "your-github-token"
```

## 배포 확인

```bash
# EKS 클러스터 확인
$ kubectl get nodes

# ArgoCD 접속
$ kubectl port-forward -n argocd svc/argocd-server 8080:443

# OpenSearch 접속 (포트포워딩)
$ ./opensearch-tunnel.sh
```

## 인프라 제거

```bash
# 모든 인프라 삭제
$ ./destroy-all.sh
```

## 주요 스크립트

- `deploy-all.sh` - 전체 인프라 자동 배포
- `destroy-all.sh` - 전체 인프라 삭제
- `opensearch-tunnel.sh` - OpenSearch Dashboard SSM 포트포워딩
