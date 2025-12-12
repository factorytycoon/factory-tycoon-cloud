# EC2 모듈

Ubuntu 22.04 LTS 기반 EC2 인스턴스를 Public Subnet에 배포합니다.

## 생성 리소스

- **EC2 Instance**: t3.large, Ubuntu 22.04 LTS
- **Security Group**: SSH(22), 8080-8081 포트 인바운드 허용
- **EBS Volume**: gp3 30GB (암호화)

## 사전 준비

### 1. 키페어 생성 (AWS Console 또는 CLI)
```bash
# AWS Console에서 생성하거나
aws ec2 create-key-pair --key-name mw_key --query 'KeyMaterial' --output text > ~/.ssh/mw_key.pem
chmod 400 ~/.ssh/mw_key.pem
```

### 2. VPC 배포 완료
- VPC가 먼저 배포되어 있어야 합니다 (Public Subnet 필요)

## 배포 방법

```bash
cd ec2
terraform init
terraform plan
terraform apply
```

## 출력값 확인

```bash
terraform output instance_public_ip   # Public IP
terraform output ssh_connection        # SSH 접속 명령어
terraform output application_urls      # 애플리케이션 URL
```

## SSH 접속

```bash
# 출력된 명령어 사용
ssh -i ~/.ssh/mw_key.pem ubuntu@<PUBLIC_IP>
```

## 애플리케이션 배포

인스턴스 접속 후:
```bash
# 패키지 업데이트
sudo apt update && sudo apt upgrade -y

# Docker 설치 (예시)
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu

# 8080 포트에서 테스트 애플리케이션 실행
docker run -d -p 8080:80 nginx
```

브라우저에서 `http://<PUBLIC_IP>:8080` 접속 확인.

## 보안 권장사항

### SSH 접근 제한
`terraform.tfvars`에서 `allowed_ssh_cidr`를 특정 IP로 제한:
```terraform
allowed_ssh_cidr = ["YOUR_IP/32"]
```

### 인스턴스 중지/재시작
```bash
# 중지 (비용 절감, EBS 비용은 계속 발생)
aws ec2 stop-instances --instance-ids <INSTANCE_ID>

# 시작
aws ec2 start-instances --instance-ids <INSTANCE_ID>
```

## 비용

- **EC2 t3.large**: 시간당 ~$0.0832 (~$60/월, 24시간 가동 시)
- **EBS gp3 30GB**: 월 ~$2.4
- **총 예상**: ~$62/월

## 주의사항

- Public Subnet에 배치되어 외부에서 직접 접근 가능
- SSH 키페어(`mw_key`)는 사전에 AWS에 생성되어 있어야 함
- 키페어 분실 시 인스턴스 접속 불가
- 사용하지 않을 때는 인스턴스 중지 권장

## 삭제

```bash
terraform destroy
```
