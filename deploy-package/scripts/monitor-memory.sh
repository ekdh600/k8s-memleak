#!/bin/bash

# 🔍 메모리 누수 모니터링 스크립트
# 다른 클러스터에서 사용할 수 있는 범용 메모리 모니터링 도구

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 설정 변수
NAMESPACE=${NAMESPACE:-memleak-demo}
POD_LABEL=${POD_LABEL:-app=leaky}
INTERVAL=${INTERVAL:-10}
DURATION=${DURATION:-0}  # 0이면 무한 실행
LOG_FILE=${LOG_FILE:-memory-monitor.log}

# 사용법 출력
usage() {
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  -n, --namespace NAMESPACE  쿠버네티스 네임스페이스 (기본값: memleak-demo)"
    echo "  -l, --label POD_LABEL      Pod 라벨 선택자 (기본값: app=leaky)"
    echo "  -i, --interval SECONDS     모니터링 간격 (기본값: 10초)"
    echo "  -d, --duration SECONDS     총 모니터링 시간 (기본값: 무한)"
    echo "  -f, --log-file FILE        로그 파일 경로 (기본값: memory-monitor.log)"
    echo "  -h, --help                 이 도움말 출력"
    echo ""
    echo "예시:"
    echo "  $0 -n memleak-demo -i 5 -d 300"
    echo "  $0 --namespace production --interval 30"
}

# 명령행 인수 파싱
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -l|--label)
            POD_LABEL="$2"
            shift 2
            ;;
        -i|--interval)
            INTERVAL="$2"
            shift 2
            ;;
        -d|--duration)
            DURATION="$2"
            shift 2
            ;;
        -f|--log-file)
            LOG_FILE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "알 수 없는 옵션: $1"
            usage
            exit 1
            ;;
    esac
done

echo -e "${BLUE}🔍 메모리 누수 모니터링 시작${NC}"
echo "📱 네임스페이스: $NAMESPACE"
echo "🎯 Pod 라벨: $POD_LABEL"
echo "⏱️  모니터링 간격: ${INTERVAL}초"
echo "⏰ 총 모니터링 시간: ${DURATION:-무한}초"
echo "📝 로그 파일: $LOG_FILE"
echo ""

# 시작 시간 기록
start_time=$(date +%s)
end_time=$([ "$DURATION" -gt 0 ] && echo $((start_time + DURATION)) || echo 0)

