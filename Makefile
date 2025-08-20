# 은밀한 메모리 누수 시뮬레이션 서비스 - 최소 환경 구성 Makefile
.PHONY: help build run clean docker-build docker-run deploy clean-all install install-rhel8 install-ubuntu check-k8s

# 기본값
IMAGE_NAME ?= stealth-memory-leaker
IMAGE_TAG ?= latest
NAMESPACE ?= memleak-demo

# 환경별 최소 구성 감지
ifeq ($(shell grep -c "Red Hat Enterprise Linux 8" /etc/redhat-release 2>/dev/null),1)
    PLATFORM := rhel8
    CC := gcc
    CFLAGS := -O2 -pthread -static
    INSTALL_SCRIPT := scripts/install-rhel8.sh
    EBPF_TOOLS := bcc-tools
    CONTAINER_CMD := podman
else ifeq ($(shell which podman 2>/dev/null),/usr/bin/podman)
    PLATFORM := rhel8-like
    CC := gcc
    CFLAGS := -O2 -pthread -static
    INSTALL_SCRIPT := scripts/install-rhel8.sh
    EBPF_TOOLS := bcc-tools
    CONTAINER_CMD := podman
else ifeq ($(shell grep -c "Ubuntu" /etc/os-release 2>/dev/null),1)
    PLATFORM := ubuntu
    CC := gcc
    CFLAGS := -O2 -pthread
    INSTALL_SCRIPT := scripts/install-ubuntu.sh
    EBPF_TOOLS := bpfcc-tools
    CONTAINER_CMD := docker
else
    PLATFORM := generic
    CC := gcc
    CFLAGS := -O2 -pthread
    INSTALL_SCRIPT := scripts/install-generic.sh
    EBPF_TOOLS := generic-ebpf
    CONTAINER_CMD := docker
endif

help: ## 도움말 표시
	@echo "🔬 은밀한 메모리 누수 시뮬레이션 서비스"
	@echo "======================================"
	@echo ""
	@echo "🎯 목표: 표준 모니터링에서는 '정상', 실제로는 메모리 누수"
	@echo "📊 특징:"
	@echo "  - HTTP 서버로 헬스체크 제공 (포트 8080)"
	@echo "  - Prometheus 메트릭 서버 (포트 9090)"
	@echo "  - Grafana 대시보드 (거짓 '정상' 표시)"
	@echo "  - 모든 메트릭에서 '정상' 표시"
	@echo "  - 백그라운드에서 은밀한 메모리 누수 (8초마다 1MB)"
	@echo "  - eBPF로만 진짜 문제 확인 가능"
	@echo ""
	@echo "🌍 현재 환경: $(PLATFORM)"
	@echo "🐳 컨테이너 도구: $(CONTAINER_CMD)"
	@echo "📦 설치 스크립트: $(INSTALL_SCRIPT)"
	@echo ""
	@echo "사용법:"
	@echo "  make install          - 환경별 최소 환경 구성"
	@echo "  make check-k8s        - 쿠버네티스 도구 확인 (설치하지 않음)"
	@echo "  make build            - 로컬에서 C 프로그램 빌드"
	@echo "  make run              - 로컬에서 메인 서비스 실행"
	@echo "  make docker-build     - 컨테이너 이미지 빌드"
	@echo "  make deploy           - 쿠버네티스에 배포"
	@make -s print-targets

print-targets:
	@echo ""
	@echo "추가 명령어:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

# 쿠버네티스 도구 확인 (설치하지 않고 확인만)
check-k8s: ## 쿠버네티스 도구 확인 (설치하지 않음)
	@echo "🔍 쿠버네티스 도구 확인 중..."
	@echo "📋 kubectl 확인:"
	@if command -v kubectl &> /dev/null; then \
		KUBECTL_VERSION=$$(kubectl version --client --short 2>/dev/null | cut -d' ' -f3); \
		echo "✅ kubectl이 설치되어 있습니다. 버전: $$KUBECTL_VERSION"; \
		echo "📍 경로: $$(which kubectl)"; \
	else \
		echo "❌ kubectl이 설치되지 않았습니다."; \
		echo "📝 수동 설치 방법:"; \
		echo "   curl -LO 'https://dl.k8s.io/release/\$$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl'"; \
		echo "   sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl"; \
	fi
	@echo ""
	@echo "📋 kind 확인:"
	@if command -v kind &> /dev/null; then \
		echo "✅ kind가 설치되어 있습니다. 경로: $$(which kind)"; \
	else \
		echo "❌ kind가 설치되지 않았습니다."; \
	fi
	@echo ""
	@echo "📋 minikube 확인:"
	@if command -v minikube &> /dev/null; then \
		echo "✅ minikube가 설치되어 있습니다. 경로: $$(which minikube)"; \
	else \
		echo "❌ minikube가 설치되지 않았습니다."; \
	fi

