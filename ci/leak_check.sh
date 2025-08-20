#!/bin/bash

# 메모리 누수 감지 스크립트
# 사용법: ./leak_check.sh [BIN] [DURATION] [THRESHOLD_KB]

set -e

BIN=${BIN:-./app}
DURATION=${DURATION:-60}
THRESHOLD_KB=${THRESHOLD_KB:-20000}  # 기간 동안 RSS 증가 허용 임계값

echo "🔍 메모리 누수 감지 시작"
echo "📱 실행 파일: $BIN"
echo "⏱️  모니터링 시간: ${DURATION}초"
echo "🚨 임계값: ${THRESHOLD_KB}KB"

# 실행 파일 존재 확인
if [ ! -f "$BIN" ]; then
    echo "❌ 실행 파일을 찾을 수 없습니다: $BIN"
    exit 1
fi

# 애플리케이션 백그라운드 실행
echo "🚀 애플리케이션 시작 중..."
$BIN >/dev/null 2>&1 &
PID=$!

# 프로세스 시작 대기
sleep 2

# 프로세스 상태 확인
if ! kill -0 $PID 2>/dev/null; then
    echo "❌ 애플리케이션 시작 실패"
    exit 1
fi

echo "✅ 애플리케이션 시작됨 (PID: $PID)"

# RSS 메모리 사용량 측정 함수
rss_kb() {
    if [ -f "/proc/$1/status" ]; then
        awk '/VmRSS/ {print $2}' "/proc/$1/status" 2>/dev/null || echo 0
    else
        # macOS용 ps 명령어
        ps -o rss= -p "$1" 2>/dev/null | awk '{print $1}' || echo 0
    fi
}

# 초기 메모리 사용량 측정
BASE=$(rss_kb $PID)
echo "📊 초기 RSS: ${BASE}KB"

# 메모리 사용량 모니터링
echo "📈 메모리 사용량 모니터링 중..."
for i in $(seq 1 $DURATION); do
    CURRENT=$(rss_kb $PID)
    DELTA=$((CURRENT - BASE))
    echo "   ${i}s: ${CURRENT}KB (변화: ${DELTA}KB)"
    sleep 1
done

# 최종 메모리 사용량 측정
END=$(rss_kb $PID)
echo "📊 최종 RSS: ${END}KB"

# 메모리 증가량 계산
DELTA=$((END - BASE))
echo "📊 RSS 증가량: ${DELTA}KB"

# 프로세스 종료
echo "🛑 애플리케이션 종료 중..."
kill $PID 2>/dev/null || true
wait $PID 2>/dev/null || true

# 결과 판정
if [ "$DELTA" -gt "$THRESHOLD_KB" ]; then
    echo "🚨 메모리 누수 의심! 증가량(${DELTA}KB)이 임계값(${THRESHOLD_KB}KB)을 초과했습니다."
    echo "💡 권장사항:"
    echo "   - pprof로 힙 프로파일 분석"
    echo "   - eBPF memleak 도구 사용"
    echo "   - 코드에서 메모리 해제 누락 확인"
    exit 1
else
    echo "✅ 메모리 누수 없음 - 증가량(${DELTA}KB)이 임계값(${THRESHOLD_KB}KB) 이내입니다."
    exit 0
fi