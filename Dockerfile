# C 메모리 누수 시뮬레이터 - 최적화된 멀티스테이지 빌드
FROM gcc:11 as builder

WORKDIR /app
COPY src/memory_leak.c .

# 최적화된 정적 컴파일 (최소 크기, 최대 성능)
RUN gcc -O2 -static -s -o memory_leak memory_leak.c \
    && strip memory_leak \
    && ls -lh memory_leak

# 실행 이미지 (Alpine Linux - 초경량)
FROM alpine:3.18

# 필요한 도구 설치 (최소한)
RUN apk add --no-cache \
    procps \
    && rm -rf /var/cache/apk/*

WORKDIR /app
COPY --from=builder /app/memory_leak .

# 메타데이터
LABEL maintainer="Memory Leak Demo Project"
LABEL description="C-based memory leak simulator for eBPF tracking"
LABEL version="2.0.0"

# 헬스체크 (프로세스 존재 확인)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pgrep memory_leak || exit 1

# 포트 (필요시 HTTP 서버 추가 가능)
EXPOSE 8080

# 실행
CMD ["./memory_leak"]