#!/bin/bash

# Memory Leak Demo - Kubernetes 배포 스크립트
# 이 스크립트는 메모리 누수 시뮬레이션을 Kubernetes에 배포합니다.

set -e

echo "☸️ Memory Leak Demo Kubernetes 배포 시작..."

# kubectl 설치 확인
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl이 설치되지 않았습니다. Kubernetes 클라이언트를 설치하세요."
    exit 1
fi

# Kubernetes 클러스터 연결 확인
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Kubernetes 클러스터에 연결할 수 없습니다. 클러스터 상태를 확인하세요."
    exit 1
fi

# 현재 컨텍스트 확인
CURRENT_CONTEXT=$(kubectl config current-context)
echo "📍 현재 Kubernetes 컨텍스트: ${CURRENT_CONTEXT}"

# 네임스페이스 생성
echo "🏗️ 네임스페이스 생성 중..."
kubectl apply -f k8s/namespace.yaml

# Prometheus 배포
echo "📊 Prometheus 배포 중..."
kubectl apply -f k8s/prometheus.yaml

# Grafana 배포
echo "📈 Grafana 배포 중..."
kubectl apply -f k8s/grafana.yaml

# 메인 애플리케이션 배포
echo "🚀 메모리 누수 시뮬레이션 애플리케이션 배포 중..."
kubectl apply -f k8s/deployment.yaml

# 서비스 배포
echo "🔌 서비스 배포 중..."
kubectl apply -f k8s/service.yaml

# Ingress 배포 (선택사항)
if [ -f "k8s/ingress.yaml" ]; then
    echo "🌐 Ingress 배포 중..."
    kubectl apply -f k8s/ingress.yaml
fi

# 배포 상태 확인
echo "⏳ 배포 상태 확인 중..."
kubectl -n memleak-demo get all

echo ""
echo "✅ 배포 완료!"
echo ""
echo "🎯 다음 단계:"
echo "1. Pod 상태 확인: kubectl -n memleak-demo get pods"
echo "2. 서비스 상태 확인: kubectl -n memleak-demo get svc"
echo "3. 로그 확인: kubectl -n memleak-demo logs -f deployment/stealth-memory-leaker"
echo "4. eBPF 도구 설정: ./scripts/ebpf-setup.sh"
echo ""
echo "🌐 접속 정보:"
echo "- 애플리케이션: http://localhost:8080 (포트포워딩 필요)"
echo "- Grafana: http://localhost:3000 (admin/admin)"
echo "- Prometheus: http://localhost:9090 (포트포워딩 필요)"
echo ""
echo "📊 포트포워딩 명령어:"
echo "kubectl -n memleak-demo port-forward svc/stealth-memory-leaker 8080:8080"
echo "kubectl -n memleak-demo port-forward svc/grafana 3000:3000"
echo "kubectl -n memleak-demo port-forward svc/prometheus 9090:9090"
