# 🚀 파드 메모리 누수 eBPF 트래킹 데모 설치 가이드

이 가이드는 Memory Leak Demo 프로젝트를 설치하고 실행하는 방법을 설명합니다.

## 📋 사전 요구사항

### 필수 도구
- **Docker**: 20.10+ (Docker Desktop 또는 Docker Engine)
- **kubectl**: Kubernetes 클라이언트
- **Kubernetes 클러스터**: 로컬 또는 클라우드

### 권장 환경
- **로컬**: Kind, Minikube, Docker Desktop Kubernetes
- **클라우드**: AKS, EKS, GKE
- **OS**: Linux, macOS, Windows (WSL2)

## 🚀 빠른 설치

### 1. 프로젝트 클론
```bash
git clone https://github.com/ekdh600/k8s-memleak.git
cd k8s-memleak
```

### 2. Docker 이미지 빌드 (GCC 포함)
```bash
./scripts/build.sh
```

### 3. Kubernetes 배포
```bash
./scripts/deploy.sh
```

### 4. eBPF 도구 설정
```bash
./scripts/ebpf-setup.sh
```

## 🔧 상세 설치 과정

### 1단계: 환경 확인

#### Docker 확인
```bash
docker --version
docker info
```

#### Kubernetes 클러스터 확인
```bash
kubectl cluster-info
kubectl get nodes
```

### 2단계: 이미지 빌드 (GCC 기반)

#### 자동 빌드 (권장)
```bash
./scripts/build.sh
```

#### 수동 빌드
```bash
docker build -t memory-leak-demo:latest .
```

#### GCC 빌드 과정 상세
```dockerfile
# 1단계: GCC 11 컴파일러로 C 소스 빌드
FROM gcc:11 as builder
WORKDIR /app
COPY src/*.c .

# 멀티스레드 C 프로그램 컴파일
RUN gcc -O2 -static -s -pthread -o main_service main_service.c \
    && gcc -O2 -static -s -pthread -o healthy_service healthy_service.c \
    && gcc -O2 -static -s -pthread -o fake_metrics fake_metrics.c

# 2단계: 실행 이미지 (Alpine Linux)
FROM alpine:3.18
COPY --from=builder /app/* .
```

#### 컴파일 옵션 설명
- **-O2**: 최적화 레벨 2 (성능 최적화)
- **-static**: 정적 링킹 (의존성 문제 방지)
- **-s**: 심볼 정보 제거 (이미지 크기 최소화)
- **-pthread**: 멀티스레드 지원 (메모리 누수 시뮬레이션용)

### 3단계: Kubernetes 배포

#### 자동 배포 (권장)
```bash
./scripts/deploy.sh
```

#### 수동 배포
```bash
# 네임스페이스 생성
kubectl apply -f k8s/namespace.yaml

# Prometheus 배포
kubectl apply -f k8s/prometheus.yaml

# Grafana 배포
kubectl apply -f k8s/grafana.yaml

# 메인 애플리케이션 배포
kubectl apply -f k8s/deployment.yaml

# 서비스 배포
kubectl apply -f k8s/service.yaml
```

### 4단계: eBPF 도구 설정

#### Inspektor Gadget 설치
```bash
kubectl apply -f k8s/inspektor-gadget.yaml
```

#### BCC 도구 설치 (노드에서)
```bash
# Ubuntu/Debian
sudo apt-get install -y bpfcc-tools

# RHEL/CentOS
sudo yum install -y bcc-tools
```

#### bpftrace 설치 (노드에서)
```bash
# Ubuntu/Debian
sudo apt-get install -y bpftrace

# RHEL/CentOS
sudo yum install -y bpftrace
```

## 🎨 Grafana 설정 및 대시보드

### 자동 설정 파일들
- **대시보드**: `grafana/dashboards/stealth-memory-leak.json`
- **데이터 소스**: `grafana/provisioning/datasources/prometheus.yaml`
- **자동 로드**: `grafana/provisioning/dashboards/dashboards.yaml`

