#!/bin/bash

# 🏗️ 클러스터 타입별 설정 스크립트
# 다양한 쿠버네티스 환경에서 메모리 누수 시뮬레이션을 위한 클러스터 설정

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 클러스터 타입 선택
echo -e "${BLUE}🏗️ 쿠버네티스 클러스터 설정${NC}"
echo ""
echo "사용 가능한 클러스터 타입:"
echo "1) kind - 로컬 개발용 (권장)"
echo "2) minikube - 로컬 개발용"
echo "3) docker-desktop - Docker Desktop 내장"
echo "4) aks - Azure Kubernetes Service"
echo "5) eks - Amazon EKS"
echo "6) gke - Google GKE"
echo "7) openshift - OpenShift"
echo "8) custom - 사용자 정의"
echo ""

read -p "클러스터 타입을 선택하세요 (1-8): " choice

case $choice in
    1)
        CLUSTER_TYPE="kind"
        setup_kind
        ;;
    2)
        CLUSTER_TYPE="minikube"
        setup_minikube
        ;;
    3)
        CLUSTER_TYPE="docker-desktop"
        setup_docker_desktop
        ;;
    4)
        CLUSTER_TYPE="aks"
        setup_aks
        ;;
    5)
        CLUSTER_TYPE="eks"
        setup_eks
        ;;
    6)
        CLUSTER_TYPE="gke"
        setup_gke
        ;;
    7)
        CLUSTER_TYPE="openshift"
        setup_openshift
        ;;
    8)
        CLUSTER_TYPE="custom"
        setup_custom
        ;;
    *)
        echo -e "${RED}❌ 잘못된 선택입니다.${NC}"
        exit 1
        ;;
esac

# 설정 완료 후 환경 변수 파일 생성
echo "export CLUSTER_TYPE=${CLUSTER_TYPE}" > .env
echo "export NAMESPACE=memleak-demo" >> .env
echo "export IMAGE_NAME=memleak" >> .env
echo "export IMAGE_TAG=latest" >> .env

echo ""
echo -e "${GREEN}✅ 클러스터 설정 완료!${NC}"
echo "환경 변수가 .env 파일에 저장되었습니다."
echo "배포를 시작하려면: ./deploy.sh"

# ===== 클러스터별 설정 함수들 =====

setup_kind() {
    echo -e "${YELLOW}🚀 Kind 클러스터 설정 중...${NC}"
    
    # kind 설치 확인
    if ! command -v kind &> /dev/null; then
        echo "kind 설치 중..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install kind
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-amd64
            chmod +x ./kind
            sudo mv ./kind /usr/local/bin/kind
        fi
    fi
    
    # 클러스터 생성
    CLUSTER_NAME="memleak-demo"
    kind create cluster --name ${CLUSTER_NAME} --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 6060
    hostPort: 6060
    protocol: TCP
EOF
    
    echo -e "${GREEN}✅ Kind 클러스터 생성 완료: ${CLUSTER_NAME}${NC}"
}

setup_minikube() {
    echo -e "${YELLOW}🚀 Minikube 설정 중...${NC}"
    
    # minikube 설치 확인
    if ! command -v minikube &> /dev/null; then
        echo "minikube 설치 중..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install minikube
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
            sudo install minikube-linux-amd64 /usr/local/bin/minikube
        fi
    fi
    
    # 클러스터 시작
    minikube start --driver=docker --memory=4096 --cpus=2
    
    echo -e "${GREEN}✅ Minikube 클러스터 시작 완료${NC}"
}

setup_docker_desktop() {
    echo -e "${YELLOW}🐳 Docker Desktop 설정 확인 중...${NC}"
    
    # Docker 실행 상태 확인
    if ! docker info &> /dev/null; then
        echo -e "${RED}❌ Docker Desktop이 실행되지 않았습니다.${NC}"
        echo "Docker Desktop을 시작한 후 다시 시도하세요."
        exit 1
    fi
    
    # 쿠버네티스 활성화 확인
    if ! kubectl cluster-info &> /dev/null; then
        echo -e "${RED}❌ Docker Desktop의 쿠버네티스가 비활성화되어 있습니다.${NC}"
        echo "Docker Desktop 설정에서 Kubernetes를 활성화하세요."
        exit 1
    fi
    
    echo -e "${GREEN}✅ Docker Desktop 쿠버네티스 확인 완료${NC}"
}

