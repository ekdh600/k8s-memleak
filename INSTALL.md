# 🚀 설치 가이드

## 📋 사전 요구사항

### 필수 도구
- **Go 1.22+**: [다운로드](https://golang.org/dl/)
- **Docker**: [다운로드](https://docs.docker.com/get-docker/)
- **kubectl**: [설치 가이드](https://kubernetes.io/docs/tasks/tools/)

### 선택 도구
- **Kind**: 로컬 쿠버네티스 클러스터 (로컬 개발용)
- **Minikube**: 로컬 쿠버네티스 클러스터 (로컬 개발용)
- **Helm**: 쿠버네티스 패키지 매니저

## 🔧 설치 과정

### 1. 프로젝트 클론
```bash
git clone <repository-url>
cd memory-leak-demo
```

### 2. Go 의존성 설치
```bash
go mod tidy
```

### 3. 애플리케이션 빌드
```bash
go build -o app main.go
```

### 4. Docker 이미지 빌드
```bash
docker build -t memleak:latest .
```

## 🚀 빠른 시작

### 로컬 실행
```bash
# 애플리케이션 실행
./app

# pprof 서버 접근
# http://localhost:6060/debug/pprof/
```

### 쿠버네티스 배포
```bash
# 배포 패키지 사용 (권장)
cd deploy-package
./scripts/setup-cluster.sh
./deploy.sh

# 또는 수동 배포
kubectl apply -f k8s/
```

## 🧪 테스트

### 단위 테스트
```bash
go test -v
```

### 메모리 누수 감지
```bash
chmod +x ci/leak_check.sh
./ci/leak_check.sh
```

## 📊 모니터링

### 실시간 모니터링
```bash
chmod +x scripts/monitor-memory.sh
./scripts/monitor-memory.sh
```

### 프로파일 수집
```bash
chmod +x scripts/collect-profiles.sh
./scripts/collect-profiles.sh
```

## 🔍 문제 해결

### 일반적인 문제들
1. **권한 문제**: eBPF 도구 사용 시 privileged 권한 필요
2. **포트 충돌**: 6060 포트 사용 중인지 확인
3. **이미지 로드 실패**: 클러스터 타입에 따른 이미지 로드 방법 확인

### 디버깅 명령어
```bash
# Pod 상태 확인
kubectl -n memleak-demo get all

# 로그 확인
kubectl -n memleak-demo logs -f deployment/leaky

# 이벤트 확인
kubectl -n memleak-demo get events --sort-by='.lastTimestamp'
```

## 📚 다음 단계

1. **eBPF 도구 설치**: [eBPF 가이드](eBPF%20도구%20설치%20및%20사용%20가이드.md)
2. **Prometheus + Grafana**: [모니터링 가이드](Prometheus%20+%20Grafana%20대시보드%20구축%20가이드.md)
3. **고급 진단**: [진단 도구 가이드](scripts/ebpf-memleak.sh)

## 🤝 지원

문제가 발생하거나 질문이 있으시면:
- [GitHub Issues](../../issues)에 버그 리포트
- [GitHub Discussions](../../discussions)에서 질문
- [Wiki](../../wiki)에서 상세 가이드 확인