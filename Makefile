# 메모리 누수 데모 프로젝트 Makefile

.PHONY: help build test clean docker-build docker-run k8s-deploy k8s-clean demo-local demo-k8s

# 기본 설정
BINARY_NAME=app
DOCKER_IMAGE=memleak
DOCKER_TAG=latest
NAMESPACE=memleak-demo

help: ## 도움말 표시
	@echo "🚨 메모리 누수 데모 프로젝트"
	@echo ""
	@echo "사용법:"
	@echo "  make <target>"
	@echo ""
	@echo "타겟:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Go 애플리케이션 빌드
	@echo "🔨 Go 애플리케이션 빌드 중..."
	go mod download
	go build -o $(BINARY_NAME) main.go
	@echo "✅ 빌드 완료: $(BINARY_NAME)"

test: ## 테스트 실행
	@echo "🧪 테스트 실행 중..."
	go test -v ./...
	@echo "✅ 테스트 완료"

test-leak: ## 메모리 누수 테스트만 실행
	@echo "🧪 메모리 누수 테스트 실행 중..."
	go test -v -run TestHeapDoesNotGrowUnbounded -timeout 2m
	go test -v -run TestMemoryLeakSimulation -timeout 1m
	@echo "✅ 메모리 누수 테스트 완료"

leak-check: ## 메모리 누수 감지 스크립트 실행
	@echo "🔍 메모리 누수 감지 스크립트 실행 중..."
	@chmod +x ci/leak_check.sh
	@BIN=./$(BINARY_NAME) DURATION=30 THRESHOLD_KB=15000 ./ci/leak_check.sh

docker-build: ## Docker 이미지 빌드
	@echo "🐳 Docker 이미지 빌드 중..."
	docker build -t $(DOCKER_IMAGE):$(DOCKER_TAG) .
	@echo "✅ Docker 이미지 빌드 완료: $(DOCKER_IMAGE):$(DOCKER_TAG)"

docker-run: ## Docker 컨테이너 실행
	@echo "🚀 Docker 컨테이너 실행 중..."
	docker run -d --name memleak-demo -p 6060:6060 $(DOCKER_IMAGE):$(DOCKER_TAG)
	@echo "✅ 컨테이너 실행됨: http://localhost:6060/debug/pprof/"

docker-stop: ## Docker 컨테이너 중지
	@echo "🛑 Docker 컨테이너 중지 중..."
	docker stop memleak-demo || true
	docker rm memleak-demo || true
	@echo "✅ 컨테이너 중지됨"

k8s-deploy: ## 쿠버네티스에 배포
	@echo "🚀 쿠버네티스 배포 중..."
	kubectl apply -f k8s/
	@echo "⏳ 배포 완료 대기 중..."
	kubectl -n $(NAMESPACE) rollout status deployment/leaky --timeout=120s
	@echo "✅ 배포 완료!"

k8s-clean: ## 쿠버네티스 리소스 정리
	@echo "🧹 쿠버네티스 리소스 정리 중..."
	kubectl delete -f k8s/ --ignore-not-found=true
	@echo "✅ 정리 완료"

k8s-status: ## 쿠버네티스 상태 확인
	@echo "📊 쿠버네티스 상태 확인 중..."
	kubectl -n $(NAMESPACE) get all
	kubectl -n $(NAMESPACE) get events --sort-by='.lastTimestamp'

demo-local: build ## 로컬 데모 실행
	@echo "🎭 로컬 메모리 누수 데모 시작"
	@echo "📱 애플리케이션: http://localhost:6060/debug/pprof/"
	@echo "⏰ 30초 후 메모리 누수 감지 스크립트 실행"
	@echo "💡 Ctrl+C로 중지"
	@./$(BINARY_NAME) &
	@sleep 30
	@make leak-check
	@pkill -f $(BINARY_NAME) || true

demo-k8s: docker-build ## 쿠버네티스 데모 실행
	@echo "🎭 쿠버네티스 메모리 누수 데모 시작"
	@echo "📦 이미지 빌드 완료"
	@echo "🚀 배포 중..."
	@make k8s-deploy
	@echo "⏳ 60초 후 상태 확인..."
	@sleep 60
	@make k8s-status
	@echo "💡 정리하려면: make k8s-clean"

ebpf-setup: ## eBPF 도구 설정
	@echo "🔧 eBPF 도구 설정 중..."
	kubectl apply -f https://raw.githubusercontent.com/inspektor-gadget/inspektor-gadget/main/deploy/gadget.yaml
	@echo "⏳ Gadget 시스템 시작 대기 중..."
	kubectl wait --for=condition=ready pod -l app=gadget -n gadget-system --timeout=120s
	@echo "✅ eBPF 도구 설정 완료"

ebpf-memleak: ## eBPF 메모리 누수 추적
	@echo "🔍 eBPF 메모리 누수 추적 시작"
	@chmod +x scripts/ebpf-memleak.sh
	@./scripts/ebpf-memleak.sh

clean: ## 빌드 파일 정리
	@echo "🧹 빌드 파일 정리 중..."
	rm -f $(BINARY_NAME)
	rm -f *.pb
	@echo "✅ 정리 완료"

all: clean build test ## 전체 빌드 및 테스트
	@echo "🎉 전체 프로세스 완료!"

install-tools: ## 필요한 도구 설치
	@echo "📦 필요한 도구 설치 중..."
	@if ! command -v kind &> /dev/null; then \
		echo "Installing kind..."; \
		brew install kind; \
	fi
	@if ! command -v kubectl &> /dev/null; then \
		echo "Installing kubectl..."; \
		brew install kubectl; \
	fi
	@if ! command -v docker &> /dev/null; then \
		echo "Installing Docker Desktop..."; \
		echo "Please install Docker Desktop manually from https://www.docker.com/products/docker-desktop"; \
	fi
	@echo "✅ 도구 설치 완료"

setup-kind: ## Kind 클러스터 설정
	@echo "🚀 Kind 클러스터 설정 중..."
	kind create cluster --name memleak-demo --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 6060
    hostPort: 6060
    protocol: TCP
EOF
	@echo "✅ Kind 클러스터 설정 완료"

destroy-kind: ## Kind 클러스터 삭제
	@echo "🗑️ Kind 클러스터 삭제 중..."
	kind delete cluster --name memleak-demo
	@echo "✅ Kind 클러스터 삭제 완료"

# 개발용 타겟
dev: build ## 개발 모드 실행
	@echo "🔧 개발 모드 시작"
	@echo "📱 애플리케이션: http://localhost:6060/debug/pprof/"
	@echo "💡 Ctrl+C로 중지"
	@./$(BINARY_NAME)

# 프로덕션용 타겟
prod: docker-build ## 프로덕션 빌드
	@echo "🚀 프로덕션 빌드 시작"
	@make docker-build
	@echo "✅ 프로덕션 빌드 완료"