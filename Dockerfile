# 멀티스테이지 빌드를 사용한 Go 애플리케이션 Docker 이미지
FROM golang:1.22-alpine AS builder

# 빌드 의존성 설치
RUN apk add --no-cache git ca-certificates tzdata

# 작업 디렉토리 설정
WORKDIR /app

# Go 모듈 파일 복사
COPY go.mod ./

# 의존성 다운로드
RUN go mod download

# 소스 코드 복사
COPY . .

# 애플리케이션 빌드
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# 최종 이미지
FROM alpine:latest

# 런타임 의존성 설치
RUN apk --no-cache add ca-certificates tzdata

# 비root 사용자 생성
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# 작업 디렉토리 설정
WORKDIR /app

# 빌드된 바이너리 복사
COPY --from=builder /app/main .

# 소유권 변경
RUN chown -R appuser:appgroup /app

# 비root 사용자로 실행
USER appuser

# 포트 노출
EXPOSE 6060

# 헬스체크
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:6060/debug/pprof/ || exit 1

# 애플리케이션 실행
CMD ["./main"]