# 로그 파일 초기화
echo "=== 메모리 모니터링 시작: $(date) ===" > "$LOG_FILE"
echo "네임스페이스: $NAMESPACE" >> "$LOG_FILE"
echo "Pod 라벨: $POD_LABEL" >> "$LOG_FILE"
echo "모니터링 간격: ${INTERVAL}초" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# 메모리 사용량 추출 함수
get_memory_usage() {
    local pod_name="$1"
    
    # Pod 내부에서 메모리 정보 수집
    local memory_info=$(kubectl -n "$NAMESPACE" exec "$pod_name" -- sh -c '
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
    
    echo "$memory_info"
}

# Pod 상태 정보 추출 함수
get_pod_status() {
    local pod_name="$1"
    
    # Pod 상태 정보
    local status=$(kubectl -n "$NAMESPACE" get pod "$pod_name" -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
    local restarts=$(kubectl -n "$NAMESPACE" get pod "$pod_name" -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null || echo "0")
    local ready=$(kubectl -n "$NAMESPACE" get pod "$pod_name" -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null || echo "false")
    
    echo "$status $restarts $ready"
}

# 메모리 변화량 계산 함수
calculate_memory_change() {
    local current_rss="$1"
    local current_vmsize="$2"
    local initial_rss="$3"
    local initial_vmsize="$4"
    
    local rss_change=$((current_rss - initial_rss))
    local vmsize_change=$((current_vmsize - initial_vmsize))
    
    echo "$rss_change $vmsize_change"
}

# 메모리 사용량을 사람이 읽기 쉬운 형태로 변환
format_memory() {
    local bytes="$1"
    
    if [ "$bytes" -gt 1048576 ]; then
        echo "$((bytes / 1048576))MB"
    elif [ "$bytes" -gt 1024 ]; then
        echo "$((bytes / 1024))KB"
    else
        echo "${bytes}B"
    fi
}

# 메인 모니터링 루프
echo "📊 메모리 사용량 모니터링 중..."
echo "💡 Ctrl+C로 중지하거나 지정된 시간까지 실행됩니다."
echo ""

# 초기 메모리 사용량 측정
initial_pod_name=""
initial_rss=0
initial_vmsize=0

# 초기 Pod 찾기
for i in {1..30}; do
    initial_pod_name=$(kubectl -n "$NAMESPACE" get pod -l "$POD_LABEL" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -n "$initial_pod_name" ]; then
        initial_memory=$(get_memory_usage "$initial_pod_name")
        initial_rss=$(echo "$initial_memory" | awk '{print $1}')
        initial_vmsize=$(echo "$initial_memory" | awk '{print $2}')
        
        if [ "$initial_rss" -gt 0 ] && [ "$initial_vmsize" -gt 0 ]; then
            break
        fi
    fi
    
    echo "Pod 대기 중... ($i/30)"
    sleep 2
done

if [ -z "$initial_pod_name" ] || [ "$initial_rss" -eq 0 ]; then
    echo -e "${RED}❌ Pod를 찾을 수 없거나 메모리 정보를 가져올 수 없습니다.${NC}"
    exit 1
fi

echo "🎯 초기 Pod: $initial_pod_name"
echo "📊 초기 메모리: RSS $(format_memory $((initial_rss * 1024))), VMSize $(format_memory $((initial_vmsize * 1024)))"
echo ""

# 모니터링 카운터
counter=0

while true; do
    current_time=$(date +%s)
    
    # 종료 시간 체크
    if [ "$DURATION" -gt 0 ] && [ "$current_time" -ge "$end_time" ]; then
        echo "⏰ 지정된 모니터링 시간이 완료되었습니다."
        break
    fi
    
    counter=$((counter + 1))
    
    # Pod 이름 가져오기 (재시작으로 인한 변경 고려)
    pod_name=$(kubectl -n "$NAMESPACE" get pod -l "$POD_LABEL" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -n "$pod_name" ]; then
        # 메모리 정보 수집
        memory_info=$(get_memory_usage "$pod_name")
        current_rss=$(echo "$memory_info" | awk '{print $1}')
        current_vmsize=$(echo "$memory_info" | awk '{print $2}')
        
        # Pod 상태 정보
        pod_status=$(get_pod_status "$pod_name")
        status=$(echo "$pod_status" | awk '{print $1}')
        restarts=$(echo "$pod_status" | awk '{print $2}')
        ready=$(echo "$pod_status" | awk '{print $3}')
        
        # 메모리 변화량 계산
        if [ "$current_rss" -gt 0 ] && [ "$current_vmsize" -gt 0 ]; then
            memory_change=$(calculate_memory_change "$current_rss" "$current_vmsize" "$initial_rss" "$initial_vmsize")
            rss_change=$(echo "$memory_change" | awk '{print $1}')
            vmsize_change=$(echo "$memory_change" | awk '{print $2}')
            
            # 변화량 표시
            rss_change_str=""
            vmsize_change_str=""
            
            if [ "$rss_change" -gt 0 ]; then
                rss_change_str=" (+$(format_memory $((rss_change * 1024))))"
            elif [ "$rss_change" -lt 0 ]; then
                rss_change_str=" (-$(format_memory $(((-rss_change) * 1024))))"
            fi
            
            if [ "$vmsize_change" -gt 0 ]; then
                vmsize_change_str=" (+$(format_memory $((vmsize_change * 1024))))"
            elif [ "$vmsize_change" -lt 0 ]; then
                vmsize_change_str=" (-$(format_memory $(((-vmsize_change) * 1024))))"
            fi
            
            # 상태 표시
            status_color=$GREEN
            if [ "$status" != "Running" ]; then
                status_color=$RED
            fi
            
            ready_color=$GREEN
            if [ "$ready" != "true" ]; then
                ready_color=$RED
            fi
            
            # 출력
            echo -e "[$(date '+%H:%M:%S')] #${counter} Pod: $pod_name"
            echo -e "   📊 메모리: RSS $(format_memory $((current_rss * 1024)))${rss_change_str}, VMSize $(format_memory $((current_vmsize * 1024)))${vmsize_change_str}"
            echo -e "   🏃 상태: ${status_color}${status}${NC}, 재시작: ${YELLOW}${restarts}${NC}, 준비: ${ready_color}${ready}${NC}"
            
            # 로그 파일에 기록
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] #${counter} Pod: $pod_name, RSS: ${current_rss}KB, VMSize: ${current_vmsize}KB, RSS변화: ${rss_change}KB, VMSize변화: ${vmsize_change}KB, 상태: ${status}, 재시작: ${restarts}" >> "$LOG_FILE"
            
        else
            echo -e "[$(date '+%H:%M:%S')] #${counter} Pod: $pod_name | 메모리 정보 수집 실패"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] #${counter} Pod: $pod_name, 메모리 정보 수집 실패" >> "$LOG_FILE"
        fi
        
    else
        echo -e "[$(date '+%H:%M:%S')] #${counter} Pod를 찾을 수 없습니다"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] #${counter} Pod를 찾을 수 없음" >> "$LOG_FILE"
    fi
    
    echo "---"
    
    # 다음 모니터링까지 대기
    sleep $INTERVAL
done

# 모니터링 완료 요약
echo ""
echo -e "${GREEN}✅ 메모리 모니터링 완료!${NC}"
echo "📝 로그 파일: $LOG_FILE"
echo "📊 총 모니터링 횟수: $counter"
echo ""
echo -e "${BLUE}💡 다음 단계:${NC}"
echo "  1. 로그 파일 분석: cat $LOG_FILE"
echo "  2. pprof 힙 프로파일 수집"
echo "  3. eBPF 도구로 상세 분석"
echo "  4. Prometheus + Grafana 대시보드 구축"