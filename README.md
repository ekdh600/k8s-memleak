# 🚨 파드 메모리 누수 eBPF 트래킹 데모

[![Docker](https://img.shields.io/badge/Docker-20.10+-2496ED.svg?logo=docker)](https://www.docker.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.20+-326CE5.svg?logo=kubernetes)](https://kubernetes.io/)
[![eBPF](https://img.shields.io/badge/eBPF-Enabled-00FF00.svg)](https://ebpf.io/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 📋 프로젝트 소개

**쿠버네티스 파드에서 발생하는 메모리 누수를 eBPF 도구로 진단하는 실습 환경**입니다.

### 🎯 **타겟 시나리오**

1. **표면적 정상**: 모든 모니터링 도구에서 "정상" 신호
2. **은밀한 누수**: 백그라운드에서 8초마다 1MB씩 메모리 누수
3. **누적 효과**: 최대 2GB까지 메모리 누수 발생
4. **성능 저하**: 점진적인 서비스 품질 저하

### 🔍 **어떻게 확인하는가?**

- **표준 모니터링**: Grafana, Prometheus, 헬스체크 모두 "정상"
- **eBPF 도구**: Inspektor Gadget, BCC, bpftrace로 실제 누수 감지
- **실시간 추적**: 메모리 할당/해제 패턴 분석
- **스택 트레이스**: 정확한 누수 지점 식별

> **핵심 학습**: 표준 모니터링의 한계를 체감하고, eBPF의 강력함을 경험하세요!

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
│   ├── Dockerfile             # GCC 기반 멀티스테이지 빌드
│   └── docker-compose.yml     # 로컬 테스트용
├── ☸️ 쿠버네티스
│   ├── deployment.yaml        # 애플리케이션 배포
│   ├── service.yaml           # 서비스 설정
│   ├── prometheus.yaml        # Prometheus 배포
│   ├── grafana.yaml           # Grafana 배포
│   ├── namespace.yaml         # 네임스페이스
│   └── inspektor-gadget.yaml # eBPF 도구 설치
├── 📊 모니터링
│   └── grafana/               # Grafana 설정
│       ├── dashboards/        # 커스텀 대시보드
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
git clone https://github.com/ekdh600/k8s-memleak.git
cd k8s-memleak
```

### 2. 통합 빌드 및 배포 (권장)
```bash
# 🏠 로컬 registry 사용 (기본값)
./scripts/build-and-deploy.sh

# 🐳 Docker Hub 사용
./scripts/build-and-deploy.sh --docker-hub

# 🏷️ 사용자 정의 이미지 이름
./scripts/build-and-deploy.sh --image-name my-image:v1.0
```

### 3. 단계별 빌드 및 배포
```bash
# 1단계: Docker 이미지 빌드
./scripts/build.sh

# 2단계: 이미지 변환 (로컬 사용 시)
# 방법: 직접 import (권장)
./scripts/convert-image.sh

# 3단계: Kubernetes 배포
./scripts/deploy.sh memory-leak-demo:latest
```

### 4. 로컬 이미지 사용 방법
```bash
# ✅ 올바른 방법: 직접 import
./scripts/import-image.sh
./scripts/deploy.sh memory-leak-demo:latest

# 또는 통합 스크립트 사용
./scripts/build-and-deploy.sh
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
./scripts/build.sh              # Docker 이미지 빌드 (GCC 기반)
./scripts/deploy.sh             # Kubernetes 배포
./scripts/cleanup.sh            # 환경 정리
```

### eBPF 설정
```bash
./scripts/ebpf-setup.sh         # eBPF 도구 설치 및 설정
```

## 📊 시뮬레이션 시나리오

### Phase 1: 표면적 정상 (0-30초)
- **HTTP 서버**: 모든 요청에 "정상" 응답
- **Prometheus 메트릭**: 거짓 "정상" 데이터 제공
- **Grafana 대시보드**: 모든 차트가 "정상" 표시
- **헬스체크**: Liveness/ReadinessProbe 항상 통과
- **Pod 상태**: Running, 이벤트 없음

### Phase 2: 은밀한 메모리 누수 (30초-30분)
- **백그라운드 스레드**: 8초마다 1MB씩 메모리 누수
- **누적량**: 30분 후 약 225MB 누적
- **표면적 정상**: 모든 모니터링 도구에서 "정상" 표시
- **Grafana**: 메모리 사용량이 "정상" 범위로 표시

### Phase 3: 성능 저하 (30분-1시간)
- **응답 지연**: 메모리 누수로 인한 성능 저하
- **사용자 경험**: 점진적 서비스 품질 저하
- **표준 모니터링**: 여전히 "정상" 신호
- **Grafana**: 거짓 메트릭으로 "정상" 유지

### Phase 4: eBPF 진단 (실시간)
- **Inspektor Gadget memleak**: 실시간 메모리 할당 추적
- **비정상 패턴 발견**: 할당된 메모리 회수 누락
- **누수 지점 식별**: 스택 트레이스로 정확한 위치 파악
- **실제 메모리 사용량**: 표준 모니터링과의 차이점 확인

## 🔍 eBPF 트래킹 방법

### Inspektor Gadget 사용 (권장)
```bash
# Pod 이름 확인
kubectl -n memleak-demo get pods

# 메모리 누수 추적 시작
kubectl gadget memleak -n memleak-demo -p <pod-name>

# 출력 예시
Allocated memory:
  PID: 12345
  Size: 1048576 bytes (1MB)
  Stack trace:
    malloc+0x1a
    memory_leak_thread+0x45
    start_thread+0x87
```

### BCC memleak 사용 (노드에서 직접 실행)
```bash
# Pod의 PID 확인
kubectl -n memleak-demo exec <pod-name> -- ps aux

# 메모리 누수 추적
sudo /usr/share/bcc/tools/memleak -p <pid>

# 전체 시스템 메모리 누수 추적
sudo /usr/share/bcc/tools/memleak
```

### bpftrace 사용 (노드에서 직접 실행)
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

## 🎨 Grafana 대시보드

### 자동 설정
- **대시보드**: `grafana/dashboards/stealth-memory-leak.json`
- **데이터 소스**: `grafana/provisioning/datasources/prometheus.yaml`
- **자동 로드**: `grafana/provisioning/dashboards/dashboards.yaml`

### 주요 패널
1. **서비스 헬스 상태**: 항상 "Healthy" 표시
2. **메모리 사용량**: 거짓 "정상" 범위로 표시
3. **HTTP 요청 수**: 정상적인 요청 패턴
4. **응답 시간**: 점진적 지연 (숨겨짐)

### 접속 방법
```bash
# 포트포워딩
kubectl -n memleak-demo port-forward svc/grafana 3000:3000

# 브라우저에서 접속
# http://localhost:3000 (admin/admin)
```

## 🔧 GCC 빌드 과정

### 멀티스테이지 빌드
```dockerfile
# 1단계: GCC 컴파일러로 C 소스 빌드
FROM gcc:11 as builder
RUN gcc -O2 -static -s -pthread -o main_service main_service.c

# 2단계: 실행 이미지 (Alpine Linux)
FROM alpine:3.18
COPY --from=builder /app/main_service .
```

### 컴파일 옵션
- **-O2**: 최적화 레벨 2
- **-static**: 정적 링킹
- **-s**: 심볼 정보 제거
- **-pthread**: 멀티스레드 지원

### 빌드 결과물
- `main_service`: 메인 서비스 (메모리 누수 시뮬레이션)
- `healthy_service`: 헬스체크 서비스
- `fake_metrics`: 거짓 메트릭 서버

## 🌍 지원하는 환경

- **로컬**: Kind, Minikube, Docker Desktop
- **클라우드**: AKS, EKS, GKE
- **엔터프라이즈**: OpenShift
- **사용자 정의**: 모든 쿠버네티스 클러스터

## 🛠️ 기술 스택

- **언어**: C (멀티스레드)
- **컨테이너**: Docker (GCC 기반 멀티스테이지 빌드)
- **오케스트레이션**: Kubernetes
- **진단**: eBPF (Inspektor Gadget, BCC, bpftrace)
- **빌드**: GCC 11, Docker
- **모니터링**: 커널 레벨 추적
- **대시보드**: Grafana (거짓 "정상" 데이터)

## 📚 상세 가이드

- [eBPF 트래킹 가이드](EBPF_GUIDE.md) - 상세한 eBPF 사용법
- [설치 가이드](INSTALL.md) - 단계별 설치 과정
- [테스트 가이드](TESTING.md) - 상세한 테스트 방법

## 🧪 테스트 방법

### 🎯 테스트 목표
1. **정상적으로 보이는 화면/메트릭/GCC 확인**
2. **eBPF를 통한 실제 메모리 누수 확인**

### ✅ 1단계: 정상 모니터링 확인

#### HTTP 헬스체크 테스트
```bash
# 컨테이너 실행
docker run --rm -d --name memory-leak-test \
  -p 8080:8080 -p 9090:9090 \
  memory-leak-demo:latest

# 헬스체크 확인 (항상 "healthy" 반환)
curl -s http://localhost:8080/health | jq .
```

#### Prometheus 메트릭 확인
```bash
# 메트릭 엔드포인트 (모든 지표가 "정상"으로 표시)
curl -s http://localhost:9090/metrics | grep -E "(http_requests_total|memory_leak)"
```

#### GCC 컴파일 테스트
```bash
# 소스 코드 컴파일 성공 확인
docker run --rm -v $(pwd)/src:/src gcc:11 bash -c "
  cd /src && 
  gcc -O2 -static -s -pthread -o test_main main_service.c fake_metrics.c &&
  echo '✅ GCC 컴파일 성공'
"
```

### 🔍 2단계: eBPF로 실제 메모리 누수 확인

#### Inspektor Gadget 설치
```bash
# Kubernetes 환경에서
kubectl apply -f k8s/inspektor-gadget.yaml

# 메모리 누수 추적
kubectl gadget memleak -n memleak-demo -p <pod-name>
```

#### BCC 도구로 노드 레벨 추적
```bash
# 노드에 접속하여 메모리 할당/해제 패턴 추적
kubectl debug node/<node-name> -it --image=ubuntu:20.04

# BCC 설치 및 메모리 추적
apt install -y python3-bpfcc
python3 -c "
from bcc import BPF
# 메모리 할당/해제 추적 코드
"
```

#### bpftrace 고급 추적
```bash
# bpftrace 스크립트로 메모리 누수 패턴 분석
cat > memleak.bt << 'EOF'
#!/usr/bin/env bpftrace
uprobe:libc:malloc { @size[pid] = arg1; @count[pid]++; }
uprobe:libc:free { @count[pid]--; }
END { print(@count); print(@total); }
EOF

bpftrace memleak.bt
```

### 📊 예상 결과

#### 표준 모니터링 (거짓 "정상")
```json
{
  "status": "healthy",
  "metrics": {
    "memory_usage_percent": 1,
    "memory": "normal",
    "gc": "healthy"
  }
}
```

#### eBPF 추적 (진짜 문제)
```
🔍 메모리 누수 추적 결과:
PID 1234: malloc 1,000+ 회, free 50회 미만
누적 메모리: 1.5GB+, 메모리 누수율: 95%+
🚨 경고: 심각한 메모리 누수 감지!
```

### 🎭 위장 효과 검증
- **Grafana**: 모든 지표 "정상" 표시
- **Prometheus**: 정상적인 메트릭 값
- **헬스체크**: 항상 "passing" 상태
- **eBPF**: 실제 메모리 누수 패턴 감지

> **핵심**: 표준 모니터링은 완벽하게 속이고, eBPF만이 진실을 보여줍니다!

---

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

**🎯 목표**: 쿠버네티스 파드의 은밀한 메모리 누수를 eBPF로 진단하여, 표준 모니터링의 한계와 eBPF의 강력함을 체험하세요!

**🔍 핵심 학습**: 
1. **표면적 정상**에 안주하지 말고
2. **eBPF로 진짜 문제**를 추적하세요
3. **Grafana의 거짓 메트릭**을 eBPF로 폭로하세요
