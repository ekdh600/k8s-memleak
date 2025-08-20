# 🚀 설치 가이드

## 📋 사전 요구사항

### 필수 도구
- **Docker**: [다운로드](https://docs.docker.com/get-docker/)
- **kubectl**: [설치 가이드](https://kubernetes.io/docs/tasks/tools/)

### 선택 도구
- **Kind**: 로컬 쿠버네티스 클러스터 (로컬 개발용)
- **Minikube**: 로컬 쿠버네티스 클러스터 (로컬 개발용)
- **Make**: 빌드 자동화 (macOS: `brew install make`)

## 🔧 설치 과정

### 1. 프로젝트 클론
```bash
git clone https://github.com/ekdh600/k8s-memleak.git
cd k8s-memleak
```

### 2. Docker 이미지 빌드
```bash
make docker-build
```

### 3. 쿠버네티스 배포
```bash
make deploy
```

### 4. eBPF 도구 설치
```bash
make install-ebpf
```

## 🚀 빠른 시작

### 로컬 실행
```bash
# C 프로그램 빌드
make build

# 메모리 누수 시뮬레이션 실행
make run
```

### Docker 실행
```bash
# Docker 이미지 빌드
make docker-build

# Docker 컨테이너 실행
make docker-run
```

### 쿠버네티스 배포
```bash
# 배포
make deploy

# 상태 확인
make status

# 로그 확인
make logs
```

## 🔍 eBPF 트래킹

### Inspektor Gadget 설치
```bash
make install-ebpf
```

### 메모리 누수 추적
```bash
make track-memory
```

### 수동 트래킹
```bash
# Pod 이름 확인
kubectl -n memleak-demo get pods

# eBPF로 메모리 누수 추적
kubectl gadget memleak -n memleak-demo -p <pod-name>
```

## 🧪 테스트

### 기본 기능 테스트
```bash
# 로컬 빌드 테스트
make build

# Docker 빌드 테스트
make docker-build

# 쿠버네티스 배포 테스트
make deploy
```

### eBPF 트래킹 테스트
```bash
# eBPF 도구 설치 테스트
make install-ebpf

# 트래킹 기능 테스트
make track-memory
```

## 📊 모니터링

### Pod 상태 확인
```bash
make status
```

### 실시간 로그 확인
```bash
make logs
```

### 수동 모니터링
```bash
# Pod 상태
kubectl -n memleak-demo get all

# Pod 로그
kubectl -n memleak-demo logs -f deployment/memory-leaker

# 이벤트
kubectl -n memleak-demo get events
```

## 🔍 문제 해결

### 일반적인 문제들

#### 1. 권한 문제
```bash
# Pod가 privileged 모드로 실행되는지 확인
kubectl -n memleak-demo describe pod <pod-name>

# 필요한 capabilities 확인
kubectl -n memleak-demo get pod <pod-name> -o yaml | grep -A 10 securityContext
```

#### 2. 이미지 빌드 실패
```bash
# Docker 데몬 상태 확인
docker info

# 이미지 정리 후 재빌드
docker system prune -f
make docker-build
```

#### 3. 배포 실패
```bash
# 네임스페이스 확인
kubectl get namespaces | grep memleak

# 이벤트 확인
kubectl -n memleak-demo get events

# Pod 상태 상세 확인
kubectl -n memleak-demo describe pod <pod-name>
```

#### 4. eBPF 도구 설치 실패
```bash
# 네임스페이스 확인
kubectl get namespaces | grep gadget

# Pod 상태 확인
kubectl get pods -n gadget-system

# 로그 확인
kubectl logs -n gadget-system -l app=gadget
```

### 디버깅 명령어
```bash
# Pod 상태 확인
kubectl -n memleak-demo get all

# 로그 확인
kubectl -n memleak-demo logs -f deployment/memory-leaker

# 이벤트 확인
kubectl -n memleak-demo get events --sort-by='.lastTimestamp'

# Pod 상세 정보
kubectl -n memleak-demo describe pod <pod-name>
```

## 📚 다음 단계

1. **eBPF 트래킹**: [eBPF 가이드](EBPF_GUIDE.md)
2. **고급 진단**: 다양한 eBPF 도구 사용법
3. **성능 최적화**: 트래킹 오버헤드 최소화

## 🤝 지원

문제가 발생하거나 질문이 있으시면:
- [GitHub Issues](../../issues)에 버그 리포트
- [GitHub Discussions](../../discussions)에서 질문
- [eBPF 가이드](EBPF_GUIDE.md)에서 상세 가이드 확인

## 🔄 정리

### 로컬 정리
```bash
make clean
```

### 전체 정리
```bash
make clean-all
```

---

**💡 팁**: 문제가 발생하면 `make status`로 상태를 확인하고, `make logs`로 로그를 분석하세요!