#!/bin/bash

# 📊 pprof 프로파일 수집 스크립트
# 메모리 누수 분석을 위한 다양한 프로파일 수집 도구

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
PROFILE_DIR=${PROFILE_DIR:-./profiles}
PORT=${PORT:-6060}
DURATION=${DURATION:-300}  # 5분

# 사용법 출력
usage() {
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  -n, --namespace NAMESPACE  쿠버네티스 네임스페이스 (기본값: memleak-demo)"
    echo "  -l, --label POD_LABEL      Pod 라벨 선택자 (기본값: app=leaky)"
    echo "  -d, --profile-dir DIR     프로파일 저장 디렉토리 (기본값: ./profiles)"
    echo "  -p, --port PORT           pprof 서버 포트 (기본값: 6060)"
    echo "  -t, --duration SECONDS    프로파일 수집 간격 (기본값: 300초)"
    echo "  -h, --help                이 도움말 출력"
    echo ""
    echo "예시:"
    echo "  $0 -n memleak-demo -d ./my-profiles -t 600"
    echo "  $0 --namespace production --duration 1800"
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
        -d|--profile-dir)
            PROFILE_DIR="$2"
            shift 2
            ;;
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -t|--duration)
            DURATION="$2"
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

echo -e "${BLUE}📊 pprof 프로파일 수집 시작${NC}"
echo "📱 네임스페이스: $NAMESPACE"
echo "🎯 Pod 라벨: $POD_LABEL"
echo "📁 프로파일 디렉토리: $PROFILE_DIR"
echo "🔌 포트: $PORT"
echo "⏱️  수집 간격: ${DURATION}초"
echo ""

# 프로파일 디렉토리 생성
mkdir -p "$PROFILE_DIR"

# Pod 이름 가져오기
pod_name=$(kubectl -n "$NAMESPACE" get pod -l "$POD_LABEL" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -z "$pod_name" ]; then
    echo -e "${RED}❌ Pod를 찾을 수 없습니다.${NC}"
    exit 1
fi

echo "🎯 대상 Pod: $pod_name"

# 포트포워딩 시작
echo -e "${YELLOW}🔌 포트포워딩 시작 중...${NC}"
kubectl -n "$NAMESPACE" port-forward pod/"$pod_name" "$PORT:$PORT" >/dev/null 2>&1 &
portforward_pid=$!

# 포트포워딩 대기
sleep 5

# 포트포워딩 상태 확인
if ! curl -s "http://localhost:$PORT/debug/pprof/" >/dev/null 2>&1; then
    echo -e "${RED}❌ 포트포워딩 실패 또는 pprof 서버에 접근할 수 없습니다.${NC}"
    kill $portforward_pid 2>/dev/null || true
    exit 1
fi

echo -e "${GREEN}✅ 포트포워딩 성공${NC}"
echo ""

# 프로파일 수집 함수
collect_profile() {
    local profile_type="$1"
    local filename="$2"
    local url="http://localhost:$PORT/debug/pprof/$profile_type"
    
    echo "📥 $profile_type 프로파일 수집 중..."
    
    if curl -s "$url" > "$filename" 2>/dev/null; then
        local size=$(wc -c < "$filename")
        echo -e "   ✅ 수집 완료: $(format_bytes $size)"
        return 0
    else
        echo -e "   ❌ 수집 실패"
        return 1
    fi
}

# 바이트를 사람이 읽기 쉬운 형태로 변환
format_bytes() {
    local bytes="$1"
    
    if [ "$bytes" -gt 1073741824 ]; then
        echo "$((bytes / 1073741824))GB"
    elif [ "$bytes" -gt 1048576 ]; then
        echo "$((bytes / 1048576))MB"
    elif [ "$bytes" -gt 1024 ]; then
        echo "$((bytes / 1024))KB"
    else
        echo "${bytes}B"
    fi
}

# 초기 프로파일 수집
echo -e "${YELLOW}📊 초기 프로파일 수집 중...${NC}"
timestamp=$(date +%Y%m%d_%H%M%S)

# 힙 프로파일
collect_profile "heap" "$PROFILE_DIR/heap_initial_${timestamp}.pb"

# 고루틴 프로파일
collect_profile "goroutine" "$PROFILE_DIR/goroutine_initial_${timestamp}.pb"

# CPU 프로파일 (30초 동안)
echo "📥 CPU 프로파일 수집 중 (30초)..."
curl -s "http://localhost:$PORT/debug/pprof/profile?seconds=30" > "$PROFILE_DIR/cpu_initial_${timestamp}.pb" &
cpu_pid=$!

