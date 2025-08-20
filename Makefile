# 은밀한 메모리 누수 시뮬레이션 서비스 - Makefile
.PHONY: help build run clean docker-build docker-run deploy clean-all

# 기본값
IMAGE_NAME ?= stealth-memory-leaker
IMAGE_TAG ?= latest
NAMESPACE ?= memleak-demo

help: ## 도움말 표시
	@echo "🔬 은밀한 메모리 누수 시뮬레이션 서비스"
	@echo "======================================"
	@echo ""
	@echo "🎯 목표: 표준 모니터링에서는 '정상', 실제로는 메모리 누수"
	@echo "📊 특징:"
	@echo "  - HTTP 서버로 헬스체크 제공 (포트 8080)"
	@echo "  - Prometheus 메트릭 서버 (포트 9090)"
	@echo "  - 모든 메트릭에서 '정상' 표시"
	@echo "  - 백그라운드에서 은밀한 메모리 누수 (8초마다 1MB)"
	@echo "  - eBPF로만 진짜 문제 확인 가능"
	@echo ""
	@echo "사용법:"
	@echo "  make build          - 로컬에서 C 프로그램 빌드"
	@echo "  make run            - 로컬에서 메인 서비스 실행"
	@echo "  make docker-build   - Docker 이미지 빌드"
	@make -s print-targets

print-targets:
	@echo ""
	@echo "추가 명령어:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## C 프로그램 빌드
	@echo "🔨 C 프로그램 빌드 중..."
	@mkdir -p bin
	gcc -O2 -pthread -o bin/main_service src/main_service.c
	gcc -O2 -pthread -o bin/healthy_service src/healthy_service.c
	gcc -O2 -pthread -o bin/fake_metrics src/fake_metrics.c
	gcc -O2 -pthread -o bin/memory_leak src/memory_leak.c
	@echo "✅ 빌드 완료:"
	@ls -lh bin/
	@echo ""
	@echo "📋 실행 가능한 서비스들:"
	@echo "  - main_service: 통합 서비스 (HTTP + 메트릭 + 메모리 누수)"
	@echo "  - healthy_service: HTTP 헬스체크 서비스"
	@echo "  - fake_metrics: Prometheus 메트릭 서버"
	@echo "  - memory_leak: 순수 메모리 누수 시뮬레이터"

run: build ## 로컬에서 메인 서비스 실행
	@echo "🚀 은밀한 메모리 누수 시뮬레이션 시작..."
	@echo "📊 서비스 엔드포인트:"
	@echo "  - HTTP 서버: http://localhost:8080"
	@echo "  - 메트릭 서버: http://localhost:9090/metrics"
	@echo "  - 헬스체크: http://localhost:8080/health"
	@echo ""
	@echo "🔍 eBPF로 진짜 문제 확인:"
	@echo "  kubectl gadget memleak -p <pid>"
	@echo ""
	@echo "📝 종료하려면 Ctrl+C"
	@echo "---"
	./bin/main_service

run-healthy: build ## 로컬에서 헬스체크 서비스만 실행
	@echo "💚 헬스체크 서비스 실행 중..."
	@echo "📊 엔드포인트: http://localhost:8080"
	@echo "---"
	./bin/healthy_service

run-metrics: build ## 로컬에서 메트릭 서버만 실행
	@echo "📊 Prometheus 메트릭 서버 실행 중..."
	@echo "📊 엔드포인트: http://localhost:9090/metrics"
	@echo "---"
	./bin/fake_metrics

run-leak: build ## 로컬에서 메모리 누수만 실행
	@echo "💧 메모리 누수 시뮬레이터 실행 중..."
	@echo "🔍 eBPF로 추적 가능"
	@echo "---"
	./bin/memory_leak

docker-build: ## Docker 이미지 빌드
	@echo "🐳 Docker 이미지 빌드 중..."
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .
	@echo "✅ 이미지 빌드 완료: $(IMAGE_NAME):$(IMAGE_TAG)"
	@docker images $(IMAGE_NAME):$(IMAGE_TAG)

