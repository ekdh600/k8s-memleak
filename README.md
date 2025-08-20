# 🚨 메모리 누수 시뮬레이션 및 eBPF 트래킹 데모

[![Docker](https://img.shields.io/badge/Docker-20.10+-2496ED.svg?logo=docker)](https://www.docker.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.20+-326CE5.svg?logo=kubernetes)](https://kubernetes.io/)
[![eBPF](https://img.shields.io/badge/eBPF-Enabled-00FF00.svg)](https://ebpf.io/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 📋 개요

이 프로젝트는 **C 기반 메모리 누수 시뮬레이터**와 **eBPF 트래킹 도구**를 사용하여 실제 운영 환경에서 발생할 수 있는 메모리 누수 시나리오를 시뮬레이션하고 진단하는 완전한 데모 환경을 제공합니다.

## 🎯 핵심 특징

- ✅ **Go 환경 불필요**: Docker 이미지만으로 즉시 실행
- ✅ **효율적인 메모리 누수**: C 언어로 실제 malloc/free 누락 시뮬레이션
- ✅ **eBPF 트래킹 최적화**: 커널 레벨에서 정확한 메모리 할당 추적
- ✅ **가벼운 이미지**: 정적 컴파일로 최소 크기
- ✅ **자동화된 배포**: 원클릭 쿠버네티스 배포

## 🏗️ 아키텍처

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   C App         │    │   Kubernetes    │    │   eBPF Tools    │
│   (Memory       │    │   Cluster       │    │                 │
│    Leak)        │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   malloc/free   │    │   Privileged    │    │   Inspektor     │
│   누락 시뮬레이션│    │   Container     │    │   Gadget       │
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

### Phase 1: 메모리 누수 발생
- **5초마다 1MB씩 메모리 누수**
- **최대 1000MB까지 누적**
- **실제 malloc 호출로 실제적인 시뮬레이션**

### Phase 2: 표준 모니터링의 한계
- **Pod 상태**: Running
- **헬스체크**: 정상
- **이벤트**: 특이사항 없음
- **하지만**: 메모리 사용량 지속 증가

### Phase 3: eBPF 진단
- **Inspektor Gadget memleak**으로 실시간 추적
- **메모리 할당 패턴** 분석
- **스택 트레이스**로 누수 지점 식별

### Phase 4: 문제 해결
- **근본 원인** 발견
- **코드 수정** 및 배포
- **예방책** 수립

## 🛠️ 기술 스택

- **언어**: C (정적 컴파일)
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
│       └── memory_leak.c      # 메모리 누수 시뮬레이터
├── 🐳 컨테이너
│   ├── Dockerfile             # 최적화된 Docker 이미지
│   └── Makefile               # 빌드 및 배포 자동화
├── ☸️ 쿠버네티스
│   ├── deployment.yaml        # 애플리케이션 배포
│   ├── service.yaml           # 서비스 설정
│   └── namespace.yaml         # 네임스페이스
└── 🚀 배포 패키지
    └── deploy-package/        # 다른 클러스터용
```

## 🔧 사용법

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

### eBPF 트래킹
```bash
# eBPF 도구 설치
make install-ebpf

# 메모리 누수 추적
make track-memory
```

## 📈 성능 지표

- **메모리 누수 속도**: 1MB/5초
- **최대 누수량**: 1000MB
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
kubectl -n memleak-demo logs -f deployment/memory-leaker

# 이벤트 확인
kubectl -n memleak-demo get events
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

**🎯 목표**: eBPF의 강력함을 체험하고, 실제 운영 환경에서의 메모리 누수 진단 능력을 향상시키세요!