# 메모리 누수 시뮬레이터 - 간소화된 Makefile
.PHONY: help build run clean docker-build docker-run deploy clean-all

# 기본값
IMAGE_NAME ?= memory-leaker
IMAGE_TAG ?= latest
NAMESPACE ?= memleak-demo

help: ## 도움말 표시
	@echo "🔬 메모리 누수 시뮬레이터 빌드 및 실행"
	@echo "======================================"
	@echo ""
	@echo "사용법:"
	@echo "  make build          - 로컬에서 C 프로그램 빌드"
	@echo "  make run            - 로컬에서 메모리 누수 시뮬레이션 실행"
	@echo "  make docker-build   - Docker 이미지 빌드"
	@make -s print-targets

print-targets:
	@echo ""
	@echo "추가 명령어:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## C 프로그램 빌드
	@echo "🔨 C 프로그램 빌드 중..."
	@mkdir -p bin
	gcc -O2 -o bin/memory_leak src/memory_leak.c
	@echo "✅ 빌드 완료: bin/memory_leak"
	@ls -lh bin/memory_leak

run: build ## 로컬에서 메모리 누수 시뮬레이션 실행
	@echo "🚀 메모리 누수 시뮬레이션 시작..."
	@echo "📝 종료하려면 Ctrl+C"
	@echo "---"
	./bin/memory_leak

docker-build: ## Docker 이미지 빌드
	@echo "🐳 Docker 이미지 빌드 중..."
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .
	@echo "✅ 이미지 빌드 완료: $(IMAGE_NAME):$(IMAGE_TAG)"
	@docker images $(IMAGE_NAME):$(IMAGE_TAG)

docker-run: docker-build ## Docker 컨테이너 실행
	@echo "🚀 Docker 컨테이너 실행 중..."
	@echo "📝 종료하려면 Ctrl+C"
	@echo "---"
	docker run --rm -it $(IMAGE_NAME):$(IMAGE_TAG)

deploy: ## 쿠버네티스에 배포
	@echo "☸️ 쿠버네티스에 배포 중..."
	@echo "📋 네임스페이스 생성..."
	kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	@echo "📦 배포 매니페스트 적용..."
	kubectl apply -f k8s/
	@echo "⏳ 배포 상태 확인 중..."
	kubectl -n $(NAMESPACE) rollout status deployment/memory-leaker --timeout=120s
	@echo "✅ 배포 완료!"
	@echo "📊 상태 확인: kubectl -n $(NAMESPACE) get all"

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
	kubectl -n $(NAMESPACE) logs -l app=memory-leaker --tail=10

logs: ## 실시간 로그 확인
	@echo "📝 실시간 로그 확인 중..."
	kubectl -n $(NAMESPACE) logs -f -l app=memory-leaker