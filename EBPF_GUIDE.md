# 🔍 eBPF 트래킹 가이드

이 가이드는 Memory Leak Demo 프로젝트에서 eBPF 도구를 사용하여 메모리 누수를 추적하는 방법을 설명합니다.

## 📋 개요

eBPF(Extended Berkeley Packet Filter)는 커널 레벨에서 시스템 호출과 이벤트를 추적할 수 있는 강력한 도구입니다. 이 프로젝트에서는 표준 모니터링에서는 "정상"으로 보이지만 실제로는 메모리 누수가 발생하는 상황을 eBPF로 진단하는 방법을 보여줍니다.

## 🛠️ 지원하는 eBPF 도구

### 1. Inspektor Gadget (권장)
- **장점**: Kubernetes 네이티브, 쉬운 사용법
- **용도**: Pod 레벨 메모리 누수 추적
- **설치**: `kubectl apply -f k8s/inspektor-gadget.yaml`

### 2. BCC (BPF Compiler Collection)
- **장점**: 강력한 기능, 다양한 도구
- **용도**: 노드 레벨 상세 분석
- **설치**: `sudo apt-get install -y bpfcc-tools`

### 3. bpftrace
- **장점**: 간단한 스크립팅, 빠른 프로토타이핑
- **용도**: 커스텀 추적 스크립트
- **설치**: `sudo apt-get install -y bpftrace`

## 🚀 Inspektor Gadget 사용법

### 설치
```bash
kubectl apply -f k8s/inspektor-gadget.yaml
```

### 메모리 누수 추적
```bash
# Pod 이름 확인
kubectl -n memleak-demo get pods

# 메모리 누수 추적 시작
kubectl gadget memleak -n memleak-demo -p <pod-name>
```

### 출력 해석
```
Allocated memory:
  PID: 12345
  Size: 1048576 bytes (1MB)
  Stack trace:
    malloc+0x1a
    memory_leak_thread+0x45
    start_thread+0x87
```

## 🔧 BCC 도구 사용법

### 설치 (노드에서)
```bash
# Ubuntu/Debian
sudo apt-get install -y bpfcc-tools

# RHEL/CentOS
sudo yum install -y bcc-tools
```

### memleak 도구 사용
```bash
# Pod의 PID 확인
kubectl -n memleak-demo exec <pod-name> -- ps aux

# 메모리 누수 추적
sudo /usr/share/bcc/tools/memleak -p <pid>

# 전체 시스템 메모리 누수 추적
sudo /usr/share/bcc/tools/memleak
```

### mallocstacks 도구 사용
```bash
# malloc 호출 스택 추적
sudo /usr/share/bcc/tools/mallocstacks -p <pid>

# 특정 크기의 할당만 추적
sudo /usr/share/bcc/tools/mallocstacks -p <pid> --size 1048576
```

## 📝 bpftrace 사용법

### 설치 (노드에서)
```bash
# Ubuntu/Debian
sudo apt-get install -y bpftrace

# RHEL/CentOS
sudo yum install -y bpftrace
```

### 기본 메모리 할당 추적
```bash
# mmap 호출 추적
sudo bpftrace -e '
tracepoint:syscalls:sys_enter_mmap {
    printf("PID %d: mmap size=%d\n", pid, args->len);
}
'

# malloc 호출 추적 (libc 레벨)
sudo bpftrace -e '
uprobe:libc.so.6:malloc {
    printf("PID %d: malloc size=%d\n", pid, arg0);
}
'
```

### 고급 메모리 추적 스크립트
```bash
# 메모리 할당/해제 패턴 분석
sudo bpftrace -e '
uprobe:libc.so.6:malloc {
    @alloc[pid] = arg0;
    printf("PID %d: malloc(%d)\n", pid, arg0);
}

uretprobe:libc.so.6:malloc {
    if (@alloc[pid] != 0) {
        printf("PID %d: malloc returned %p\n", pid, retval);
        @alloc[pid] = 0;
    }
}
'
```

## 🎯 메모리 누수 시나리오 분석

### 시뮬레이션된 메모리 누수
- **빈도**: 8초마다 1MB
- **최대 누적량**: 2GB
- **패턴**: malloc() 호출 후 free() 호출 누락

### eBPF로 감지 가능한 패턴
1. **할당 패턴**: 주기적인 malloc() 호출
2. **해제 누락**: free() 호출이 없는 메모리 블록
3. **스택 트레이스**: memory_leak_thread 함수에서 할당

### 추적 결과 예시
```
Memory leak detected:
  PID: 12345
  Unfreed allocations: 150
  Total unfreed memory: 157286400 bytes (150MB)
  Most common allocation size: 1048576 bytes (1MB)
  Stack trace for unfreed allocations:
    memory_leak_thread+0x45
    start_thread+0x87
```