### Grafana 대시보드 특징
1. **서비스 헬스 상태**: 항상 "Healthy" 표시 (거짓)
2. **메모리 사용량**: 거짓 "정상" 범위로 표시
3. **HTTP 요청 수**: 정상적인 요청 패턴
4. **응답 시간**: 점진적 지연 (숨겨짐)

### Grafana 접속 및 설정
```bash
# 포트포워딩
kubectl -n memleak-demo port-forward svc/grafana 3000:3000

# 브라우저에서 접속
# http://localhost:3000 (admin/admin)

# 대시보드 자동 로드 확인
# Settings > Data Sources > Prometheus 연결 상태 확인
# Dashboards > Stealth Memory Leak 대시보드 확인
```

## 🧪 테스트 및 검증

### 1. 배포 상태 확인
```bash
kubectl -n memleak-demo get all
kubectl -n memleak-demo get pods
```

### 2. 서비스 접속 테스트
```bash
# 포트포워딩
kubectl -n memleak-demo port-forward svc/stealth-memory-leaker 8080:8080

# 브라우저에서 접속
# http://localhost:8080/health
```

### 3. Grafana 접속
```bash
# 포트포워딩
kubectl -n memleak-demo port-forward svc/grafana 3000:3000

# 브라우저에서 접속
# http://localhost:3000 (admin/admin)
```

### 4. Prometheus 접속
```bash
# 포트포워딩
kubectl -n memleak-demo port-forward svc/prometheus 9090:9090

# 브라우저에서 접속
# http://localhost:9090
```

## 🔍 메모리 누수 추적

### Inspektor Gadget 사용
```bash
# Pod 이름 확인
kubectl -n memleak-demo get pods

# 메모리 누수 추적 시작
kubectl gadget memleak -n memleak-demo -p <pod-name>

# 출력 해석
Allocated memory:
  PID: 12345
  Size: 1048576 bytes (1MB)
  Stack trace:
    malloc+0x1a
    memory_leak_thread+0x45
    start_thread+0x87
```

### BCC memleak 사용 (노드에서)
```bash
# Pod의 PID 확인
kubectl -n memleak-demo exec <pod-name> -- ps aux

# 메모리 누수 추적
sudo /usr/share/bcc/tools/memleak -p <pid>

# 전체 시스템 메모리 누수 추적
sudo /usr/share/bcc/tools/memleak
```

### bpftrace 사용 (노드에서)
```bash
# 메모리 할당 이벤트 추적
sudo bpftrace -e '
tracepoint:syscalls:sys_enter_mmap {
    printf("PID %d: mmap size=%d\n", pid, args->len);
}
'

# malloc 호출 추적
sudo bpftrace -e '
uprobe:libc.so.6:malloc {
    printf("PID %d: malloc size=%d\n", pid, arg0);
}
'
```

## 🐳 로컬 테스트 (Docker Compose)

### 1. 로컬 실행
```bash
docker-compose up -d
```

### 2. 서비스 접속
- **애플리케이션**: http://localhost:8080
- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9091

### 3. 정리
```bash
docker-compose down
```

## 🔧 GCC 빌드 상세 과정

### 멀티스테이지 빌드 장점
1. **빌드 이미지**: GCC 11 + 개발 도구
2. **실행 이미지**: Alpine Linux (경량)
3. **결과**: 최적화된 바이너리만 포함

### 컴파일 최적화
```bash
# GCC 최적화 옵션
-O2          # 최적화 레벨 2
-static      # 정적 링킹
-s           # 심볼 정보 제거
-pthread     # 멀티스레드 지원
```

### 빌드 결과물 검증
```bash
# 바이너리 크기 확인
ls -lh main_service healthy_service fake_metrics

# 의존성 확인
ldd main_service  # 정적 링킹으로 의존성 없음

# 실행 권한 확인
file main_service
```

## 🧹 정리

### Kubernetes 리소스 정리
```bash
./scripts/cleanup.sh
```

### Docker 리소스 정리
```bash
docker-compose down
docker rmi memory-leak-demo:latest
```