# 환경별 최소 설치 (호스트 예민 부분은 건드리지 않음)
install: ## 환경별 최소 환경 구성 (자동 감지)
	@echo "🔧 환경별 최소 환경 구성 중..."
	@echo "🌍 감지된 환경: $(PLATFORM)"
	@echo "📦 사용할 스크립트: $(INSTALL_SCRIPT)"
	@if [ -f "$(INSTALL_SCRIPT)" ]; then \
		echo "🚀 $(INSTALL_SCRIPT) 실행 중..."; \
		sudo $(INSTALL_SCRIPT); \
	else \
		echo "❌ $(INSTALL_SCRIPT)을 찾을 수 없습니다."; \
		echo "수동으로 환경을 구성해주세요."; \
	fi

install-rhel8: ## RHEL 8 최소 환경 구성
	@echo "🔧 RHEL 8 최소 환경 구성 중..."
	@echo "📋 목표: 시나리오 구동 가능한 최소한의 환경만 구성"
	@echo "🚫 제한: 방화벽, AppArmor 등 호스트 예민 부분은 건드리지 않음"
	@echo "🔍 쿠버네티스: 설치하지 않고 확인만 진행"
	@if [ -f "scripts/install-rhel8.sh" ]; then \
		sudo ./scripts/install-rhel8.sh; \
	else \
		echo "❌ RHEL 8 설치 스크립트를 찾을 수 없습니다."; \
	fi

install-ubuntu: ## Ubuntu 최소 환경 구성
	@echo "🔧 Ubuntu 최소 환경 구성 중..."
	@echo "📋 목표: 시나리오 구동 가능한 최소한의 환경만 구성"
	@echo "🚫 제한: 방화벽, AppArmor 등 호스트 예민 부분은 건드리지 않음"
	@echo "🔍 쿠버네티스: 설치하지 않고 확인만 진행"
	@if [ -f "scripts/install-ubuntu.sh" ]; then \
		sudo ./scripts/install-ubuntu.sh; \
	else \
		echo "❌ Ubuntu 설치 스크립트를 찾을 수 없습니다."; \
	fi

build: ## C 프로그램 빌드
	@echo "🔨 C 프로그램 빌드 중..."
	@mkdir -p bin
	$(CC) $(CFLAGS) -o bin/main_service src/main_service.c
	$(CC) $(CFLAGS) -o bin/healthy_service src/healthy_service.c
	$(CC) $(CFLAGS) -o bin/fake_metrics src/fake_metrics.c
	@echo "✅ 빌드 완료:"
	@ls -lh bin/
	@echo ""
	@echo "📋 실행 가능한 서비스들:"
	@echo "  - main_service: 통합 서비스 (HTTP + 메트릭 + 메모리 누수)"
	@echo "  - healthy_service: HTTP 헬스체크 서비스"
	@echo "  - fake_metrics: Prometheus 메트릭 서버"

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

docker-build: ## 컨테이너 이미지 빌드
	@echo "🐳 컨테이너 이미지 빌드 중..."
	@echo "🌍 환경: $(PLATFORM), 도구: $(CONTAINER_CMD)"
	$(CONTAINER_CMD) build -t $(IMAGE_NAME):$(IMAGE_TAG) .
	@echo "✅ 이미지 빌드 완료: $(IMAGE_NAME):$(IMAGE_TAG)"
	@$(CONTAINER_CMD) images $(IMAGE_NAME):$(IMAGE_TAG)