## 🔍 고급 분석 기법

### 1. 메모리 사용량 추이 분석
```bash
# 시간별 메모리 할당량 추적
sudo bpftrace -e '
uprobe:libc.so.6:malloc {
    @alloc_count[pid] = count();
    @alloc_size[pid] = sum(arg0);
    time("%H:%M:%S ");
    printf("PID %d: malloc(%d) - Total: %d calls, %d bytes\n", 
           pid, arg0, @alloc_count[pid], @alloc_size[pid]);
}
'
```

### 2. 메모리 누수 패턴 분석
```bash
# 할당/해제 비율 분석
sudo bpftrace -e '
uprobe:libc.so.6:malloc { @alloc[pid]++; }
uprobe:libc.so.6:free { @free[pid]++; }

interval:s:10 {
    printf("PID %d: Alloc/Free ratio: %d/%d = %.2f\n", 
           pid, @alloc[pid], @free[pid], 
           @alloc[pid] > 0 ? @alloc[pid] / @free[pid] : 0);
}
'
```

### 3. 커스텀 필터링
```bash
# 특정 크기 이상의 할당만 추적
sudo bpftrace -e '
uprobe:libc.so.6:malloc {
    if (arg0 > 1000000) {  // 1MB 이상
        printf("Large allocation: PID %d, size %d bytes\n", pid, arg0);
        @large_allocs[pid] = count();
    }
}
'
```

## 🚨 문제 해결

### 일반적인 문제

#### 1. 권한 부족
```bash
# privileged 모드로 실행 중인지 확인
kubectl -n memleak-demo describe pod <pod-name> | grep -A 5 SecurityContext

# 필요한 capabilities 확인
kubectl -n memleak-demo get pod <pod-name> -o yaml | grep -A 10 capabilities
```

#### 2. eBPF 도구가 작동하지 않음
```bash
# 커널 버전 확인 (4.18+ 필요)
uname -r

# eBPF 지원 확인
ls /sys/fs/bpf/

# BPF 도구 확인
bpftool version
```

#### 3. 성능 오버헤드
```bash
# CPU 사용량 모니터링
top -p <pid>

# 메모리 오버헤드 확인
ps -o pid,vsz,rss,comm -p <pid>
```

### 디버깅 팁
1. **점진적 추적**: 전체 시스템이 아닌 특정 프로세스부터 시작
2. **필터링**: 불필요한 이벤트는 제외하여 성능 향상
3. **로그 분석**: eBPF 도구의 로그와 애플리케이션 로그 비교

## 📊 모니터링 대시보드

### Grafana 대시보드 구성
- **메모리 사용량**: RSS, VSS, 스왑 사용량
- **할당 패턴**: malloc/free 호출 빈도
- **누수 지표**: 해제되지 않은 메모리 블록 수

### Prometheus 메트릭
- **커스텀 메트릭**: eBPF 도구에서 수집한 데이터
- **알림 규칙**: 메모리 누수 패턴 감지 시 알림

## 🔄 지속적인 모니터링

### 1. 자동화된 추적
```bash
# 주기적인 메모리 누수 검사
while true; do
    kubectl gadget memleak -n memleak-demo -p <pod-name> --duration 60s
    sleep 300  # 5분마다 검사
done
```

### 2. 로그 분석
```bash
# 메모리 누수 패턴 로그 분석
kubectl -n memleak-demo logs -f deployment/stealth-memory-leaker | \
grep "메모리 누수" | \
awk '{print $1, $2, $NF}' | \
sort -k3 -n
```

### 3. 알림 설정
- **Slack/Teams**: 메모리 누수 감지 시 알림
- **이메일**: 일일/주간 메모리 누수 리포트
- **대시보드**: 실시간 모니터링

## 📚 추가 리소스

- [eBPF 공식 문서](https://ebpf.io/)
- [Inspektor Gadget 문서](https://github.com/inspektor-gadget/inspektor-gadget)
- [BCC 도구 모음](https://github.com/iovisor/bcc)
- [bpftrace 문서](https://github.com/iovisor/bpftrace)

## 🎯 학습 목표

1. **기본 개념**: eBPF의 작동 원리와 장점 이해
2. **실용적 사용**: 실제 메모리 누수 문제 진단
3. **고급 기법**: 커스텀 추적 스크립트 작성
4. **운영 적용**: 프로덕션 환경에서의 eBPF 활용

---

**💡 핵심**: eBPF는 표준 모니터링으로는 감지할 수 없는 문제를 발견할 수 있는 강력한 도구입니다. 이 데모를 통해 eBPF의 진가를 체험하고, 실제 운영 환경에서 활용할 수 있는 능력을 기르세요!
