# 🌍 환경별 최소 설치 가이드

## 📋 핵심 원칙

**🎯 목표**: 시나리오 구동 가능한 최소한의 환경만 구성
**🚫 제한**: 방화벽, AppArmor 등 호스트 예민 부분은 건드리지 않음
**🔧 범위**: 개발 도구, 컨테이너, 쿠버네티스, eBPF 도구만 설치

## 📋 RHEL 8 환경

### 사전 요구사항 확인
```bash
# RHEL 8 버전 확인
cat /etc/redhat-release

# 커널 버전 확인 (eBPF 지원 확인)
uname -r

# 기본 도구 확인
which make gcc kubectl docker

# SELinux 상태 확인 (읽기 전용)
getenforce
```

### 최소 환경 구성 (자동)
```bash
# 자동 설치 스크립트 실행
sudo ./scripts/install-rhel8.sh

# 또는 Makefile 사용
make install-rhel8
```

### 최소 환경 구성 (수동)
```bash
# 시스템 업데이트 (커널, 방화벽, AppArmor 제외)
sudo dnf update -y --exclude="kernel*" --exclude="firewalld*" --exclude="apparmor*"

# 개발 도구 설치 (최소한만)
sudo dnf install -y \
    gcc \
    gcc-c++ \
    make \
    git \
    curl \
    wget

# kubectl 설치
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# eBPF 도구 설치 (최소한만)
sudo dnf install -y bcc-tools

# 최소한의 SELinux 설정 (컨테이너 실행만 허용)
sudo setsebool -P container_manage_cgroup 1
```

### 설치 후 확인
```bash
# 환경 정보 확인
make env-info

# 설치된 도구 확인
which gcc make kubectl
ls /usr/share/bcc/tools/memleak
```

## 🐧 Ubuntu/Debian 환경

### 사전 요구사항 확인
```bash
# Ubuntu 버전 확인
cat /etc/os-release

# 커널 버전 확인 (eBPF 지원 확인)
uname -r

# 기본 도구 확인
which make gcc kubectl docker
```

### 최소 환경 구성 (자동)
```bash
# 자동 설치 스크립트 실행
sudo ./scripts/install-ubuntu.sh

# 또는 Makefile 사용
make install-ubuntu
```

### 최소 환경 구성 (수동)
```bash
# 시스템 업데이트
sudo apt update
sudo apt upgrade -y

# 개발 도구 설치 (최소한만)
sudo apt install -y \
    build-essential \
    gcc \
    gcc-multilib \
    make \
    git \
    curl \
    wget

# kubectl 설치
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# eBPF 도구 설치 (최소한만)
sudo apt install -y bpfcc-tools
```

### 설치 후 확인
```bash
# 환경 정보 확인
make env-info

# 설치된 도구 확인
which gcc make kubectl
ls /usr/share/bcc/tools/memleak
```

## 🍎 macOS 환경

### 사전 요구사항 확인
```bash
# macOS 버전 확인
sw_vers -productVersion

# 기본 도구 확인
which make gcc kubectl docker
```

### 최소 환경 구성 (수동)
```bash
# Homebrew 설치 (없는 경우)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 개발 도구 설치
brew install \
    make \
    gcc \
    git \
    curl \
    wget

# kubectl 설치
brew install kubectl

# Docker Desktop 설치
brew install --cask docker
```

### 설치 후 확인
```bash
# 환경 정보 확인
make env-info

# 설치된 도구 확인
which gcc make kubectl
docker --version
```

## 🐳 컨테이너 환경

### Docker-in-Docker
```bash
# Docker 컨테이너 내에서 실행
docker run --privileged -it \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $(pwd):/workspace \
    ubuntu:20.04

# 컨테이너 내부에서 설치
apt update && apt install -y make gcc git curl
```

### Podman (RHEL 8 기본)
```bash
# Podman 설치 확인
which podman

# Docker 호환 모드 활성화 (선택사항)
sudo podman system connection add docker-daemon unix:///var/run/docker.sock

# Docker 명령어로 Podman 사용
alias docker=podman
```

## 🔧 환경별 Makefile 설정

### 자동 환경 감지
```makefile
# 환경별 자동 감지
ifeq ($(shell grep -c "Red Hat Enterprise Linux 8" /etc/redhat-release 2>/dev/null),1)
    PLATFORM := rhel8
    INSTALL_SCRIPT := scripts/install-rhel8.sh
    EBPF_TOOLS := bcc-tools
else ifeq ($(shell grep -c "Ubuntu" /etc/os-release 2>/dev/null),1)
    PLATFORM := ubuntu
    INSTALL_SCRIPT := scripts/install-ubuntu.sh
    EBPF_TOOLS := bpfcc-tools
else
    PLATFORM := generic
    INSTALL_SCRIPT := scripts/install-generic.sh
    EBPF_TOOLS := generic-ebpf
endif
```

