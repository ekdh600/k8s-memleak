#!/bin/bash

# 🧹 정리 스크립트
# 메모리 누수 시뮬레이션 환경 정리

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 설정 변수
NAMESPACE=${NAMESPACE:-memleak-demo}
POD_LABEL=${POD_LABEL:-app=leaky}
CLEANUP_IMAGES=${CLEANUP_IMAGES:-false}
CLEANUP_PROFILES=${CLEANUP_PROFILES:-false}

# 사용법 출력
usage() {
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  -n, --namespace NAMESPACE     쿠버네티스 네임스페이스 (기본값: memleak-demo)"
    echo "  -l, --label POD_LABEL         Pod 라벨 선택자 (기본값: app=leaky)"
    echo "  -i, --cleanup-images          Docker 이미지도 정리"
    echo "  -p, --cleanup-profiles        프로파일 파일도 정리"
    echo "  -a, --cleanup-all             모든 리소스 정리"
    echo "  -h, --help                    이 도움말 출력"
    echo ""
    echo "예시:"
    echo "  $0 -n memleak-demo"
    echo "  $0 --cleanup-all"
}

# 명령행 인수 파싱
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -l|--label)
            POD_LABEL="$2"
            shift 2
            ;;
        -i|--cleanup-images)
            CLEANUP_IMAGES=true
            shift
            ;;
        -p|--cleanup-profiles)
            CLEANUP_PROFILES=true
            shift
            ;;
        -a|--cleanup-all)
            CLEANUP_IMAGES=true
            CLEANUP_PROFILES=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "알 수 없는 옵션: $1"
            usage
            exit 1
            ;;
    esac
done

echo -e "${BLUE}🧹 메모리 누수 시뮬레이션 환경 정리${NC}"
echo "📱 네임스페이스: $NAMESPACE"
echo "🎯 Pod 라벨: $POD_LABEL"
echo "🐳 이미지 정리: $CLEANUP_IMAGES"
echo "📁 프로파일 정리: $CLEANUP_PROFILES"
echo ""

# 확인 메시지
echo -e "${YELLOW}⚠️  이 작업은 다음을 삭제합니다:${NC}"
echo "   - 네임스페이스: $NAMESPACE"
echo "   - 모든 관련 쿠버네티스 리소스"
if [ "$CLEANUP_IMAGES" = true ]; then
    echo "   - Docker 이미지: memleak:latest"
fi
if [ "$CLEANUP_PROFILES" = true ]; then
    echo "   - 프로파일 파일들"
fi
echo ""

read -p "계속하시겠습니까? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}❌ 정리가 취소되었습니다.${NC}"
    exit 0
fi

echo ""

# 1. 포트포워딩 프로세스 종료
echo -e "${YELLOW}🔌 포트포워딩 프로세스 종료 중...${NC}"
pkill -f "kubectl.*port-forward.*$PORT" 2>/dev/null || true
echo -e "${GREEN}✅ 포트포워딩 프로세스 종료 완료${NC}"

# 2. 쿠버네티스 리소스 정리
echo -e "${YELLOW}🗑️  쿠버네티스 리소스 정리 중...${NC}"

# Deployment 삭제
if kubectl -n "$NAMESPACE" get deployment/leaky 2>/dev/null; then
    kubectl -n "$NAMESPACE" delete deployment/leaky --ignore-not-found=true
    echo "   ✅ Deployment 삭제 완료"
fi

# Service 삭제
if kubectl -n "$NAMESPACE" get service/leaky-service 2>/dev/null; then
    kubectl -n "$NAMESPACE" delete service/leaky-service --ignore-not-found=true
    echo "   ✅ Service 삭제 완료"
fi

# Ingress 삭제
if kubectl -n "$NAMESPACE" get ingress/leaky-ingress 2>/dev/null; then
    kubectl -n "$NAMESPACE" delete ingress/leaky-ingress --ignore-not-found=true
    echo "   ✅ Ingress 삭제 완료"
fi

# ConfigMap 삭제
if kubectl -n "$NAMESPACE" get configmap/prometheus-config 2>/dev/null; then
    kubectl -n "$NAMESPACE" delete configmap/prometheus-config --ignore-not-found=true
    echo "   ✅ ConfigMap 삭제 완료"
fi

# 네임스페이스 삭제
if kubectl get namespace "$NAMESPACE" 2>/dev/null; then
    kubectl delete namespace "$NAMESPACE" --ignore-not-found=true
    echo "   ✅ 네임스페이스 삭제 완료"
fi

echo -e "${GREEN}✅ 쿠버네티스 리소스 정리 완료${NC}"

# 3. Docker 이미지 정리
if [ "$CLEANUP_IMAGES" = true ]; then
    echo -e "${YELLOW}🐳 Docker 이미지 정리 중...${NC}"
    
    # memleak 이미지 삭제
    if docker images | grep -q "memleak.*latest"; then
        docker rmi memleak:latest --force 2>/dev/null || true
        echo "   ✅ memleak:latest 이미지 삭제 완료"
    fi
    
    # 사용하지 않는 이미지 정리
    docker image prune -f 2>/dev/null || true
    echo "   ✅ 사용하지 않는 이미지 정리 완료"
    
    echo -e "${GREEN}✅ Docker 이미지 정리 완료${NC}"
fi

# 4. 프로파일 파일 정리
if [ "$CLEANUP_PROFILES" = true ]; then
    echo -e "${YELLOW}📁 프로파일 파일 정리 중...${NC}"
    
    # 프로파일 파일 삭제
    if [ -d "./profiles" ]; then
        rm -rf ./profiles
        echo "   ✅ profiles 디렉토리 삭제 완료"
    fi
    
    # 개별 프로파일 파일 삭제
    find . -name "*.pb" -type f -delete 2>/dev/null || true
    echo "   ✅ .pb 파일 삭제 완료"
    
    echo -e "${GREEN}✅ 프로파일 파일 정리 완료${NC}"
fi

# 5. 로컬 빌드 파일 정리
echo -e "${YELLOW}🔨 로컬 빌드 파일 정리 중...${NC}"

# Go 빌드 파일 삭제
if [ -f "./app" ]; then
    rm ./app
    echo "   ✅ Go 빌드 파일 삭제 완료"
fi

# 로그 파일 삭제
find . -name "*.log" -type f -delete 2>/dev/null || true
echo "   ✅ 로그 파일 삭제 완료"

echo -e "${GREEN}✅ 로컬 빌드 파일 정리 완료${NC}"

# 6. 환경 변수 파일 정리
if [ -f ".env" ]; then
    echo -e "${YELLOW}⚙️  환경 변수 파일 정리 중...${NC}"
    rm .env
    echo -e "${GREEN}✅ 환경 변수 파일 정리 완료${NC}"
fi

echo ""
echo -e "${GREEN}🎉 정리 완료!${NC}"
echo ""
echo -e "${BLUE}💡 다음에 다시 사용하려면:${NC}"
echo "  1. ./scripts/setup-cluster.sh - 클러스터 설정"
echo "  2. ./deploy.sh - 배포"
echo "  3. ./scripts/monitor-memory.sh - 모니터링"
echo "  4. ./scripts/collect-profiles.sh - 프로파일 수집"
echo ""
echo -e "${YELLOW}⚠️  주의: 모든 데이터가 삭제되었습니다.${NC}"