#!/bin/bash

# 쿠버네티스 Pod의 메모리 사용량을 모니터링하는 스크립트

NAMESPACE=${NAMESPACE:-memleak-demo}
POD_LABEL=${POD_LABEL:-app=leaky}
INTERVAL=${INTERVAL:-10}
DURATION=${DURATION:-300}  # 5분

echo "🔍 쿠버네티스 메모리 모니터링 시작"
echo "📱 네임스페이스: $NAMESPACE"
echo "🎯 Pod 라벨: $POD_LABEL"
echo "⏱️  모니터링 간격: ${INTERVAL}초"
echo "⏰ 총 모니터링 시간: ${DURATION}초"
echo "---"

start_time=$(date +%s)
end_time=$((start_time + DURATION))

while [ $(date +%s) -lt $end_time ]; do
    current_time=$(date '+%H:%M:%S')
    
    # Pod 이름 가져오기
    POD_NAME=$(kubectl -n $NAMESPACE get pod -l $POD_LABEL -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -n "$POD_NAME" ]; then
        # Pod 내부에서 메모리 정보 수집
        MEMORY_INFO=$(kubectl -n $NAMESPACE exec $POD_NAME -- sh -c '
            PID=$(pgrep main)
            if [ -n "$PID" ]; then
                if [ -f "/proc/$PID/status" ]; then
                    RSS=$(awk "/VmRSS/ {print \$2}" /proc/$PID/status 2>/dev/null || echo "0")
                    VMSIZE=$(awk "/VmSize/ {print \$2}" /proc/$PID/status 2>/dev/null || echo "0")
                    echo "$RSS $VMSIZE"
                else
                    echo "0 0"
                fi
            else
                echo "0 0"
            fi
        ' 2>/dev/null)
        
        RSS=$(echo $MEMORY_INFO | awk '{print $1}')
        VMSIZE=$(echo $MEMORY_INFO | awk '{print $2}')
        
        # 메모리 사용량 출력
        if [ "$RSS" != "0" ] && [ "$VMSIZE" != "0" ]; then
            echo "[$current_time] Pod: $POD_NAME | RSS: ${RSS}KB | VMSize: ${VMSIZE}KB"
        else
            echo "[$current_time] Pod: $POD_NAME | 메모리 정보 수집 실패"
        fi
        
        # Pod 상태 확인
        POD_STATUS=$(kubectl -n $NAMESPACE get pod $POD_NAME -o jsonpath='{.status.phase}')
        RESTARTS=$(kubectl -n $NAMESPACE get pod $POD_NAME -o jsonpath='{.status.containerStatuses[0].restartCount}')
        echo "   상태: $POD_STATUS | 재시작: $RESTARTS"
        
    else
        echo "[$current_time] Pod를 찾을 수 없습니다"
    fi
    
    echo "---"
    sleep $INTERVAL
done

echo "✅ 메모리 모니터링 완료"
echo "💡 힙 프로파일 수집: curl http://localhost:6060/debug/pprof/heap > heap_profile_final.pb"