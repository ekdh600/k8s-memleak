# 🚨 메모리 누수 시뮬레이션 및 진단 데모

[![Go Version](https://img.shields.io/badge/Go-1.22+-blue.svg)](https://golang.org/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.20+-326CE5.svg?logo=kubernetes)](https://kubernetes.io/)
[![Docker](https://img.shields.io/badge/Docker-20.10+-2496ED.svg?logo=docker)](https://www.docker.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 📋 개요

이 프로젝트는 실제 운영 환경에서 발생할 수 있는 메모리 누수 시나리오를 시뮬레이션하고, eBPF 기반 진단 도구들을 사용하여 문제를 추적하는 완전한 데모 환경을 제공합니다.



## 🏗️ 아키텍처

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Go App       │    │   Kubernetes    │    │   Monitoring    │
│   (Memory      │    │   Cluster       │    │   Stack         │
│    Leak)       │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   pprof        │    │   eBPF          │    │   Prometheus    │
│   Heap Profile │    │   memleak       │    │   + Grafana     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 빠른 시작

### 1. 프로젝트 클론
```bash
git clone https://github.com/ekdh600/k8s-memleak.git
cd memory-leak-demo
```

### 2. 사전 요구사항 확인
```bash
# Go 설치 확인
go version

# Docker 설치 확인
docker --version

# kubectl 설치 확인
kubectl version --client
```

### 3. 로컬 환경에서 실행
```bash
# 의존성 설치
go mod tidy

# 애플리케이션 빌드
go build -o app main.go

# 메모리 누수 시뮬레이션 시작
./app
```

### 4. 테스트 실행
```bash
# 단위 테스트
go test -v

# 메모리 누수 감지 스크립트
chmod +x ci/leak_check.sh
./ci/leak_check.sh
```

### 5. 쿠버네티스 환경에서 실행
```bash
# 배포 패키지 사용 (권장)
cd deploy-package
./scripts/setup-cluster.sh
./deploy.sh

# 또는 수동 배포
docker build -t memleak:latest .
kubectl apply -f k8s/
```

## 🔍 진단 도구들

### 1. 표준 모니터링 (한계점 시연)
- **Prometheus**: 기본 메트릭만 수집
- **Grafana**: 대시보드에서 "정상" 표시
- **Kubernetes**: Pod 상태 Running, 이벤트 없음

### 2. eBPF 기반 진단
```bash
# Inspektor Gadget 설치
kubectl apply -f https://raw.githubusercontent.com/inspektor-gadget/inspektor-gadget/main/deploy/gadget.yaml

# 메모리 누수 추적
kubectl gadget memleak -n memleak-demo -p <pod-name>

# 진단 스크립트 실행
chmod +x scripts/ebpf-memleak.sh
./scripts/ebpf-memleak.sh
```

### 3. pprof 힙 프로파일
```bash
# 힙 프로파일 수집
curl http://localhost:6060/debug/pprof/heap > heap.pb

# 프로파일 분석
go tool pprof -top heap.pb
```

## 📊 시연 시나리오

### Phase 1: 표면적 정상
- 모든 모니터링 도구가 "정상" 신호
- Pod 상태 Running, 이벤트 없음
- 하지만 실제로는 메모리 누수 발생

### Phase 2: 문제 인식
- 사용자 불만 증가
- Pod 재시작 시 잠깐 정상, 1-2시간 후 메모리 폭증
- 표준 헬스체크는 여전히 "정상"

### Phase 3: eBPF 진단
- Inspektor Gadget memleak 도구 사용
- 실시간 메모리 할당/해제 추적
- 특정 프로세스의 비정상 패턴 발견

### Phase 4: 근본 원인 발견
- 외부 라이브러리 예외 처리 버그
- 메모리 해제 누락 패턴 식별
- 코드 수정 및 배포

## 🛠️ 기술 스택

- **언어**: Go 1.22
- **컨테이너**: Docker
- **오케스트레이션**: Kubernetes
- **모니터링**: Prometheus + Grafana
- **진단**: eBPF (Inspektor Gadget)
- **프로파일링**: pprof
- **CI/CD**: GitHub Actions

## 📚 학습 포인트

1. **표준 모니터링의 한계**: 대시보드의 "정상" 신호에 안주하지 말 것
2. **eBPF의 중요성**: 커널 레벨에서의 실시간 추적
3. **집요한 문제 추적**: 추상적 증상을 넘어 시스템 레벨까지 파고들 것
4. **자동화된 검증**: CI/CD에 메모리 누수 체크 포함

## 🔧 문제 해결

### 일반적인 문제들

1. **권한 문제**: eBPF 도구 사용 시 privileged 권한 필요
2. **이미지 로드 실패**: Kind 클러스터에 이미지 로드 확인
3. **포트 충돌**: 6060 포트 사용 중인지 확인

### 디버깅 명령어

```bash
# Pod 로그 확인
kubectl -n memleak-demo logs -f deployment/leaky

# Pod 상태 상세 확인
kubectl -n memleak-demo describe pod -l app=leaky

# 메모리 사용량 확인
kubectl -n memleak-demo exec -it $(kubectl -n memleak-demo get pod -l app=leaky -o jsonpath='{.items[0].metadata.name}') -- top
```

## 📈 성능 지표

- **메모리 누수 속도**: 1MB/5초
- **탐지 임계값**: 20MB (RSS 증가)
- **pprof 수집 주기**: 10초
- **eBPF 추적 시간**: 5분

## 🚀 다른 클러스터에서 사용

### 1. Git을 통한 배포
```bash
# 원격 저장소에서 클론
git clone <repository-url>
cd memory-leak-demo

# 배포 패키지 사용
cd deploy-package
./scripts/setup-cluster.sh
./deploy.sh
```

### 2. 지원하는 클러스터 타입
- **로컬**: Kind, Minikube, Docker Desktop
- **클라우드**: AKS, EKS, GKE
- **엔터프라이즈**: OpenShift
- **사용자 정의**: 사용자 정의 클러스터

### 3. 자동화된 배포
- 클러스터 타입 자동 감지
- 환경별 최적화된 설정
- 원클릭 배포 및 정리

## 📁 프로젝트 구조

```
memory-leak-demo/
├── README.md                 # 이 파일
├── main.go                   # 메인 애플리케이션
├── leak_test.go             # 테스트 파일
├── go.mod                   # Go 모듈 정의
├── Dockerfile               # Docker 이미지 정의
├── Makefile                 # 빌드 및 배포 명령어
├── ci/                      # CI/CD 스크립트
│   └── leak_check.sh       # 메모리 누수 감지
├── scripts/                  # 유틸리티 스크립트
│   ├── ebpf-memleak.sh     # eBPF 진단
│   └── monitor-memory.sh   # 메모리 모니터링
├── k8s/                     # 쿠버네티스 매니페스트
│   ├── namespace.yaml       # 네임스페이스
│   ├── deployment.yaml      # 애플리케이션 배포
│   ├── service.yaml         # 서비스
│   ├── ingress.yaml         # 인그레스
│   └── prometheus-config.yaml # Prometheus 설정
├── deploy-package/           # 배포 패키지
│   ├── deploy.sh            # 메인 배포 스크립트
│   ├── scripts/             # 배포 관련 스크립트
│   └── k8s/                 # 쿠버네티스 매니페스트
└── .github/                  # GitHub Actions
    └── workflows/            # CI/CD 워크플로우
        └── leak-check.yml   # 메모리 누수 체크
```

## 🤝 기여하기

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 `LICENSE` 파일을 참조하세요.

## 🙏 감사의 말

- [Inspektor Gadget](https://github.com/inspektor-gadget/inspektor-gadget) - eBPF 기반 진단 도구
- [Go pprof](https://pkg.go.dev/runtime/pprof) - Go 프로파일링 도구
- [Kubernetes](https://kubernetes.io/) - 컨테이너 오케스트레이션

## 📞 지원 및 문제 해결

### 이슈 리포트
GitHub Issues를 통해 버그 리포트나 기능 요청을 해주세요.

### 토론
GitHub Discussions에서 질문이나 아이디어를 공유해주세요.

### 문서
자세한 사용법은 [Wiki](../../wiki)를 참조하세요.

---

**⚠️ 주의**: 이 데모는 교육 목적으로만 사용되어야 합니다. 실제 운영 환경에서는 신중하게 테스트하고 검증된 도구들을 사용하세요.