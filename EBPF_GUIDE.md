# 🔍 eBPF 메모리 누수 트래킹 가이드

## 📋 개요

이 가이드는 C 기반 메모리 누수 시뮬레이터를 eBPF 도구로 트래킹하는 방법을 설명합니다.

## 🚀 빠른 시작

### 1. 메모리 누수 시뮬레이터 배포
```bash
# 프로젝트 클론
git clone https://github.com/ekdh600/k8s-memleak.git
cd k8s-memleak

# Docker 이미지 빌드
make docker-build

# 쿠버네티스에 배포
make deploy
```

### 2. eBPF 도구 설치
```bash
# Inspektor Gadget 설치
make install-ebpf

# 설치 확인
kubectl get pods -n gadget-system
```

### 3. 메모리 누수 트래킹
```bash
# Pod 이름 확인
kubectl -n memleak-demo get pods

# eBPF로 메모리 누수 추적
make track-memory
```

## 🔧 eBPF 도구 상세 사용법

### Inspektor Gadget memleak

#### 기본 사용법
```bash
# 특정 Pod의 메모리 누수 추적
kubectl gadget memleak -n memleak-demo -p <pod-name>

# 특정 프로세스 ID로 추적
kubectl gadget memleak -n memleak-demo --pid <pid>

# 지속 시간 지정 (5분)
kubectl gadget memleak -n memleak-demo -p <pod-name> --duration 300
```

#### 고급 옵션
```bash
# 스택 트레이스와 함께
kubectl gadget memleak -n memleak-demo -p <pod-name> --show-references

# 특정 크기 이상만 추적
kubectl gadget memleak -n memleak-demo -p <pod-name> --min-size 1048576

# 출력 형식 지정
kubectl gadget memleak -n memleak-demo -p <pod-name> --output json
```

### BCC (BPF Compiler Collection)

#### memleak 도구
```bash
# 특정 프로세스 추적
sudo /usr/share/bcc/tools/memleak -p <pid>

# 스택 트레이스와 함께
sudo /usr/share/bcc/tools/memleak -p <pid> --show-references

# 특정 크기 이상만
sudo /usr/share/bcc/tools/memleak -p <pid> --min-size 1048576
```

#### malloc 트레이스
```bash
# malloc/free 호출 추적
sudo /usr/share/bcc/tools/trace 'p:malloc "size=%d", arg1' -p <pid>

# 메모리 할당 패턴 분석
sudo /usr/share/bcc/tools/trace 'r:malloc "ptr=%p, size=%d", retval, arg1' -p <pid>
```

### bpftrace

#### 메모리 할당 이벤트 추적
```bash
# mmap 호출 추적
sudo bpftrace -e '
tracepoint:syscalls:sys_enter_mmap {
    printf("PID %d: mmap size=%d\n", pid, args->len);
}
'

# malloc 호출 추적 (uprobe)
sudo bpftrace -e '
uprobe:libc:malloc {
    printf("PID %d: malloc size=%d\n", pid, arg0);
}
'
```

## 📊 트래킹 결과 해석

### Inspektor Gadget 출력 예시
```
[2024-01-20 10:30:15] Memory leak detected
PID: 12345
Comm: memory_leak
Size: 1048576 bytes (1.0 MB)
Stack trace:
    [0] malloc
    [1] leak_memory
    [2] main
    [3] __libc_start_main
```

### BCC 출력 예시
```
[10:30:15] Leak of 1048576 bytes in 1 allocations from 1 unique stacks
    [0] malloc
    [1] leak_memory
    [2] main
    [3] __libc_start_main
```

## 🎯 트래킹 시나리오

### 시나리오 1: 기본 메모리 누수 감지
```bash
# 1. 시뮬레이터 배포
make deploy

# 2. eBPF 트래킹 시작
kubectl gadget memleak -n memleak-demo -p <pod-name>

# 3. 5분간 관찰
# 4. 결과 분석
```

### 시나리오 2: 스택 트레이스 분석
```bash
# 1. 상세한 스택 트레이스
kubectl gadget memleak -n memleak-demo -p <pod-name> --show-references

# 2. 특정 크기 이상만 추적
kubectl gadget memleak -n memleak-demo -p <pod-name> --min-size 1048576
```

### 시나리오 3: 성능 분석
```bash
# 1. 메모리 할당 속도 측정
kubectl gadget memleak -n memleak-demo -p <pod-name> --duration 300

# 2. JSON 출력으로 분석
kubectl gadget memleak -n memleak-demo -p <pod-name> --output json > memleak.json
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

#### 2. eBPF 도구 설치 실패
```bash
# 네임스페이스 확인
kubectl get namespaces | grep gadget

# Pod 상태 확인
kubectl get pods -n gadget-system

# 로그 확인
kubectl logs -n gadget-system -l app=gadget
```

#### 3. 트래킹 결과 없음
```bash
# 프로세스 ID 확인
kubectl -n memleak-demo exec -it <pod-name> -- ps aux

# 메모리 사용량 확인
kubectl -n memleak-demo exec -it <pod-name> -- cat /proc/1/status | grep Vm
```

## 📈 성능 최적화

### 트래킹 오버헤드 최소화
```bash
# 특정 이벤트만 필터링
kubectl gadget memleak -n memleak-demo -p <pod-name> --min-size 1048576

# 지속 시간 제한
kubectl gadget memleak -n memleak-demo -p <pod-name> --duration 300
```

### 메모리 사용량 최적화
```bash
# 버퍼 크기 조정
kubectl gadget memleak -n memleak-demo -p <pod-name> --max-entries 10000

# 출력 형식 최적화
kubectl gadget memleak -n memleak-demo -p <pod-name> --output compact
```

## 🔗 추가 리소스

### 공식 문서
- [Inspektor Gadget Documentation](https://github.com/inspektor-gadget/inspektor-gadget)
- [BCC Tools](https://github.com/iovisor/bcc)
- [bpftrace Reference](https://github.com/iovisor/bpftrace)

### 커뮤니티
- [eBPF Slack](https://ebpf.io/slack/)
- [Kubernetes Slack](https://slack.k8s.io/)

### 도구 설치
```bash
# Ubuntu/Debian
sudo apt-get install bpfcc-tools

# CentOS/RHEL
sudo yum install bcc-tools

# macOS
brew install bcc
```

---

**💡 팁**: eBPF 트래킹은 강력하지만 시스템 리소스를 사용합니다. 프로덕션 환경에서는 신중하게 사용하세요.