# 블록 프로파일
collect_profile "block" "$PROFILE_DIR/block_initial_${timestamp}.pb"

# 뮤텍스 프로파일
collect_profile "mutex" "$PROFILE_DIR/mutex_initial_${timestamp}.pb"

# CPU 프로파일 완료 대기
wait $cpu_pid
if [ -f "$PROFILE_DIR/cpu_initial_${timestamp}.pb" ]; then
    size=$(wc -c < "$PROFILE_DIR/cpu_initial_${timestamp}.pb")
    echo -e "   ✅ CPU 프로파일 수집 완료: $(format_bytes $size)"
fi

echo ""
echo -e "${GREEN}✅ 초기 프로파일 수집 완료!${NC}"
echo ""

# 대기 시간 안내
echo -e "${YELLOW}⏳ ${DURATION}초 동안 메모리 누수 시뮬레이션 진행 중...${NC}"
echo "💡 이 시간 동안 애플리케이션에서 메모리 누수가 발생합니다."
echo ""

# 진행률 표시
for i in $(seq 1 $DURATION); do
    if [ $((i % 60)) -eq 0 ]; then
        echo "⏰ 진행률: $((i / 60))분 / $((DURATION / 60))분"
    fi
    sleep 1
done

echo ""
echo -e "${YELLOW}📊 최종 프로파일 수집 중...${NC}"
final_timestamp=$(date +%Y%m%d_%H%M%S)

# 최종 프로파일 수집
collect_profile "heap" "$PROFILE_DIR/heap_final_${final_timestamp}.pb"
collect_profile "goroutine" "$PROFILE_DIR/goroutine_final_${final_timestamp}.pb"
collect_profile "block" "$PROFILE_DIR/block_final_${final_timestamp}.pb"
collect_profile "mutex" "$PROFILE_DIR/mutex_final_${final_timestamp}.pb"

# CPU 프로파일 (30초 동안)
echo "📥 CPU 프로파일 수집 중 (30초)..."
curl -s "http://localhost:$PORT/debug/pprof/profile?seconds=30" > "$PROFILE_DIR/cpu_final_${final_timestamp}.pb" &
cpu_pid=$!

# CPU 프로파일 완료 대기
wait $cpu_pid
if [ -f "$PROFILE_DIR/cpu_final_${final_timestamp}.pb" ]; then
    size=$(wc -c < "$PROFILE_DIR/cpu_final_${final_timestamp}.pb")
    echo -e "   ✅ CPU 프로파일 수집 완료: $(format_bytes $size)"
fi

echo ""
echo -e "${GREEN}✅ 최종 프로파일 수집 완료!${NC}"

# 포트포워딩 종료
kill $portforward_pid 2>/dev/null || true

# 프로파일 비교 분석
echo ""
echo -e "${BLUE}📈 프로파일 비교 분석${NC}"
echo ""

# 힙 프로파일 크기 비교
initial_heap=$(find "$PROFILE_DIR" -name "heap_initial_*.pb" | head -1)
final_heap=$(find "$PROFILE_DIR" -name "heap_final_*.pb" | head -1)

if [ -n "$initial_heap" ] && [ -n "$final_heap" ]; then
    initial_size=$(wc -c < "$initial_heap")
    final_size=$(wc -c < "$final_heap")
    size_diff=$((final_size - initial_size))
    size_diff_percent=$((size_diff * 100 / initial_size))
    
    echo "📊 힙 프로파일 크기 변화:"
    echo "   초기: $(format_bytes $initial_size)"
    echo "   최종: $(format_bytes $final_size)"
    echo "   변화: ${size_diff:+$size_diff_percent% 증가}"
    
    if [ "$size_diff" -gt 0 ]; then
        echo -e "   🚨 ${RED}메모리 누수 의심!${NC}"
    else
        echo -e "   ✅ ${GREEN}메모리 누수 없음${NC}"
    fi
fi

echo ""
echo -e "${GREEN}🎉 프로파일 수집 완료!${NC}"
echo "📁 저장 위치: $PROFILE_DIR"
echo ""
echo -e "${BLUE}💡 다음 단계:${NC}"
echo "  1. 프로파일 분석: go tool pprof -top <프로파일파일>"
echo "  2. 웹 인터페이스: go tool pprof -http=:8080 <프로파일파일>"
echo "  3. 프로파일 비교: go tool pprof -base <초기프로파일> <최종프로파일>"
echo "  4. 메모리 누수 패턴 분석"
echo "  5. 근본 원인 추적"