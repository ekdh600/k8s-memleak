#!/bin/bash

# Docker 이미지를 CRI 이미지로 변환하는 스크립트
# 이 스크립트는 로컬 Docker 이미지를 Kubernetes에서 사용할 수 있도록 변환합니다.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 기본값 설정
SOURCE_IMAGE=${1:-"memory-leak-demo:latest"}
TARGET_IMAGE=${2:-"memory-leak-demo:latest"}
REGISTRY=${3:-"localhost:5000"}

echo "🔄 Docker 이미지를 CRI 이미지로 변환 중..."
echo "📥 소스 이미지: ${SOURCE_IMAGE}"
echo "📤 타겟 이미지: ${REGISTRY}/${TARGET_IMAGE}"

# Docker 이미지 존재 확인
if ! docker image inspect "${SOURCE_IMAGE}" >/dev/null 2>&1; then
    echo "❌ 소스 이미지 ${SOURCE_IMAGE}를 찾을 수 없습니다."
    echo "💡 먼저 이미지를 빌드하세요: ./scripts/build.sh"
    exit 1
fi

# 로컬 registry 실행 확인 및 시작
if ! docker ps | grep -q registry; then
    echo "🏗️ 로컬 registry 시작 중..."
    docker run -d -p 5000:5000 --name registry registry:2
    sleep 3
else
    echo "✅ 로컬 registry가 이미 실행 중입니다."
fi

# 이미지 태그 및 push
echo "🏷️ 이미지 태그 중..."
docker tag "${SOURCE_IMAGE}" "${REGISTRY}/${TARGET_IMAGE}"

echo "📤 로컬 registry에 이미지 push 중..."
docker push "${REGISTRY}/${TARGET_IMAGE}"

# containerd에 이미지 import (선택사항)
if command -v ctr &> /dev/null; then
    echo "🔧 containerd에 이미지 import 중..."
    # Docker 이미지를 tar로 export
    docker save "${REGISTRY}/${TARGET_IMAGE}" > /tmp/image.tar
    
    # containerd에 import
    ctr -n k8s.io images import /tmp/image.tar
    
    # 임시 파일 정리
    rm -f /tmp/image.tar
    
    echo "✅ containerd에 이미지 import 완료"
else
    echo "⚠️ ctr 도구가 설치되지 않았습니다. containerd import를 건너뜁니다."
fi

echo ""
echo "🎉 이미지 변환 완료!"
echo ""
echo "📋 사용 방법:"
echo "1. Kubernetes 배포:"
echo "   ./scripts/deploy.sh ${REGISTRY}/${TARGET_IMAGE}"
echo ""
echo "2. 이미지 확인:"
echo "   curl -s http://localhost:5000/v2/_catalog"
echo "   curl -s http://localhost:5000/v2/${TARGET_IMAGE%:*}/tags/list"
echo ""
echo "3. registry 정리 (선택사항):"
echo "   docker stop registry && docker rm registry"
