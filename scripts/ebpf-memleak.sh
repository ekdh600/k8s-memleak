#!/bin/bash

# eBPF 기반 메모리 누수 진단 스크립트
# Inspektor Gadget을 사용한 실시간 메모리 추적

set -e

NAMESPACE=${NAMESPACE:-memleak-demo}
POD_NAME=${POD_NAME:-}
DURATION=${DURATION:-300}  # 5분

echo "🔍 eBPF 기반 메모리 누수 진단 시작"
echo "📱 네임스페이스: $NAMESPACE"
echo "⏱️  추적 시간: ${DURATION}초"

# Inspektor Gadget 설치 확인
if ! kubectl get ns gadget-system 2>/dev/null; then
    echo "📦 Inspektor Gadget 설치 중..."
    kubectl apply -f https://raw.githubusercontent.com/inspektor-gadget/inspektor-gadget/main/deploy/gadget.yaml
    
    echo "⏳ Gadget 시스템 시작 대기 중..."
    kubectl wait --for=condition=ready pod -l app=gadget -n gadget-system --timeout=120s
fi

# Pod 이름이 지정되지 않은 경우 자동 감지
if [ -z "$POD_NAME" ]; then
    POD_NAME=$(kubectl get pod -n $NAMESPACE -l app=leaky -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -z "$POD_NAME" ]; then
        echo "❌ 대상 Pod를 찾을 수 없습니다. Pod 이름을 직접 지정하거나 배포를 확인하세요."
        exit 1
    fi
fi

echo "🎯 대상 Pod: $POD_NAME"

# 메모리 누수 추적 시작
echo "🚀 memleak 추적 시작 (PID 기반)..."
kubectl trace run $NAMESPACE/$POD_NAME --tool memleak --duration $DURATION &
TRACE_PID=$!

echo "📊 추적 중... (PID: $TRACE_PID)"
echo "💡 추적 결과는 별도 터미널에서 확인하세요:"
echo "   kubectl trace status $TRACE_PID"

# 추적 완료 대기
sleep $DURATION

echo "✅ memleak 추적 완료"

# 추가 진단 도구들
echo "🔧 추가 진단 도구 실행..."

# 1. pmap으로 메모리 맵 확인
echo "📋 pmap으로 메모리 맵 확인 중..."
kubectl exec -n $NAMESPACE $POD_NAME -- sh -c '
    PID=$(pgrep main)
    if [ -n "$PID" ]; then
        echo "메인 프로세스 PID: $PID"
        pmap -x $PID | sort -k3 -n | tail -10
    else
        echo "메인 프로세스를 찾을 수 없습니다"
    fi
'

# 2. 프로세스 상태 확인
echo "📊 프로세스 상태 확인 중..."
kubectl exec -n $NAMESPACE $POD_NAME -- sh -c '
    ps aux | grep main
'

# 3. 메모리 통계 확인
echo "📈 메모리 통계 확인 중..."
kubectl exec -n $NAMESPACE $POD_NAME -- sh -c '
    cat /proc/meminfo | grep -E "(MemTotal|MemFree|MemAvailable|Buffers|Cached)"
'

echo "🎯 진단 완료!"
echo "💡 다음 단계:"
echo "   1. kubectl trace status $TRACE_PID 로 추적 결과 확인"
echo "   2. pprof로 힙 프로파일 분석"
echo "   3. 코드에서 메모리 해제 누약 확인"