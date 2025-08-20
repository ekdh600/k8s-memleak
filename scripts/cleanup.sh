#!/bin/bash

# Memory Leak Demo - 환경 정리 스크립트
# 이 스크립트는 배포된 모든 리소스를 정리합니다.

set -e

echo "🧹 Memory Leak Demo 환경 정리 시작..."

# kubectl 설치 확인
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl이 설치되지 않았습니다. Kubernetes 클라이언트를 설치하세요."
    exit 1
fi

# 사용자 확인
echo "⚠️ 이 작업은 memleak-demo 네임스페이스의 모든 리소스를 삭제합니다."
read -p "계속하시겠습니까? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ 작업이 취소되었습니다."
    exit 1
fi

# Kubernetes 리소스 정리
echo "🗑️ Kubernetes 리소스 정리 중..."

# 1. Deployment 삭제
if kubectl get deployment -n memleak-demo stealth-memory-leaker &> /dev/null; then
    echo "   - Deployment 삭제 중..."
    kubectl delete deployment stealth-memory-leaker -n memleak-demo
fi

# 2. Service 삭제
if kubectl get svc -n memleak-demo &> /dev/null; then
    echo "   - Service 삭제 중..."
    kubectl delete svc -n memleak-demo --all
fi

# 3. Prometheus 삭제
if kubectl get deployment -n memleak-demo prometheus &> /dev/null; then
    echo "   - Prometheus 삭제 중..."
    kubectl delete deployment prometheus -n memleak-demo
fi

# 4. Grafana 삭제
if kubectl get deployment -n memleak-demo grafana &> /dev/null; then
    echo "   - Grafana 삭제 중..."
    kubectl delete deployment grafana -n memleak-demo
fi

# 5. Ingress 삭제 (존재하는 경우)
if kubectl get ingress -n memleak-demo &> /dev/null; then
    echo "   - Ingress 삭제 중..."
    kubectl delete ingress -n memleak-demo --all
fi

# 6. ConfigMap 삭제
if kubectl get configmap -n memleak-demo &> /dev/null; then
    echo "   - ConfigMap 삭제 중..."
    kubectl delete configmap -n memleak-demo --all
fi

# 7. Secret 삭제
if kubectl get secret -n memleak-demo &> /dev/null; then
    echo "   - Secret 삭제 중..."
    kubectl delete secret -n memleak-demo --all
fi

# 8. PersistentVolumeClaim 삭제
if kubectl get pvc -n memleak-demo &> /dev/null; then
    echo "   - PersistentVolumeClaim 삭제 중..."
    kubectl delete pvc -n memleak-demo --all
fi

# 9. 네임스페이스 삭제
if kubectl get namespace memleak-demo &> /dev/null; then
    echo "   - 네임스페이스 삭제 중..."
    kubectl delete namespace memleak-demo
fi

# Docker 리소스 정리 (선택사항)
echo ""
read -p "Docker 이미지와 컨테이너도 정리하시겠습니까? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🐳 Docker 리소스 정리 중..."
    
    # 컨테이너 정리
    if docker ps -a | grep -q "memory-leak-demo\|prometheus\|grafana"; then
        echo "   - Docker 컨테이너 정리 중..."
        docker stop $(docker ps -a -q --filter "name=memory-leak-demo\|prometheus\|grafana") 2>/dev/null || true
        docker rm $(docker ps -a -q --filter "name=memory-leak-demo\|prometheus\|grafana") 2>/dev/null || true
    fi
    
    # 이미지 정리
    if docker images | grep -q "memory-leak-demo"; then
        echo "   - Docker 이미지 정리 중..."
        docker rmi memory-leak-demo:latest 2>/dev/null || true
    fi
    
    # 볼륨 정리
    if docker volume ls | grep -q "memory-leak-demo\|prometheus_data\|grafana_data"; then
        echo "   - Docker 볼륨 정리 중..."
        docker volume rm $(docker volume ls -q --filter "name=memory-leak-demo\|prometheus_data\|grafana_data") 2>/dev/null || true
    fi
    
    # 네트워크 정리
    if docker network ls | grep -q "memory-leak-demo"; then
        echo "   - Docker 네트워크 정리 중..."
        docker network rm memory-leak-demo_default 2>/dev/null || true
    fi
fi

echo ""
echo "✅ 환경 정리 완료!"
echo ""
echo "🎯 다음 단계:"
echo "1. 새로 배포: ./scripts/deploy.sh"
echo "2. 이미지 재빌드: ./scripts/build.sh"
echo "3. 로컬 테스트: docker-compose up -d"
