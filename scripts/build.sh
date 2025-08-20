#!/bin/bash

# Memory Leak Demo - Docker 이미지 빌드 스크립트
# 이 스크립트는 메모리 누수 시뮬레이션을 위한 Docker 이미지를 빌드합니다.

set -e

echo "🐳 Memory Leak Demo Docker 이미지 빌드 시작..."

# 현재 디렉토리 확인
if [ ! -f "Dockerfile" ]; then
    echo "❌ Dockerfile을 찾을 수 없습니다. 프로젝트 루트 디렉토리에서 실행하세요."
    exit 1
fi

# Docker 데몬 실행 확인
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker 데몬이 실행되지 않았습니다. Docker를 시작하세요."
    exit 1
fi

# 이미지 태그 설정
IMAGE_NAME="memory-leak-demo"
TAG="latest"
FULL_IMAGE_NAME="${IMAGE_NAME}:${TAG}"

echo "🔨 이미지 빌드 중: ${FULL_IMAGE_NAME}"

# 기존 이미지 제거 (선택사항)
if docker images | grep -q "${IMAGE_NAME}"; then
    echo "🗑️ 기존 이미지 제거 중..."
    docker rmi "${FULL_IMAGE_NAME}" || true
fi

# 이미지 빌드
echo "🚀 Docker 이미지 빌드 시작..."
docker build -t "${FULL_IMAGE_NAME}" .

# 빌드 결과 확인
if [ $? -eq 0 ]; then
    echo "✅ 이미지 빌드 성공!"
    echo "📊 이미지 정보:"
    docker images "${FULL_IMAGE_NAME}"
    
    # 이미지 변환 옵션
    echo ""
    echo "🔄 이미지 변환 옵션:"
    echo "1. CRI 이미지로 변환 (로컬 Kubernetes 사용):"
    echo "   ./scripts/convert-image.sh"
    echo ""
    echo "2. Docker Hub에 push (원격 Kubernetes 사용):"
    echo "   docker tag ${FULL_IMAGE_NAME} ekdh600/${FULL_IMAGE_NAME}"
    echo "   docker push ekdh600/${FULL_IMAGE_NAME}"
    echo ""
    echo "🎯 다음 단계:"
    echo "1. 로컬 테스트: docker-compose up -d"
    echo "2. 로컬 Kubernetes 배포: ./scripts/convert-image.sh && ./scripts/deploy.sh localhost:5000/memory-leak-demo:latest"
    echo "3. 원격 Kubernetes 배포: ./scripts/deploy.sh ekdh600/memory-leak-demo:latest"
    echo "4. eBPF 도구 설정: ./scripts/ebpf-setup.sh"
else
    echo "❌ 이미지 빌드 실패!"
    exit 1
fi
