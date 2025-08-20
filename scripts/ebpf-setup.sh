#!/bin/bash

# Memory Leak Demo - eBPF 도구 설정 스크립트
# 이 스크립트는 eBPF 기반 메모리 누수 추적 도구를 설정합니다.

set -e

echo "🔍 Memory Leak Demo eBPF 도구 설정 시작..."

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

echo "🚀 eBPF 도구 설정 중..."

# 1. Inspektor Gadget 설치
echo "📦 Inspektor Gadget 설치 중..."
if [ -f "k8s/inspektor-gadget.yaml" ]; then
    kubectl apply -f k8s/inspektor-gadget.yaml
    echo "✅ Inspektor Gadget 설치 완료"
else
    echo "⚠️ Inspektor Gadget YAML 파일을 찾을 수 없습니다. 수동으로 설치하세요."
    echo "   kubectl gadget install"
fi

# 2. BCC 도구 설치 (노드에서 직접 실행)
echo "🔧 BCC 도구 설치 정보..."
echo "📋 BCC 도구는 노드에서 직접 설치해야 합니다:"
echo ""
echo "Ubuntu/Debian:"
echo "  sudo apt-get install -y bpfcc-tools"
echo ""
echo "RHEL/CentOS:"
echo "  sudo yum install -y bcc-tools"
echo ""
echo "또는 소스에서 빌드:"
echo "  git clone https://github.com/iovisor/bcc.git"
echo "  cd bcc && mkdir build && cd build"
echo "  cmake .. && make && sudo make install"
echo ""

# 3. bpftrace 설치 정보
echo "📋 bpftrace 설치 정보:"
echo ""
echo "Ubuntu/Debian:"
echo "  sudo apt-get install -y bpftrace"
echo ""
echo "RHEL/CentOS:"
echo "  sudo yum install -y bpftrace"
echo ""

# 4. 메모리 누수 추적 방법 안내
echo "🎯 메모리 누수 추적 방법:"
echo ""
echo "1. Inspektor Gadget 사용 (권장):"
echo "   kubectl gadget memleak -n memleak-demo -p <pod-name>"
echo ""
echo "2. BCC memleak 사용 (노드에서):"
echo "   sudo /usr/share/bcc/tools/memleak -p <pid>"
echo ""
echo "3. bpftrace 사용 (노드에서):"
echo "   sudo bpftrace -e 'tracepoint:syscalls:sys_enter_mmap { printf(\"PID %d: mmap size=%d\\n\", pid, args->len); }'"
echo ""

# 5. Pod 이름 확인
echo "🔍 현재 실행 중인 Pod 확인:"
kubectl -n memleak-demo get pods

echo ""
echo "✅ eBPF 도구 설정 완료!"
echo ""
echo "🎯 다음 단계:"
echo "1. Pod 이름 확인: kubectl -n memleak-demo get pods"
echo "2. 메모리 누수 추적: kubectl gadget memleak -n memleak-demo -p <pod-name>"
echo "3. 로그 모니터링: kubectl -n memleak-demo logs -f deployment/stealth-memory-leaker"
echo ""
echo "💡 팁: 메모리 누수는 8초마다 1MB씩 발생하며, 최대 2GB까지 누적됩니다."
echo "   표준 모니터링에서는 '정상'으로 보이지만, eBPF로 실제 누수를 확인할 수 있습니다."