## 🚨 문제 해결

### 일반적인 문제

#### 1. Pod가 시작되지 않음
```bash
# Pod 상태 확인
kubectl -n memleak-demo get pods

# Pod 이벤트 확인
kubectl -n memleak-demo describe pod <pod-name>

# Pod 로그 확인
kubectl -n memleak-demo logs <pod-name>
```

#### 2. 서비스에 접속할 수 없음
```bash
# 서비스 상태 확인
kubectl -n memleak-demo get svc

# 엔드포인트 확인
kubectl -n memleak-demo get endpoints
```

#### 3. eBPF 도구가 작동하지 않음
```bash
# Inspektor Gadget 상태 확인
kubectl -n gadget get pods

# 노드에서 BCC 도구 확인
sudo /usr/share/bcc/tools/memleak --help
```

#### 4. Grafana 대시보드가 로드되지 않음
```bash
# Grafana Pod 상태 확인
kubectl -n memleak-demo get pods -l app=grafana

# Grafana 로그 확인
kubectl -n memleak-demo logs -f deployment/grafana

# 설정 파일 확인
kubectl -n memleak-demo exec deployment/grafana -- cat /etc/grafana/provisioning/dashboards/dashboards.yaml
```

#### 5. GCC 빌드 실패
```bash
# Docker 이미지 확인
docker images | grep gcc

# 빌드 로그 확인
docker build -t memory-leak-demo:latest . 2>&1 | tee build.log

# 소스 코드 문법 확인
docker run --rm -v $(pwd)/src:/src gcc:11 gcc -fsyntax-only /src/*.c
```

### 로그 확인
```bash
# 애플리케이션 로그
kubectl -n memleak-demo logs -f deployment/stealth-memory-leaker

# Grafana 로그
kubectl -n memleak-demo logs -f deployment/grafana

# Prometheus 로그
kubectl -n memleak-demo logs -f deployment/prometheus
```

## 📊 모니터링 및 검증

### 메모리 누수 시뮬레이션 확인
```bash
# Pod 메모리 사용량 모니터링
kubectl -n memleak-demo top pods

# 메모리 사용량 추이 확인
kubectl -n memleak-demo exec deployment/stealth-memory-leaker -- cat /proc/self/status | grep VmRSS

# 로그에서 메모리 누수 패턴 확인
kubectl -n memleak-demo logs -f deployment/stealth-memory-leaker | grep "메모리 누수"
```

### eBPF 트래킹 결과 검증
```bash
# Inspektor Gadget 상태 확인
kubectl gadget info

# 메모리 누수 추적 결과 확인
kubectl gadget memleak -n memleak-demo -p <pod-name> --duration 60s

# BCC 도구로 교차 검증
sudo /usr/share/bcc/tools/memleak -p <pid> --duration 60
```

## 📚 추가 리소스

- [eBPF 트래킹 가이드](EBPF_GUIDE.md) - 상세한 eBPF 사용법
- [프로젝트 README](README.md) - 프로젝트 개요
- [Kubernetes 공식 문서](https://kubernetes.io/docs/)
- [eBPF 공식 문서](https://ebpf.io/)
- [Grafana 공식 문서](https://grafana.com/docs/)
- [GCC 공식 문서](https://gcc.gnu.org/onlinedocs/)

## 🤝 지원

문제가 발생하거나 질문이 있으시면:
1. GitHub Issues에 문제를 등록
2. 프로젝트 문서 확인
3. 커뮤니티 포럼 참여

---

**🎯 목표**: 쿠버네티스 파드의 은밀한 메모리 누수를 eBPF로 진단하여, 표준 모니터링의 한계와 eBPF의 강력함을 체험하세요!

**🔍 핵심 학습**: 
1. **GCC로 C 프로그램 빌드**하여 메모리 누수 시뮬레이션
2. **Grafana의 거짓 메트릭**을 eBPF로 폭로
3. **실제 운영 환경**에서의 문제 진단 능력 향상