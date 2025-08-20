#!/bin/bash

# 🔧 RHEL 8 최소 환경 구성 스크립트
# 은밀한 메모리 누수 시뮬레이션 서비스를 위한 최소한의 환경 설정
# 호스트의 예민한 부분(방화벽, AppArmor 등)은 건드리지 않음

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo "🔧 RHEL 8 최소 환경 구성 스크립트"
echo "=================================="
echo "📋 목표: 시나리오 구동 가능한 최소한의 환경만 구성"
echo "🚫 제한: 방화벽, AppArmor 등 호스트 예민 부분은 건드리지 않음"
echo "🔍 쿠버네티스: 설치하지 않고 확인만 진행"
echo ""

# 1. RHEL 8 환경 확인
log_info "RHEL 8 환경 확인 중..."
if [[ ! -f /etc/redhat-release ]]; then
    log_error "이 스크립트는 RHEL/CentOS 환경에서만 실행할 수 있습니다."
    exit 1
fi

RHEL_VERSION=$(cat /etc/redhat-release)
echo "배포판: $RHEL_VERSION"

if [[ ! "$RHEL_VERSION" =~ "Red Hat Enterprise Linux 8" ]]; then
    log_warning "RHEL 8이 아닌 다른 버전입니다. 호환성 문제가 있을 수 있습니다."
fi

# 2. 권한 확인
log_info "권한 확인 중..."
if [[ $EUID -ne 0 ]]; then
    log_error "이 스크립트는 root 권한으로 실행해야 합니다."
    log_info "sudo $0 명령으로 실행하세요."
    exit 1
fi

# 3. 시스템 업데이트 (최소한만)
log_info "시스템 업데이트 중 (최소한만)..."
dnf update -y --exclude="kernel*" --exclude="firewalld*" --exclude="apparmor*"
log_success "시스템 업데이트 완료 (커널, 방화벽, AppArmor 제외)"

# 4. 개발 도구 설치 (최소한만)
log_info "개발 도구 설치 중 (최소한만)..."
dnf install -y \
    gcc \
    gcc-c++ \
    make \
    git \
    curl \
    wget
log_success "개발 도구 설치 완료"

# 5. 컨테이너 도구 확인 (기존 설치된 것 사용)
log_info "컨테이너 도구 확인 중..."
if command -v podman &> /dev/null; then
    log_info "Podman이 이미 설치되어 있습니다."
    CONTAINER_CMD="podman"
elif command -v docker &> /dev/null; then
    log_info "Docker가 이미 설치되어 있습니다."
    CONTAINER_CMD="docker"
else
    log_warning "컨테이너 도구가 설치되지 않았습니다."
    log_info "수동으로 Docker 또는 Podman을 설치해주세요."
    log_info "  Docker: dnf install docker-ce"
    log_info "  Podman: dnf install podman"
    CONTAINER_CMD="none"
fi

# 6. kubectl 확인 (설치하지 않고 확인만)
log_info "kubectl 확인 중 (설치하지 않음)..."
if command -v kubectl &> /dev/null; then
    KUBECTL_VERSION=$(kubectl version --client --short 2>/dev/null | cut -d' ' -f3)
    log_success "kubectl이 이미 설치되어 있습니다. 버전: $KUBECTL_VERSION"
    log_info "kubectl 경로: $(which kubectl)"
else
    log_warning "kubectl이 설치되지 않았습니다."
    log_info "수동으로 kubectl을 설치해주세요:"
    log_info "  curl -LO 'https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl'"
    log_info "  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl"
fi

# 7. eBPF 도구 설치 (최소한만)
log_info "eBPF 도구 설치 중..."
dnf install -y bcc-tools
log_success "eBPF 도구 설치 완료"

# 8. 최소한의 SELinux 설정 (컨테이너 실행만 허용)
log_info "최소한의 SELinux 설정 중..."
if command -v setsebool &> /dev/null; then
    # 컨테이너 실행에 필요한 최소한의 권한만 설정
    setsebool -P container_manage_cgroup 1 2>/dev/null || log_warning "SELinux 설정 실패 (무시됨)"
    log_info "SELinux 최소 설정 완료"
else
    log_warning "SELinux 도구를 찾을 수 없습니다."
fi

# 9. 설치 완료 확인
log_info "설치 완료 확인 중..."
echo ""
log_success "🎉 RHEL 8 최소 환경 구성 완료!"
echo ""
echo "📋 설치된 도구들:"
echo "  - 개발 도구: gcc, make"
echo "  - 컨테이너: $CONTAINER_CMD"
echo "  - 쿠버네티스: kubectl (확인만, 설치하지 않음)"
echo "  - eBPF: bcc-tools"
echo "  - 기타: git, curl, wget"
echo ""
echo "🔧 다음 단계:"
echo "  1. 프로젝트 클론: git clone https://github.com/ekdh600/k8s-memleak.git"
echo "  2. 디렉토리 이동: cd k8s-memleak"
echo "  3. 빌드: make build"
echo "  4. 배포: make deploy"
echo ""
echo "🔍 eBPF 도구 테스트:"
echo "  - bcc-tools: /usr/share/bcc/tools/memleak"
echo ""
echo "⚠️  주의사항:"
echo "  - kubectl이 설치되지 않은 경우 수동 설치 필요"
echo "  - 방화벽 설정은 수동으로 확인 필요"
echo "  - AppArmor 설정은 수동으로 확인 필요"
echo "  - 네트워크 정책은 수동으로 확인 필요"
echo ""
echo "🧹 정리: make clean-all"