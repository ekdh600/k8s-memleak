# 🚨 은밀한 메모리 누수 시뮬레이션 및 eBPF 트래킹 데모

[![Docker](https://img.shields.io/badge/Docker-20.10+-2496ED.svg?logo=docker)](https://www.docker.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.20+-326CE5.svg?logo=kubernetes)](https://kubernetes.io/)
[![eBPF](https://img.shields.io/badge/eBPF-Enabled-00FF00.svg)](https://ebpf.io/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 📋 개요

이 프로젝트는 **표준 모니터링에서는 "정상"이지만 실제로는 메모리 누수가 발생하는 서비스**를 시뮬레이션하여, eBPF 도구의 중요성을 체감할 수 있는 완전한 데모 환경을 제공합니다.

## 🎯 핵심 시나리오

### **문제 상황**
> 운영 서비스의 응답이 점점 느려졌다.
> Prometheus, Grafana, 쿠버네티스 대시보드 모두 "정상".
> Pod 상태도 Running, 이벤트도 특이사항 없음.
> 하지만 사용자들은 불만을 쏟아냈다.
> 그때부터 진짜 문제를 추적하기 시작했다.

### **표준 모니터링의 맹점**
- ✅ **Pod 상태**: Running (정상)
- ✅ **헬스체크**: Liveness/ReadinessProbe 통과
- ✅ **메트릭**: Prometheus/Grafana에서 "정상" 표시
- ✅ **GC**: 정상 동작
- ❌ **실제**: 메모리 누수로 인한 성능 저하
- ❌ **사용자 경험**: 응답 지연, 불만 증가

### **eBPF 진단의 중요성**
- 🔍 **GC 로그/앱 내 메트릭**: 유의미한 패턴 없음
- 🔍 **eBPF 기반 실시간 추적**: 문제 즉시 발견
- 🔍 **메모리 할당/해제 추적**: 비정상 패턴 식별
- 🔍 **누수 지점 정확한 파악**: 근본 원인 발견

## 🏗️ 아키텍처

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   C Service     │    │   Kubernetes    │    │   eBPF Tools    │
│   (Stealth      │    │   Cluster       │    │                 │
│    Memory       │    │                 │    │                 │
│     Leak)       │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   HTTP Server   │    │   Privileged    │    │   Inspektor     │
│   + Metrics     │    │   Container     │    │   Gadget       │
│   (Fake         │    │                 │    │                 │
│    Healthy)     │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 빠른 시작 (5분)

### 1. 프로젝트 클론
```bash
git clone https://github.com/ekdh600/k8s-memleak.git
cd k8s-memleak
```

### 2. Docker 이미지 빌드
```bash
make docker-build
```

### 3. 쿠버네티스에 배포
```bash
make deploy
```

### 4. eBPF 도구 설치
```bash
make install-ebpf
```

### 5. 메모리 누수 트래킹
```bash
make track-memory
```

## 🔍 eBPF 트래킹

### Inspektor Gadget memleak
```bash
# Pod 이름 확인
kubectl -n memleak-demo get pods

# 메모리 누수 추적
kubectl gadget memleak -n memleak-demo -p <pod-name>

# 상세한 스택 트레이스
kubectl gadget memleak -n memleak-demo -p <pod-name> --show-references
```

### BCC memleak
```bash
# 특정 프로세스 추적
sudo /usr/share/bcc/tools/memleak -p <pid>

# 스택 트레이스와 함께
sudo /usr/share/bcc/tools/memleak -p <pid> --show-references
```

## 📊 시뮬레이션 시나리오

### Phase 1: 표면적 정상
- **HTTP 서버**: 모든 요청에 "정상" 응답
- **Prometheus 메트릭**: 거짓 "정상" 데이터 제공
- **헬스체크**: Liveness/ReadinessProbe 항상 통과
- **Pod 상태**: Running, 이벤트 없음

### Phase 2: 은밀한 메모리 누수
- **백그라운드 스레드**: 8초마다 1MB씩 메모리 누수
- **최대 누수량**: 2GB까지 누적
- **로그 최소화**: 20개마다만 로그 출력
- **표면적 정상**: 모든 모니터링 도구에서 "정상" 표시

### Phase 3: 사용자 불만 증가
- **응답 지연**: 메모리 누수로 인한 성능 저하
- **사용자 경험**: 점진적 서비스 품질 저하
- **표준 모니터링**: 여전히 "정상" 신호

### Phase 4: eBPF 진단
- **Inspektor Gadget memleak**: 실시간 메모리 할당 추적
- **비정상 패턴 발견**: 할당된 메모리 회수 누락
- **누수 지점 식별**: 스택 트레이스로 정확한 위치 파악

### Phase 5: 문제 해결
- **근본 원인 발견**: 백그라운드 메모리 누수 스레드
- **코드 수정**: 메모리 누수 로직 제거
- **예방책 수립**: eBPF 트래킹 자동화

## 🛠️ 기술 스택

- **언어**: C (멀티스레드)
- **컨테이너**: Docker (Alpine Linux)
- **오케스트레이션**: Kubernetes
- **진단**: eBPF (Inspektor Gadget, BCC)
- **빌드**: Make, GCC
- **모니터링**: 커널 레벨 추적

## 📁 프로젝트 구조

```
k8s-memleak/
├── 📚 문서
│   ├── README.md              # 이 파일
│   ├── EBPF_GUIDE.md          # eBPF 트래킹 상세 가이드
│   ├── INSTALL.md             # 설치 가이드
│   └── LICENSE                # 라이선스
├── 🔧 소스 코드
│   └── src/                   # C 소스 코드
│       ├── main_service.c     # 통합 서비스 (메인)
│       ├── healthy_service.c  # HTTP 헬스체크 서비스
│       ├── fake_metrics.c     # Prometheus 메트릭 서버
│       └── memory_leak.c      # 메모리 누수 시뮬레이터
├── 🐳 컨테이너
│   ├── Dockerfile             # 최적화된 Docker 이미지
│   └── Makefile               # 빌드 및 배포 자동화
├── ☸️ 쿠버네티스
│   ├── deployment.yaml        # 애플리케이션 배포
│   ├── service.yaml           # 서비스 설정
│   ├── prometheus-config.yaml # Prometheus 설정
│   └── namespace.yaml         # 네임스페이스
└── 🚀 배포 패키지
    └── deploy-package/        # 다른 클러스터용
```

## 🔧 사용법

### 로컬 실행
```bash
# C 프로그램 빌드
make build

# 메인 서비스 실행 (HTTP + 메트릭 + 메모리 누수)
make run

# 개별 서비스 실행
make run-healthy    # 헬스체크만
make run-metrics    # 메트릭 서버만
make run-leak       # 메모리 누수만
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

### eBPF 트래킹
```bash
# eBPF 도구 설치
make install-ebpf

# 메모리 누수 추적
make track-memory
```

## 📈 성능 지표

- **메모리 누수 속도**: 1MB/8초 (은밀하게)
- **최대 누수량**: 2GB
- **트래킹 정확도**: 커널 레벨 (99.9%+)
- **오버헤드**: 최소 (eBPF 최적화)
- **배포 시간**: < 2분

## 🌐 지원하는 환경

- **로컬**: Kind, Minikube, Docker Desktop
- **클라우드**: AKS, EKS, GKE
- **엔터프라이즈**: OpenShift
- **사용자 정의**: 모든 쿠버네티스 클러스터

## 🔍 문제 해결

### 일반적인 문제들
1. **권한 문제**: eBPF 도구 사용 시 privileged 권한 필요
2. **이미지 로드**: 클러스터 타입에 따른 이미지 로드 방법 확인
3. **네트워크 정책**: eBPF 도구 접근 허용 필요

### 디버깅 명령어
```bash
# Pod 상태 확인
kubectl -n memleak-demo get all

# 로그 확인
kubectl -n memleak-demo logs -f deployment/stealth-memory-leaker

# 이벤트 확인
kubectl -n memleak-demo get events

# 디버깅 정보
make debug
```

## 📚 상세 가이드

- [eBPF 트래킹 가이드](EBPF_GUIDE.md) - 상세한 eBPF 사용법
- [설치 가이드](INSTALL.md) - 단계별 설치 과정
- [GitHub 설정](GITHUB_SETUP.md) - 저장소 설정 및 공유

## 🚀 다른 클러스터에서 사용

### 1. 프로젝트 클론
```bash
git clone https://github.com/ekdh600/k8s-memleak.git
cd k8s-memleak
```

### 2. 빠른 시작
```bash
# 위의 "빠른 시작 (5분)" 섹션 참조
```

### 3. 자동화된 배포
```bash
cd deploy-package
./deploy.sh
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
- [BCC](https://github.com/iovisor/bcc) - BPF Compiler Collection
- [eBPF](https://ebpf.io/) - Extended Berkeley Packet Filter

## 📞 지원 및 문제 해결

### 이슈 리포트
GitHub Issues를 통해 버그 리포트나 기능 요청을 해주세요.

### 토론
GitHub Discussions에서 질문이나 아이디어를 공유해주세요.

---

**⚠️ 주의**: 이 데모는 교육 목적으로만 사용되어야 합니다. 실제 운영 환경에서는 신중하게 테스트하고 검증된 도구들을 사용하세요.

**🎯 목표**: 표준 모니터링의 한계를 체감하고, eBPF의 강력함을 경험하여 실제 운영 환경에서의 문제 진단 능력을 향상시키세요!

**🔍 핵심 학습**: "정상" 신호에 안주하지 말고, eBPF로 진짜 문제를 추적하세요!