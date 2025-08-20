#!/bin/bash

# 🧹 메모리 누수 시뮬레이션 정리 스크립트

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

echo "🧹 메모리 누수 시뮬레이션 정리"
echo "=============================="
echo ""

# 확인
read -p "정말로 모든 리소스를 삭제하시겠습니까? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_warning "정리가 취소되었습니다."
    exit 0
fi

# 1. 쿠버네티스 리소스 삭제
log_info "쿠버네티스 리소스 삭제 중..."
kubectl delete -f k8s/ --ignore-not-found=true
log_success "쿠버네티스 리소스 삭제 완료"

# 2. 네임스페이스 삭제
log_info "네임스페이스 삭제 중..."
kubectl delete namespace $NAMESPACE --ignore-not-found=true
log_success "네임스페이스 삭제 완료: $NAMESPACE"

# 3. Docker 이미지 삭제
log_info "Docker 이미지 삭제 중..."
docker rmi $IMAGE_NAME:$IMAGE_TAG 2>/dev/null || log_warning "이미지가 존재하지 않습니다"
log_success "Docker 이미지 정리 완료"

# 4. Inspektor Gadget 삭제 (선택사항)
read -p "Inspektor Gadget도 삭제하시겠습니까? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Inspektor Gadget 삭제 중..."
    kubectl delete -f https://raw.githubusercontent.com/inspektor-gadget/inspektor-gadget/main/deploy/gadget.yaml --ignore-not-found=true
    log_success "Inspektor Gadget 삭제 완료"
fi

# 5. 정리 완료
echo ""
log_success "🎉 모든 리소스 정리 완료!"
echo ""
echo "📋 정리된 항목:"
echo "- 네임스페이스: $NAMESPACE"
echo "- 배포: memory-leaker"
echo "- 서비스: memory-leaker-service"
echo "- Docker 이미지: $IMAGE_NAME:$IMAGE_TAG"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "- eBPF 도구: Inspektor Gadget"
fi
echo ""
echo "🔄 재배포하려면: ./deploy.sh"