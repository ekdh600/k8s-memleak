#!/bin/bash

# Memory Leak Demo - 통합 빌드 및 배포 스크립트
# 이 스크립트는 Docker 이미지 빌드부터 Kubernetes 배포까지 자동으로 처리합니다.

set -e

echo "🚀 Memory Leak Demo 통합 빌드 및 배포 시작..."
echo "================================================"

# 사용법 출력
usage() {
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  --local          로컬 registry 사용 (기본값)"
    echo "  --docker-hub     Docker Hub 사용"
    echo "  --image-name     사용할 이미지 이름 (기본값: memory-leak-demo:latest)"
    echo "  --help           이 도움말 표시"
    echo ""
    echo "예시:"
    echo "  $0                    # 로컬 registry 사용"
    echo "  $0 --docker-hub       # Docker Hub 사용"
    echo "  $0 --image-name my-image:v1.0  # 사용자 정의 이미지 이름"
    echo ""
}

# 기본값 설정
USE_LOCAL=true
IMAGE_NAME="memory-leak-demo:latest"
DEPLOY_IMAGE=""

# 명령행 인수 파싱
while [[ $# -gt 0 ]]; do
    case $1 in
        --local)
            USE_LOCAL=true
            shift
            ;;
        --docker-hub)
            USE_LOCAL=false
            shift
            ;;
        --image-name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            echo "❌ 알 수 없는 옵션: $1"
            usage
            exit 1
            ;;
    esac
done

echo "🔧 설정:"
echo "  - 로컬 registry 사용: ${USE_LOCAL}"
echo "  - 이미지 이름: ${IMAGE_NAME}"
echo ""

# 1단계: Docker 이미지 빌드
echo "📦 1단계: Docker 이미지 빌드"
echo "================================"
./scripts/build.sh

# 2단계: 이미지 변환 및 배포
echo ""
echo "🚀 2단계: 이미지 변환 및 배포"
echo "================================"

if [ "$USE_LOCAL" = true ]; then
    echo "🏠 로컬 이미지 사용 모드"
    
    # 이미지 직접 import (registry 없이)
    echo "🔧 Docker 이미지를 containerd에 직접 import 중..."
    if command -v ctr &> /dev/null; then
        # Docker 이미지를 tar로 export
        docker save "${IMAGE_NAME}" > /tmp/image.tar
        
        # containerd에 import
        ctr -n k8s.io images import /tmp/image.tar
        
        # 임시 파일 정리
        rm -f /tmp/image.tar
        
        echo "✅ containerd에 이미지 import 완료"
        DEPLOY_IMAGE="${IMAGE_NAME}"
    else
        echo "❌ ctr 도구가 설치되지 않았습니다."
        echo "💡 containerd-tools를 설치하거나 Docker Hub를 사용하세요."
        exit 1
    fi
    
    echo "✅ 이미지 변환 완료: ${DEPLOY_IMAGE}"
else
    echo "🐳 Docker Hub 사용 모드"
    
    # Docker Hub 이미지 태그
    DOCKER_HUB_IMAGE="ekdh600/${IMAGE_NAME}"
    echo "🏷️ Docker Hub 이미지 태그: ${DOCKER_HUB_IMAGE}"
    
    if docker tag "${IMAGE_NAME}" "${DOCKER_HUB_IMAGE}"; then
        echo "✅ 이미지 태그 완료"
        
        # Docker Hub push 확인
        echo "📤 Docker Hub에 이미지 push 중..."
        if docker push "${DOCKER_HUB_IMAGE}"; then
            echo "✅ Docker Hub push 완료"
            DEPLOY_IMAGE="${DOCKER_HUB_IMAGE}"
        else
            echo "❌ Docker Hub push 실패"
            exit 1
        fi
    else
        echo "❌ 이미지 태그 실패"
        exit 1
    fi
fi

# 3단계: Kubernetes 배포
echo ""
echo "☸️ 3단계: Kubernetes 배포"
echo "================================"
echo "배포할 이미지: ${DEPLOY_IMAGE}"

./scripts/deploy.sh "${DEPLOY_IMAGE}"

echo ""
echo "🎉 통합 빌드 및 배포 완료!"
echo ""
echo "📋 배포된 리소스:"
kubectl -n memleak-demo get all
echo ""
echo "🌐 접속 정보:"
echo "- 애플리케이션: kubectl -n memleak-demo port-forward svc/stealth-memory-leaker 8080:8080"
echo "- Grafana: kubectl -n memleak-demo port-forward svc/grafana 3000:3000"
echo "- Prometheus: kubectl -n memleak-demo port-forward svc/prometheus 9090:9090"
echo ""
echo "🔍 eBPF 도구 설정:"
echo "./scripts/ebpf-setup.sh"
