#!/bin/bash

# 🚨 메모리 누수 시뮬레이션 배포 스크립트
# 다른 쿠버네티스 클러스터에서 실행하기 위한 완전 자동화 스크립트

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 설정 변수
NAMESPACE=${NAMESPACE:-memleak-demo}
IMAGE_NAME=${IMAGE_NAME:-memleak}
IMAGE_TAG=${IMAGE_TAG:-latest}
CLUSTER_TYPE=${CLUSTER_TYPE:-unknown}

echo -e "${BLUE}🚨 메모리 누수 시뮬레이션 배포 시작${NC}"
echo -e "${BLUE}📱 네임스페이스: ${NAMESPACE}${NC}"
echo -e "${BLUE}🐳 이미지: ${IMAGE_NAME}:${IMAGE_TAG}${NC}"
echo -e "${BLUE}🏗️  클러스터 타입: ${CLUSTER_TYPE}${NC}"
echo ""

# 1. 사전 요구사항 확인
echo -e "${YELLOW}🔍 사전 요구사항 확인 중...${NC}"

# kubectl 확인
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl이 설치되지 않았습니다.${NC}"
    echo "설치 방법: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

# Docker 확인
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker가 설치되지 않았습니다.${NC}"
    echo "설치 방법: https://docs.docker.com/get-docker/"
    exit 1
fi

# Go 확인
if ! command -v go &> /dev/null; then
    echo -e "${RED}❌ Go가 설치되지 않았습니다.${NC}"
    echo "설치 방법: https://golang.org/doc/install"
    exit 1
fi

echo -e "${GREEN}✅ 사전 요구사항 확인 완료${NC}"
echo ""

# 2. 애플리케이션 빌드
echo -e "${YELLOW}🔨 애플리케이션 빌드 중...${NC}"

# Go 모듈 의존성 설치
go mod tidy

# 애플리케이션 빌드
go build -o app main.go

if [ ! -f "app" ]; then
    echo -e "${RED}❌ 애플리케이션 빌드 실패${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 애플리케이션 빌드 완료${NC}"
echo ""

# 3. Docker 이미지 빌드
echo -e "${YELLOW}🐳 Docker 이미지 빌드 중...${NC}"

docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Docker 이미지 빌드 실패${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker 이미지 빌드 완료${NC}"
echo ""

# 4. 클러스터 타입별 이미지 로드
echo -e "${YELLOW}📦 클러스터에 이미지 로드 중...${NC}"

case $CLUSTER_TYPE in
    "kind")
        echo "Kind 클러스터에 이미지 로드 중..."
        kind load docker-image ${IMAGE_NAME}:${IMAGE_TAG}
        ;;
    "minikube")
        echo "Minikube에 이미지 로드 중..."
        minikube image load ${IMAGE_NAME}:${IMAGE_TAG}
        ;;
    "docker-desktop")
        echo "Docker Desktop 클러스터 사용 중..."
        # 이미지가 이미 로컬에 있으므로 추가 작업 불필요
        ;;
    "aks"|"eks"|"gke"|"openshift")
        echo "클라우드 클러스터 사용 중..."
        echo "이미지를 레지스트리에 푸시해야 합니다:"
        echo "  docker tag ${IMAGE_NAME}:${IMAGE_TAG} <registry>/${IMAGE_NAME}:${IMAGE_TAG}"
        echo "  docker push <registry>/${IMAGE_NAME}:${IMAGE_TAG}"
        echo ""
        read -p "이미지를 레지스트리에 푸시했습니까? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${RED}❌ 이미지 푸시가 필요합니다.${NC}"
            exit 1
        fi
        ;;
    *)
        echo "알 수 없는 클러스터 타입: ${CLUSTER_TYPE}"
        echo "이미지 로드를 건너뜁니다."
        ;;
esac

echo -e "${GREEN}✅ 이미지 로드 완료${NC}"
echo ""

# 5. 쿠버네티스 리소스 배포
echo -e "${YELLOW}🚀 쿠버네티스 리소스 배포 중...${NC}"

# 네임스페이스 생성
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# 잠시 대기
sleep 2

# 모든 리소스 배포
kubectl apply -f k8s/

echo -e "${GREEN}✅ 쿠버네티스 리소스 배포 완료${NC}"
echo ""

# 6. 배포 상태 확인
echo -e "${YELLOW}📊 배포 상태 확인 중...${NC}"

# Deployment 상태 확인
kubectl -n ${NAMESPACE} rollout status deployment/leaky --timeout=120s

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 배포 성공!${NC}"
else
    echo -e "${RED}❌ 배포 실패${NC}"
    echo "문제 해결을 위해 다음 명령어를 실행하세요:"
    echo "  kubectl -n ${NAMESPACE} get events --sort-by='.lastTimestamp'"
    echo "  kubectl -n ${NAMESPACE} describe pod -l app=leaky"
    exit 1
fi

echo ""

# 7. 서비스 정보 출력
echo -e "${GREEN}🎉 메모리 누수 시뮬레이션 배포 완료!${NC}"
echo ""
echo -e "${BLUE}📋 사용 가능한 명령어:${NC}"
echo "  # Pod 상태 확인"
echo "  kubectl -n ${NAMESPACE} get all"
echo ""
echo "  # 로그 확인"
echo "  kubectl -n ${NAMESPACE} logs -f deployment/leaky"
echo ""
echo "  # 포트포워딩 (pprof 접근용)"
echo "  kubectl -n ${NAMESPACE} port-forward pod/\$(kubectl -n ${NAMESPACE} get pod -l app=leaky -o jsonpath='{.items[0].metadata.name}') 6060:6060"
echo ""
echo "  # 메모리 모니터링"
echo "  ./scripts/monitor-memory.sh"
echo ""
echo "  # 정리"
echo "  kubectl delete -f k8s/"
echo ""
echo -e "${BLUE}🌐 접근 URL:${NC}"
echo "  - pprof 디버그: http://localhost:6060/debug/pprof/"
echo "  - 힙 프로파일: http://localhost:6060/debug/pprof/heap"
echo ""
echo -e "${YELLOW}💡 다음 단계:${NC}"
echo "  1. 포트포워딩 설정"
echo "  2. pprof로 힙 프로파일 수집"
echo "  3. 메모리 모니터링 스크립트 실행"
echo "  4. eBPF 도구 설치 (선택사항)"
echo "  5. Prometheus + Grafana 구축 (선택사항)"