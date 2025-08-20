# 🚨 은밀한 메모리 누수 시뮬레이션 및 eBPF 트래킹 데모

[![Docker](https://img.shields.io/badge/Docker-20.10+-2496ED.svg?logo=docker)](https://www.docker.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.20+-326CE5.svg?logo=kubernetes)](https://kubernetes.io/)
[![eBPF](https://img.shields.io/badge/eBPF-Enabled-00FF00.svg)](https://ebpf.io/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 📋 프로젝트 소개

**표준 모니터링에서는 "정상"이지만 실제로는 메모리 누수가 발생하는 서비스**를 시뮬레이션하여, eBPF 도구의 중요성을 체감할 수 있는 완전한 데모 환경입니다.

> 그때부터 진짜 문제를 추적하기 시작했다.

## 🏗️ 프로젝트 구조

```
memory-leak-demo/
├── 📚 문서
│   ├── README.md              # 이 파일
│   ├── EBPF_GUIDE.md          # eBPF 트래킹 상세 가이드
│   ├── INSTALL.md             # 설치 가이드
│   └── LICENSE                # 라이선스
├── 🔧 소스 코드
│   └── src/                   # C 소스 코드
│       ├── main_service.c     # 통합 서비스 (메인)
│       ├── healthy_service.c  # HTTP 헬스체크 서비스
│       └── fake_metrics.c     # Prometheus 메트릭 서버
├── 🐳 컨테이너
│   ├── Dockerfile             # 최적화된 Docker 이미지
│   └── docker-compose.yml     # 로컬 테스트용
├── ☸️ 쿠버네티스
│   ├── deployment.yaml        # 애플리케이션 배포
│   ├── service.yaml           # 서비스 설정
│   ├── prometheus.yaml        # Prometheus 배포
│   ├── grafana.yaml           # Grafana 배포
│   ├── namespace.yaml         # 네임스페이스
│   └── ebpf-tools.yaml        # eBPF 도구 배포
├── 📊 모니터링
│   └── grafana/               # Grafana 설정
│       ├── dashboards/        # 대시보드 정의
│       └── provisioning/      # 자동 설정
├── 🔧 스크립트
│   ├── build.sh               # 이미지 빌드 스크립트
│   ├── deploy.sh              # 배포 스크립트
│   ├── ebpf-setup.sh          # eBPF 도구 설정
│   └── cleanup.sh             # 정리 스크립트
└── 📦 eBPF 도구
    ├── inspektor-gadget.yaml  # Inspektor Gadget 설치
    └── bcc-tools/             # BCC 도구 (선택사항)
```

## 🚀 빠른 시작

### 1. 프로젝트 클론
```bash
git clone <repository-url>
cd memory-leak-demo
```

### 2. 컨테이너 이미지 빌드
```bash
./scripts/build.sh
```

### 3. 쿠버네티스에 배포
```bash
./scripts/deploy.sh
```

### 4. eBPF 도구 설정
```bash
./scripts/ebpf-setup.sh
```

### 5. 메모리 누수 트래킹
```bash
# Pod 이름 확인
kubectl -n memleak-demo get pods

# Inspektor Gadget으로 메모리 누수 추적
kubectl gadget memleak -n memleak-demo -p <pod-name>
```

## 🔧 주요 스크립트

### 빌드 및 배포
```bash
./scripts/build.sh              # Docker 이미지 빌드
./scripts/deploy.sh             # Kubernetes 배포
./scripts/cleanup.sh            # 환경 정리
```

### eBPF 설정
```bash
./scripts/ebpf-setup.sh         # eBPF 도구 설치 및 설정
```

## 📊 시뮬레이션 시나리오

### Phase 1: 표면적 정상
- **HTTP 서버**: 모든 요청에 "정상" 응답
- **Prometheus 메트릭**: 거짓 "정상" 데이터 제공
- **Grafana 대시보드**: 모든 차트가 "정상" 표시
- **헬스체크**: Liveness/ReadinessProbe 항상 통과
- **Pod 상태**: Running, 이벤트 없음

### Phase 2: 은밀한 메모리 누수
- **백그라운드 스레드**: 8초마다 1MB씩 메모리 누수
- **최대 누수량**: 2GB까지 누적
- **표면적 정상**: 모든 모니터링 도구에서 "정상" 표시

### Phase 3: 사용자 불만 증가
- **응답 지연**: 메모리 누수로 인한 성능 저하
- **사용자 경험**: 점진적 서비스 품질 저하
- **표준 모니터링**: 여전히 "정상" 신호

### Phase 4: eBPF 진단
- **Inspektor Gadget memleak**: 실시간 메모리 할당 추적
- **비정상 패턴 발견**: 할당된 메모리 회수 누락
- **누수 지점 식별**: 스택 트레이스로 정확한 위치 파악

## 🔍 eBPF 트래킹

### Inspektor Gadget memleak
```bash
# Pod 이름 확인
kubectl -n memleak-demo get pods

# 메모리 누수 추적
kubectl gadget memleak -n memleak-demo -p <pod-name>
```

### BCC memleak (노드에서 직접 실행)
```bash
# 특정 프로세스 추적
sudo /usr/share/bcc/tools/memleak -p <pid>
```

### bpftrace (노드에서 직접 실행)
```bash
# 메모리 할당 이벤트 추적
sudo bpftrace -e '
tracepoint:syscalls:sys_enter_mmap {
    printf("PID %d: mmap size=%d\n", pid, args->len);
}
'
```

## 🌍 지원하는 환경

- **로컬**: Kind, Minikube, Docker Desktop
- **클라우드**: AKS, EKS, GKE
- **엔터프라이즈**: OpenShift
- **사용자 정의**: 모든 쿠버네티스 클러스터

## 🛠️ 기술 스택

- **언어**: C (멀티스레드)
- **컨테이너**: Docker
- **오케스트레이션**: Kubernetes
- **진단**: eBPF (Inspektor Gadget, BCC, bpftrace)
- **빌드**: Docker, GCC
- **모니터링**: 커널 레벨 추적
- **대시보드**: Grafana (거짓 "정상" 데이터)

## 📚 상세 가이드

- [eBPF 트래킹 가이드](EBPF_GUIDE.md) - 상세한 eBPF 사용법
- [설치 가이드](INSTALL.md) - 단계별 설치 과정

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

---

**⚠️ 주의**: 이 데모는 교육 목적으로만 사용되어야 합니다. 실제 운영 환경에서는 신중하게 테스트하고 검증된 도구들을 사용하세요.

**🎯 목표**: 표준 모니터링의 한계를 체감하고, eBPF의 강력함을 경험하여 실제 운영 환경에서의 문제 진단 능력을 향상시키세요!

**🔍 핵심 학습**: "정상" 신호에 안주하지 말고, eBPF로 진짜 문제를 추적하세요!
