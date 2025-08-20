#!/bin/bash

# Docker 이미지를 직접 containerd에 import하는 스크립트
# 이 방법은 로컬 registry 없이도 로컬 이미지를 Kubernetes에서 사용할 수 있게 합니다.

set -e

# 기본값 설정
SOURCE_IMAGE=${1:-"memory-leak-demo:latest"}
TARGET_IMAGE=${2:-"memory-leak-demo:latest"}

# 이미지 이름 검증 (공백 제거)
SOURCE_IMAGE=$(echo "$SOURCE_IMAGE" | tr -s ' ' '-')
TARGET_IMAGE=$(echo "$TARGET_IMAGE" | tr -s ' ' '-')

echo "🔧 Docker 이미지를 containerd에 직접 import 중..."
echo "📥 소스 이미지: ${SOURCE_IMAGE}"
echo "📤 타겟 이미지: ${TARGET_IMAGE}"

# Docker 이미지 존재 확인
if ! docker image inspect "${SOURCE_IMAGE}" >/dev/null 2>&1; then
    echo "❌ 소스 이미지 ${SOURCE_IMAGE}를 찾을 수 없습니다."
    echo "💡 먼저 이미지를 빌드하세요: ./scripts/build.sh"
    exit 1
fi

# ctr 도구 확인
if ! command -v ctr &> /dev/null; then
    echo "❌ ctr 도구가 설치되지 않았습니다."
    echo "💡 containerd-tools를 설치하세요:"
    echo "   Ubuntu/Debian: apt install containerd-tools"
    echo "   CentOS/RHEL: yum install containerd-tools"
    exit 1
fi

# containerd 서비스 상태 확인
if ! systemctl is-active --quiet containerd; then
    echo "⚠️ containerd 서비스가 실행되지 않았습니다."
    echo "💡 containerd 서비스를 시작하세요: systemctl start containerd"
fi

echo "🔄 이미지 변환 중..."

# Docker 이미지를 tar로 export
echo "📦 Docker 이미지를 tar로 export 중..."
docker save "${SOURCE_IMAGE}" > /tmp/image.tar

# containerd에 import
echo "📥 containerd에 이미지 import 중..."
ctr -n k8s.io images import /tmp/image.tar

# 임시 파일 정리
rm -f /tmp/image.tar

# 이미지 확인
echo "✅ 이미지 import 완료!"
echo "📋 containerd 이미지 목록:"
ctr -n k8s.io images ls | grep "${TARGET_IMAGE%:*}" || echo "⚠️ 이미지를 찾을 수 없습니다."

echo ""
echo "🎯 다음 단계:"
echo "1. Kubernetes 배포:"
echo "   ./scripts/deploy.sh ${TARGET_IMAGE}"
echo ""
echo "2. 이미지 확인:"
echo "   crictl images | grep ${TARGET_IMAGE%:*}"
echo ""
echo "⚠️ 중요: 이 방법은 이미지를 containerd에 직접 import하므로"
echo "   로컬 registry가 필요하지 않습니다!"
