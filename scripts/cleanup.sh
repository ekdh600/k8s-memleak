#!/bin/bash

# Memory Leak Demo - 정리 스크립트
# 이 스크립트는 배포된 모든 리소스를 정리합니다.

set -e

echo "🧹 Memory Leak Demo 정리 시작..."
echo "=================================="

# 사용법 출력
usage() {
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  --all              모든 리소스 정리 (기본값)"
    echo "  --k8s-only         Kubernetes 리소스만 정리"
    echo "  --docker-only      Docker 이미지만 정리"
    echo "  --registry         로컬 registry 정리"
    echo "  --force            확인 없이 강제 정리"
    echo "  --help             이 도움말 표시"
    echo ""
    echo "예시:"
    echo "  $0                    # 모든 리소스 정리"
    echo "  $0 --k8s-only         # Kubernetes 리소스만 정리"
    echo "  $0 --docker-only      # Docker 이미지만 정리"
    echo "  $0 --force            # 확인 없이 강제 정리"
    echo ""
}

# 기본값 설정
CLEANUP_K8S=true
CLEANUP_DOCKER=true
CLEANUP_REGISTRY=false
FORCE=false

# 명령행 인수 파싱
while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            CLEANUP_K8S=true
            CLEANUP_DOCKER=true
            CLEANUP_REGISTRY=true
            shift
            ;;
        --k8s-only)
            CLEANUP_K8S=true
            CLEANUP_DOCKER=false
            CLEANUP_REGISTRY=false
            shift
            ;;
        --docker-only)
            CLEANUP_K8S=false
            CLEANUP_DOCKER=true
            CLEANUP_REGISTRY=false
            shift
            ;;
        --registry)
            CLEANUP_REGISTRY=true
            shift
            ;;
        --force)
            FORCE=true
            shift
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

echo "🔧 정리 설정:"
echo "  - Kubernetes 리소스: ${CLEANUP_K8S}"
echo "  - Docker 이미지: ${CLEANUP_DOCKER}"
echo "  - 로컬 registry: ${CLEANUP_REGISTRY}"
echo "  - 강제 정리: ${FORCE}"
echo ""

# 확인 메시지 (--force가 아닌 경우)
if [ "$FORCE" = false ]; then
    echo "⚠️ 이 작업은 다음을 정리합니다:"
    if [ "$CLEANUP_K8S" = true ]; then
        echo "  - memleak-demo 네임스페이스의 모든 리소스"
        echo "  - 배포된 Pod, Service, Deployment 등"
    fi
    if [ "$CLEANUP_DOCKER" = true ]; then
        echo "  - memory-leak-demo Docker 이미지"
        echo "  - 관련 컨테이너"
    fi
    if [ "$CLEANUP_REGISTRY" = true ]; then
        echo "  - 로컬 registry 컨테이너"
    fi
    echo ""
    read -p "계속하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ 정리가 취소되었습니다."
        exit 0
    fi
fi

# 1단계: Kubernetes 리소스 정리
if [ "$CLEANUP_K8S" = true ]; then
    echo ""
    echo "☸️ 1단계: Kubernetes 리소스 정리"
    echo "================================"
    
    # kubectl 설치 확인
    if ! command -v kubectl &> /dev/null; then
        echo "⚠️ kubectl이 설치되지 않았습니다. Kubernetes 정리를 건너뜁니다."
    else
        # Kubernetes 클러스터 연결 확인
        if kubectl cluster-info &> /dev/null; then
            echo "🔍 memleak-demo 네임스페이스 리소스 확인 중..."
            
            # 네임스페이스 존재 확인
            if kubectl get namespace memleak-demo &> /dev/null; then
                echo "🗑️ memleak-demo 네임스페이스의 모든 리소스 삭제 중..."
                
                # 개별 리소스 삭제 (더 안전함)
                echo "  - Deployment 삭제 중..."
                kubectl delete deployment -n memleak-demo --all --ignore-not-found=true
                
                echo "  - Service 삭제 중..."
                kubectl delete service -n memleak-demo --all --ignore-not-found=true
                
                echo "  - ConfigMap 삭제 중..."
                kubectl delete configmap -n memleak-demo --all --ignore-not-found=true
                
                echo "  - PersistentVolumeClaim 삭제 중..."
                kubectl delete pvc -n memleak-demo --all --ignore-not-found=true
                
                echo "  - Ingress 삭제 중..."
                kubectl delete ingress -n memleak-demo --all --ignore-not-found=true
                
                # 네임스페이스 삭제
                echo "  - 네임스페이스 삭제 중..."
                kubectl delete namespace memleak-demo --ignore-not-found=true
                
                echo "✅ Kubernetes 리소스 정리 완료"
            else
                echo "ℹ️ memleak-demo 네임스페이스가 존재하지 않습니다."
            fi
        else
            echo "⚠️ Kubernetes 클러스터에 연결할 수 없습니다. Kubernetes 정리를 건너뜁니다."
        fi
    fi