docker-run: docker-build ## 컨테이너 실행
	@echo "🚀 컨테이너 실행 중..."
	@echo "📊 서비스 엔드포인트:"
	@echo "  - HTTP 서버: http://localhost:8080"
	@echo "  - 메트릭 서버: http://localhost:9090/metrics"
	@echo "---"
	$(CONTAINER_CMD) run --rm -it -p 8080:8080 -p 9090:9090 $(IMAGE_NAME):$(IMAGE_TAG)

deploy: check-k8s ## 쿠버네티스에 배포 (kubectl 확인 후)
	@echo "☸️ 쿠버네티스에 배포 중..."
	@echo "📋 네임스페이스 생성..."
	kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	@echo "📦 기본 서비스 배포..."
	kubectl apply -f k8s/
	@echo "📊 모니터링 스택 배포..."
	kubectl apply -f k8s/prometheus.yaml
	kubectl apply -f k8s/grafana.yaml
	@echo "⏳ 배포 상태 확인 중..."
	kubectl -n $(NAMESPACE) rollout status deployment/stealth-memory-leaker --timeout=120s
	kubectl -n $(NAMESPACE) rollout status deployment/prometheus --timeout=120s
	kubectl -n $(NAMESPACE) rollout status deployment/grafana --timeout=120s
	@echo "✅ 배포 완료!"
	@echo ""
	@echo "📊 서비스 상태:"
	kubectl -n $(NAMESPACE) get all
	@echo ""
	@echo "🔍 eBPF 트래킹 준비:"
	@echo "  make install-ebpf"
	@echo "  make track-memory"
	@echo ""
	@echo "📈 모니터링 접근:"
	@echo "  - Prometheus: kubectl -n $(NAMESPACE) port-forward svc/prometheus-service 9090:9090"
	@echo "  - Grafana: kubectl -n $(NAMESPACE) port-forward svc/grafana-service 3000:3000"

clean: ## 빌드 파일 정리
	@echo "🧹 빌드 파일 정리 중..."
	rm -rf bin/
	@echo "✅ 정리 완료"

clean-all: clean ## 모든 생성 파일 정리
	@echo "🧹 모든 생성 파일 정리 중..."
	@if [ "$(CONTAINER_CMD)" = "podman" ]; then \
		podman rmi $(IMAGE_NAME):$(IMAGE_TAG) 2>/dev/null || true; \
	else \
		docker rmi $(IMAGE_NAME):$(IMAGE_TAG) 2>/dev/null || true; \
	fi
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

# 모니터링 관련
monitoring-status: ## 모니터링 상태 확인
	@echo "📊 모니터링 상태 확인 중..."
	@echo "Prometheus:"
	kubectl -n $(NAMESPACE) get pods -l app=prometheus
	@echo ""
	@echo "Grafana:"
	kubectl -n $(NAMESPACE) get pods -l app=grafana
	@echo ""
	@echo "📈 접근 방법:"
	@echo "  Prometheus: kubectl -n $(NAMESPACE) port-forward svc/prometheus-service 9090:9090"
	@echo "  Grafana: kubectl -n $(NAMESPACE) port-forward svc/grafana-service 3000:3000"

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
	@echo "🌍 환경: $(PLATFORM)"
	@echo "🐳 컨테이너 도구: $(CONTAINER_CMD)"
	@echo "📦 설치 스크립트: $(INSTALL_SCRIPT)"
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

# 환경 정보
env-info: ## 환경 정보 출력
	@echo "🌍 환경 정보:"
	@echo "  플랫폼: $(PLATFORM)"
	@echo "  컨테이너 도구: $(CONTAINER_CMD)"
	@echo "  컴파일러: $(CC)"
	@echo "  컴파일 플래그: $(CFLAGS)"
	@echo "  설치 스크립트: $(INSTALL_SCRIPT)"
	@echo "  eBPF 도구: $(EBPF_TOOLS)"
	@if [ -f /etc/redhat-release ]; then \
		echo "  배포판: $(cat /etc/redhat-release)"; \
	elif [ -f /etc/os-release ]; then \
		echo "  배포판: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"; \
	fi
	@echo "  커널: $(uname -r)"
	@echo "  아키텍처: $(uname -m)"