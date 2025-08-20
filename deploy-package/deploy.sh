#!/bin/bash

# 🚀 간소화된 메모리 누수 시뮬레이션 배포 스크립트
# C 기반 메모리 누수 시뮬레이터 + eBPF 트래킹

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 설정
NAMESPACE="memleak-demo"
IMAGE_NAME="memory-leaker"
IMAGE_TAG="latest"

echo "🔬 메모리 누수 시뮬레이션 및 eBPF 트래킹 데모"
echo "=============================================="
echo ""

# 1. 사전 요구사항 확인
log_info "사전 요구사항 확인 중..."

# kubectl 확인
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl이 설치되지 않았습니다."
    log_info "설치 방법: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

# Docker 확인
if ! command -v docker &> /dev/null; then
    log_error "Docker가 설치되지 않았습니다."
    log_info "설치 방법: https://docs.docker.com/get-docker/"
    exit 1
fi

log_success "사전 요구사항 확인 완료"

# 2. 네임스페이스 생성
log_info "네임스페이스 생성 중..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
log_success "네임스페이스 생성 완료: $NAMESPACE"

# 3. Docker 이미지 빌드
log_info "Docker 이미지 빌드 중..."
docker build -t $IMAGE_NAME:$IMAGE_TAG .
log_success "Docker 이미지 빌드 완료: $IMAGE_NAME:$IMAGE_TAG"

# 4. 이미지 로드 (Kind/Minikube용)
if kubectl config current-context | grep -q "kind\|minikube"; then
    log_info "로컬 클러스터에 이미지 로드 중..."
    if kubectl config current-context | grep -q "kind"; then
        kind load docker-image $IMAGE_NAME:$IMAGE_TAG
        log_success "Kind 클러스터에 이미지 로드 완료"
    elif kubectl config current-context | grep -q "minikube"; then
        eval $(minikube docker-env)
        docker build -t $IMAGE_NAME:$IMAGE_TAG .
        log_success "Minikube에 이미지 로드 완료"
    fi
fi

# 5. 쿠버네티스 리소스 배포
log_info "쿠버네티스 리소스 배포 중..."
kubectl apply -f k8s/
log_success "쿠버네티스 리소스 배포 완료"

# 6. 배포 상태 확인
log_info "배포 상태 확인 중..."
kubectl -n $NAMESPACE rollout status deployment/memory-leaker --timeout=120s
log_success "배포 완료!"

# 7. 상태 출력
echo ""
log_info "배포된 리소스:"
kubectl -n $NAMESPACE get all

echo ""
log_info "Pod 로그 (최근 10줄):"
kubectl -n $NAMESPACE logs -l app=memory-leaker --tail=10

echo ""
log_success "🎉 메모리 누수 시뮬레이션 배포 완료!"
echo ""
echo "📋 다음 단계:"
echo "1. eBPF 도구 설치: kubectl apply -f https://raw.githubusercontent.com/inspektor-gadget/inspektor-gadget/main/deploy/gadget.yaml"
echo "2. 메모리 누수 추적: kubectl gadget memleak -n $NAMESPACE -p <pod-name>"
echo "3. 상태 확인: kubectl -n $NAMESPACE get all"
echo "4. 로그 확인: kubectl -n $NAMESPACE logs -f deployment/memory-leaker"
echo ""
echo "🔍 eBPF 트래킹 가이드: https://github.com/ekdh600/k8s-memleak/blob/main/EBPF_GUIDE.md"
echo ""
echo "🧹 정리: ./cleanup.sh"