### 환경별 설치 명령어
```makefile
# 환경별 자동 설치
install: ## 환경별 최소 환경 구성 (자동 감지)
	@echo "🔧 환경별 최소 환경 구성 중..."
	@echo "🌍 감지된 환경: $(PLATFORM)"
	@echo "📦 사용할 스크립트: $(INSTALL_SCRIPT)"
	@sudo $(INSTALL_SCRIPT)

# RHEL 8 전용 설치
install-rhel8: ## RHEL 8 최소 환경 구성
	@sudo ./scripts/install-rhel8.sh

# Ubuntu 전용 설치
install-ubuntu: ## Ubuntu 최소 환경 구성
	@sudo ./scripts/install-ubuntu.sh
```

## 🚨 환경별 주의사항

### RHEL 8
- **SELinux**: 최소한의 컨테이너 권한만 설정
- **AppArmor**: 수동 설정 필요 (스크립트에서 건드리지 않음)
- **방화벽**: 수동 설정 필요 (스크립트에서 건드리지 않음)
- **커널**: eBPF 지원 버전 확인
- **패키지**: dnf 사용, yum 대체

### Ubuntu/Debian
- **apt**: 패키지 매니저 사용
- **커널**: 4.18+ 필요
- **권한**: sudo 설정 확인
- **AppArmor**: 수동 설정 필요 (스크립트에서 건드리지 않음)
- **방화벽**: 수동 설정 필요 (스크립트에서 건드리지 않음)

### macOS
- **eBPF 제한**: Linux 환경 권장
- **Homebrew**: 패키지 매니저
- **Docker Desktop**: 가상화 환경

## 🔍 환경 확인 스크립트

### 환경 감지 스크립트
```bash
#!/bin/bash
# detect-environment.sh

echo "🔍 환경 감지 중..."

# OS 감지
if [[ -f /etc/redhat-release ]]; then
    OS="RHEL/CentOS"
    VERSION=$(cat /etc/redhat-release)
elif [[ -f /etc/debian_version ]]; then
    OS="Debian/Ubuntu"
    VERSION=$(cat /etc/debian_version)
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macOS"
    VERSION=$(sw_vers -productVersion)
else
    OS="Unknown"
    VERSION="Unknown"
fi

echo "OS: $OS"
echo "Version: $VERSION"

# 커널 버전 확인
if [[ "$OS" != "macOS" ]]; then
    KERNEL=$(uname -r)
    echo "Kernel: $KERNEL"
    
    # eBPF 지원 확인
    if [[ "$KERNEL" > "4.18" ]]; then
        echo "✅ eBPF 지원됨"
    else
        echo "❌ eBPF 지원 안됨 (커널 4.18+ 필요)"
    fi
fi

# 도구 확인
echo ""
echo "🔧 도구 확인:"
which make gcc kubectl docker 2>/dev/null || echo "일부 도구가 설치되지 않음"

# 권한 확인 (읽기 전용)
echo ""
echo "🔐 권한 확인 (읽기 전용):"
if [[ "$OS" == "RHEL/CentOS" ]]; then
    getenforce
    echo "컨테이너 권한:"
    getsebool container_manage_cgroup 2>/dev/null || echo "SELinux 도구 없음"
fi
```

## 🚀 빠른 시작

### 1. 환경별 자동 설치
```bash
# RHEL 8
sudo ./scripts/install-rhel8.sh

# Ubuntu
sudo ./scripts/install-ubuntu.sh

# 또는 Makefile 사용
make install
```

### 2. 프로젝트 실행
```bash
# 프로젝트 클론
git clone https://github.com/ekdh600/k8s-memleak.git
cd k8s-memleak

# 빌드 및 배포
make build
make deploy
```

### 3. 환경 정보 확인
```bash
# 환경 정보 출력
make env-info

# 설치된 도구 확인
which gcc make kubectl
```

## ⚠️ 중요 주의사항

### 🚫 스크립트에서 건드리지 않는 것들
- **방화벽 설정** (firewalld, ufw, iptables)
- **AppArmor 정책**
- **SELinux 정책** (최소한의 컨테이너 권한만)
- **네트워크 정책**
- **시스템 보안 설정**
- **커널 모듈 로딩**
- **시스템 서비스 설정**

### ✅ 스크립트에서 설치하는 것들
- **개발 도구** (gcc, make, git)
- **컨테이너 도구** (Docker/Podman 확인만)
- **쿠버네티스 도구** (kubectl)
- **eBPF 도구** (bcc-tools, bpfcc-tools)
- **기본 유틸리티** (curl, wget)

### 🔧 수동 설정이 필요한 것들
- **방화벽 포트 열기** (8080, 9090, 3000)
- **AppArmor 정책 설정**
- **네트워크 정책 설정**
- **보안 그룹 설정**
- **컨테이너 런타임 설정**

---

**💡 팁**: 환경별 자동 감지로 최적의 설치 방법을 제공하지만, 호스트의 예민한 부분은 수동으로 설정해야 합니다!

**🎯 목표**: 시나리오 구동에 필요한 최소한의 환경만 구성하여 안전하고 효율적인 설치를 제공합니다!