fi

# 2단계: Docker 이미지 정리
if [ "$CLEANUP_DOCKER" = true ]; then
    echo ""
    echo "🐳 2단계: Docker 이미지 정리"
    echo "============================"
    
    # Docker 데몬 실행 확인
    if ! docker info > /dev/null 2>&1; then
        echo "⚠️ Docker 데몬이 실행되지 않았습니다. Docker 정리를 건너뜁니다."
    else
        echo "🔍 memory-leak-demo 관련 이미지 확인 중..."
        
        # 관련 이미지 찾기
        IMAGES=$(docker images | grep -E "(memory-leak-demo|ekdh600/memory-leak-demo)" | awk '{print $1":"$2}' || true)
        
        if [ -n "$IMAGES" ]; then
            echo "🗑️ 다음 이미지들을 삭제 중:"
            echo "$IMAGES" | while read -r img; do
                echo "  - $img"
                docker rmi "$img" --force 2>/dev/null || true
            done
            echo "✅ Docker 이미지 정리 완료"
        else
            echo "ℹ️ memory-leak-demo 관련 이미지가 없습니다."
        fi
        
        # 관련 컨테이너 정리
        echo "🔍 memory-leak-demo 관련 컨테이너 확인 중..."
        CONTAINERS=$(docker ps -a | grep -E "(memory-leak|memleak)" | awk '{print $1}' || true)
        
        if [ -n "$CONTAINERS" ]; then
            echo "🗑️ 다음 컨테이너들을 삭제 중:"
            echo "$CONTAINERS" | while read -r container; do
                echo "  - $container"
                docker rm "$container" --force 2>/dev/null || true
            done
            echo "✅ Docker 컨테이너 정리 완료"
        else
            echo "ℹ️ memory-leak-demo 관련 컨테이너가 없습니다."
        fi
    fi
fi

# 3단계: 로컬 registry 정리
if [ "$CLEANUP_REGISTRY" = true ]; then
    echo ""
    echo "🏗️ 3단계: 로컬 registry 정리"
    echo "============================"
    
    # Docker 데몬 실행 확인
    if ! docker info > /dev/null 2>&1; then
        echo "⚠️ Docker 데몬이 실행되지 않았습니다. Registry 정리를 건너뜁니다."
    else
        echo "🔍 로컬 registry 컨테이너 확인 중..."
        
        # registry 컨테이너 찾기
        REGISTRY_CONTAINERS=$(docker ps -a | grep -E "(registry|localhost:5000)" | awk '{print $1}' || true)
        
        if [ -n "$REGISTRY_CONTAINERS" ]; then
            echo "🗑️ 다음 registry 컨테이너들을 삭제 중:"
            echo "$REGISTRY_CONTAINERS" | while read -r container; do
                echo "  - $container"
                docker stop "$container" 2>/dev/null || true
                docker rm "$container" 2>/dev/null || true
            done
            echo "✅ 로컬 registry 정리 완료"
        else
            echo "ℹ️ 로컬 registry 컨테이너가 없습니다."
        fi
    fi
fi

# 4단계: 임시 파일 정리
echo ""
echo "📁 4단계: 임시 파일 정리"
echo "========================"

# tar 파일 정리
if [ -f "/tmp/image.tar" ]; then
    echo "🗑️ 임시 tar 파일 삭제 중..."
    rm -f /tmp/image.tar
    echo "✅ 임시 파일 정리 완료"
else
    echo "ℹ️ 임시 tar 파일이 없습니다."
fi

# 5단계: 정리 결과 확인
echo ""
echo "🔍 5단계: 정리 결과 확인"
echo "========================"

# Kubernetes 상태 확인
if [ "$CLEANUP_K8S" = true ] && command -v kubectl &> /dev/null; then
    if kubectl cluster-info &> /dev/null; then
        echo "📋 Kubernetes 네임스페이스 상태:"
        kubectl get namespaces | grep memleak-demo || echo "  memleak-demo 네임스페이스가 정리되었습니다."
    fi
fi

# Docker 상태 확인
if [ "$CLEANUP_DOCKER" = true ] && docker info > /dev/null 2>&1; then
    echo "📋 Docker 이미지 상태:"
    docker images | grep -E "(memory-leak-demo|ekdh600/memory-leak-demo)" || echo "  memory-leak-demo 관련 이미지가 정리되었습니다."
fi

echo ""
echo "🎉 정리 완료!"
echo ""
echo "📋 다음 단계:"
echo "1. 새로 빌드 및 배포: ./scripts/build-and-deploy.sh"
echo "2. 단계별 실행: ./scripts/build.sh → ./scripts/convert-image.sh → ./scripts/deploy.sh"
echo "3. eBPF 도구 설정: ./scripts/ebpf-setup.sh"
echo ""
echo "💡 도움말: ./scripts/cleanup.sh --help"
