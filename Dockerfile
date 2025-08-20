# 파드 메모리 누수 시뮬레이션 서비스 - GCC 기반 멀티스테이지 빌드
FROM gcc:11 AS builder

WORKDIR /app
COPY src/ .

# 모든 소스 파일을 포함하여 main_service 컴파일
RUN gcc -O2 -static -s -pthread -o main_service main_service.c fake_metrics.c \
    && gcc -O2 -static -s -pthread -o healthy_service healthy_service.c \
    && strip main_service healthy_service \
    && ls -lh *.c *.h main_service healthy_service

# 실행 이미지 (Alpine Linux - 초경량)
FROM alpine:3.18

# 필요한 도구 설치 (최소한)
RUN apk add --no-cache \
    procps \
    curl \
    && rm -rf /var/cache/apk/*

WORKDIR /app
COPY --from=builder /app/main_service .
COPY --from=builder /app/healthy_service .

# 실행 권한 설정
RUN chmod +x main_service healthy_service

# 메타데이터
LABEL maintainer="Memory Leak Demo Project"
LABEL description="Stealthy memory leak simulator with fake healthy metrics"
LABEL version="2.0.0"
LABEL features="stealth-leak,fake-metrics,ebpf-tracking"

# 헬스체크 (프로세스 존재 확인)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pgrep main_service || exit 1

# 포트 (HTTP 서버 + Prometheus 메트릭)
EXPOSE 8080 9090

# 기본 실행 (메인 서비스)
CMD ["./main_service"]