setup_aks() {
    echo -e "${YELLOW}☁️ Azure AKS 설정 중...${NC}"
    
    # Azure CLI 설치 확인
    if ! command -v az &> /dev/null; then
        echo "Azure CLI 설치 중..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install azure-cli
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
        fi
    fi
    
    echo "Azure에 로그인하세요:"
    az login
    
    echo "사용 가능한 구독:"
    az account list --output table
    
    read -p "구독 ID를 입력하세요: " SUBSCRIPTION_ID
    read -p "리소스 그룹 이름을 입력하세요: " RESOURCE_GROUP
    read -p "AKS 클러스터 이름을 입력하세요: " CLUSTER_NAME
    
    # 구독 설정
    az account set --subscription ${SUBSCRIPTION_ID}
    
    # AKS 자격 증명 가져오기
    az aks get-credentials --resource-group ${RESOURCE_GROUP} --name ${CLUSTER_NAME}
    
    echo -e "${GREEN}✅ AKS 클러스터 연결 완료: ${CLUSTER_NAME}${NC}"
}

setup_eks() {
    echo -e "${YELLOW}☁️ Amazon EKS 설정 중...${NC}"
    
    # AWS CLI 설치 확인
    if ! command -v aws &> /dev/null; then
        echo "AWS CLI 설치 중..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install awscli
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip awscliv2.zip
            sudo ./aws/install
        fi
    fi
    
    # AWS 자격 증명 설정
    echo "AWS 자격 증명을 설정하세요:"
    aws configure
    
    echo "사용 가능한 EKS 클러스터:"
    aws eks list-clusters --output table
    
    read -p "EKS 클러스터 이름을 입력하세요: " CLUSTER_NAME
    read -p "리전을 입력하세요 (예: us-west-2): " REGION
    
    # EKS 자격 증명 가져오기
    aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${REGION}
    
    echo -e "${GREEN}✅ EKS 클러스터 연결 완료: ${CLUSTER_NAME}${NC}"
}

setup_gke() {
    echo -e "${YELLOW}☁️ Google GKE 설정 중...${NC}"
    
    # gcloud CLI 설치 확인
    if ! command -v gcloud &> /dev/null; then
        echo "Google Cloud CLI 설치 중..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            curl https://sdk.cloud.google.com | bash
            exec -l $SHELL
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            curl https://sdk.cloud.google.com | bash
            exec -l $SHELL
        fi
    fi
    
    # Google Cloud 로그인
    echo "Google Cloud에 로그인하세요:"
    gcloud auth login
    
    echo "사용 가능한 프로젝트:"
    gcloud projects list --format="table(projectId,name)"
    
    read -p "프로젝트 ID를 입력하세요: " PROJECT_ID
    read -p "GKE 클러스터 이름을 입력하세요: " CLUSTER_NAME
    read -p "리전을 입력하세요 (예: us-central1): " REGION
    
    # 프로젝트 설정
    gcloud config set project ${PROJECT_ID}
    
    # GKE 자격 증명 가져오기
    gcloud container clusters get-credentials ${CLUSTER_NAME} --region ${REGION}
    
    echo -e "${GREEN}✅ GKE 클러스터 연결 완료: ${CLUSTER_NAME}${NC}"
}

setup_openshift() {
    echo -e "${YELLOW}🔴 OpenShift 설정 중...${NC}"
    
    # oc CLI 설치 확인
    if ! command -v oc &> /dev/null; then
        echo "OpenShift CLI 설치 중..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install openshift-cli
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            curl -L https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz | tar xz
            sudo mv oc /usr/local/bin/
        fi
    fi
    
    echo "OpenShift 서버 URL을 입력하세요:"
    read -p "서버 URL: " SERVER_URL
    read -p "사용자명: " USERNAME
    read -p "토큰 또는 비밀번호: " TOKEN
    
    # OpenShift 로그인
    oc login ${SERVER_URL} --username=${USERNAME} --password=${TOKEN}
    
    echo -e "${GREEN}✅ OpenShift 클러스터 연결 완료${NC}"
}

setup_custom() {
    echo -e "${YELLOW}🔧 사용자 정의 클러스터 설정${NC}"
    
    echo "사용자 정의 클러스터 정보를 입력하세요:"
    read -p "클러스터 이름: " CLUSTER_NAME
    read -p "kubeconfig 파일 경로 (선택사항): " KUBECONFIG_PATH
    
    if [ -n "$KUBECONFIG_PATH" ]; then
        export KUBECONFIG=${KUBECONFIG_PATH}
        echo "KUBECONFIG가 ${KUBECONFIG_PATH}로 설정되었습니다."
    fi
    
    # 클러스터 연결 확인
    if kubectl cluster-info &> /dev/null; then
        echo -e "${GREEN}✅ 사용자 정의 클러스터 연결 완료: ${CLUSTER_NAME}${NC}"
    else
        echo -e "${RED}❌ 클러스터 연결에 실패했습니다.${NC}"
        echo "kubeconfig 설정을 확인하세요."
        exit 1
    fi
}