# 🚀 Memory Leak Demo 설치 가이드

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
git clone <repository-url>
cd memory-leak-demo
```

### 2. Docker 이미지 빌드
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

### 2단계: 이미지 빌드

#### 자동 빌드 (권장)
```bash
./scripts/build.sh
```

#### 수동 빌드
```bash
docker build -t memory-leak-demo:latest .
```

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

# 메모리 누수 추적
kubectl gadget memleak -n memleak-demo -p <pod-name>
```

### BCC memleak 사용 (노드에서)
```bash
# Pod의 PID 확인
kubectl -n memleak-demo exec <pod-name> -- ps aux

# 메모리 누수 추적
sudo /usr/share/bcc/tools/memleak -p <pid>
```

### bpftrace 사용 (노드에서)
```bash
# 메모리 할당 이벤트 추적
sudo bpftrace -e '
tracepoint:syscalls:sys_enter_mmap {
    printf("PID %d: mmap size=%d\n", pid, args->len);
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

### 로그 확인
```bash
# 애플리케이션 로그
kubectl -n memleak-demo logs -f deployment/stealth-memory-leaker

# Grafana 로그
kubectl -n memleak-demo logs -f deployment/grafana

# Prometheus 로그
kubectl -n memleak-demo logs -f deployment/prometheus
```

## 📚 추가 리소스

- [eBPF 트래킹 가이드](EBPF_GUIDE.md)
- [프로젝트 README](README.md)
- [Kubernetes 공식 문서](https://kubernetes.io/docs/)
- [eBPF 공식 문서](https://ebpf.io/)

## 🤝 지원

문제가 발생하거나 질문이 있으시면:
1. GitHub Issues에 문제를 등록
2. 프로젝트 문서 확인
3. 커뮤니티 포럼 참여

---

**🎯 목표**: 표준 모니터링의 한계를 체감하고, eBPF의 강력함을 경험하여 실제 운영 환경에서의 문제 진단 능력을 향상시키세요!