docker-run: docker-build ## Docker 컨테이너 실행
	@echo "🚀 Docker 컨테이너 실행 중..."
	@echo "📊 서비스 엔드포인트:"
	@echo "  - HTTP 서버: http://localhost:8080"
	@echo "  - 메트릭 서버: http://localhost:9090/metrics"
	@echo "---"
	docker run --rm -it -p 8080:8080 -p 9090:9090 $(IMAGE_NAME):$(IMAGE_TAG)

deploy: ## 쿠버네티스에 배포
	@echo "☸️ 쿠버네티스에 배포 중..."
	@echo "📋 네임스페이스 생성..."
	kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	@echo "📦 배포 매니페스트 적용..."
	kubectl apply -f k8s/
	@echo "⏳ 배포 상태 확인 중..."
	kubectl -n $(NAMESPACE) rollout status deployment/stealth-memory-leaker --timeout=120s
	@echo "✅ 배포 완료!"
	@echo ""
	@echo "📊 서비스 상태:"
	kubectl -n $(NAMESPACE) get all
	@echo ""
	@echo "🔍 eBPF 트래킹 준비:"
	@echo "  make install-ebpf"
	@echo "  make track-memory"

clean: ## 빌드 파일 정리
	@echo "🧹 빌드 파일 정리 중..."
	rm -rf bin/
	@echo "✅ 정리 완료"

clean-all: clean ## 모든 생성 파일 정리
	@echo "🧹 모든 생성 파일 정리 중..."
	docker rmi $(IMAGE_NAME):$(IMAGE_TAG) 2>/dev/null || true
	kubectl delete namespace $(NAMESPACE) 2>/dev/null || true
	@echo "✅ 전체 정리 완료"

# eBPF 도구 관련
install-ebpf: ## eBPF 도구 설치 (Inspektor Gadget)
	@echo "🔍 eBPF 도구 설치 중..."
	kubectl apply -f https://raw.githubusercontent.com/inspektor-gadget/inspektor-gadget/main/deploy/gadget.yaml
	@echo "✅ eBPF 도구 설치 완료"
	@echo "⏳ 설치 상태 확인 중..."
	kubectl get pods -n gadget-system

track-memory: ## eBPF로 메모리 누수 추적
	@echo "🔍 eBPF로 메모리 누수 추적 중..."
	@echo "📝 Pod 이름을 입력하세요:"
	@read -p "Pod 이름: " pod_name; \
	kubectl gadget memleak -n $(NAMESPACE) -p $$pod_name

# 상태 확인
status: ## 배포 상태 확인
	@echo "📊 배포 상태 확인 중..."
	kubectl -n $(NAMESPACE) get all
	@echo ""
	@echo "📝 Pod 로그:"
	kubectl -n $(NAMESPACE) logs -l app=stealth-memory-leaker --tail=10

logs: ## 실시간 로그 확인
	@echo "📝 실시간 로그 확인 중..."
	kubectl -n $(NAMESPACE) logs -f -l app=stealth-memory-leaker

# 테스트 관련
test-health: ## 헬스체크 테스트
	@echo "💚 헬스체크 테스트 중..."
	@echo "📊 HTTP 응답 확인:"
	curl -s http://localhost:8080/health | jq '.' || curl -s http://localhost:8080/health

test-metrics: ## 메트릭 테스트
	@echo "📊 메트릭 테스트 중..."
	@echo "📈 Prometheus 메트릭 확인:"
	curl -s http://localhost:9090/metrics | head -20

# 디버깅
debug: ## 디버깅 정보 출력
	@echo "🐛 디버깅 정보:"
	@echo "📊 현재 상태:"
	@make status
	@echo ""
	@echo "🔍 eBPF 도구 상태:"
	kubectl get pods -n gadget-system 2>/dev/null || echo "eBPF 도구가 설치되지 않음"
	@echo ""
	@echo "📝 최근 이벤트:"
	kubectl -n $(NAMESPACE) get events --sort-by='.lastTimestamp' | tail -5

# 성능 테스트
benchmark: ## 성능 벤치마크
	@echo "⚡ 성능 벤치마크 시작..."
	@echo "📊 HTTP 응답 시간 테스트:"
	for i in {1..10}; do \
		time curl -s -o /dev/null http://localhost:8080/health; \
	done
	@echo ""
	@echo "📈 메트릭 수집 시간 테스트:"
	for i in {1..5}; do \
		time curl -s -o /dev/null http://localhost:9090/metrics; \
	done