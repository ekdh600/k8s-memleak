# 🧪 메모리 누수 eBPF 트래킹 데모 테스트 가이드

## 📋 테스트 개요

이 가이드는 **은밀한 메모리 누수 시뮬레이션**을 테스트하는 방법을 설명합니다. 
표준 모니터링 도구(Grafana, Prometheus)에서는 "정상"으로 보이지만, 
실제로는 eBPF를 통해서만 진짜 메모리 누수를 확인할 수 있습니다.

## 🎯 테스트 목표

1. **표준 모니터링에서 "정상" 확인**: Grafana, Prometheus, GCC가 모두 정상으로 인식
2. **eBPF로 실제 메모리 누수 확인**: 커널 레벨에서 진짜 메모리 누수 추적

---

## 🚀 1단계: 환경 준비

### Docker 이미지 빌드
```bash
# 프로젝트 디렉토리로 이동
cd memory-leak-demo

# Docker 이미지 빌드
docker build -t memory-leak-demo:latest .

# 빌드 확인
docker images | grep memory-leak-demo
```

### 로컬 테스트 환경 실행
```bash
# 컨테이너 실행 (포트 8080: HTTP, 9090: Prometheus)
docker run --rm -d --name memory-leak-test \
  -p 8080:8080 -p 9090:9090 \
  memory-leak-demo:latest

# 컨테이너 상태 확인
docker ps | grep memory-leak-test
```

---

## ✅ 2단계: 정상적으로 보이는 화면/메트릭 확인

### 2.1 HTTP 헬스체크 확인
```bash
# 헬스체크 엔드포인트 테스트
curl -s http://localhost:8080/health | jq .

# 예상 결과 (항상 "healthy" 상태)
{
  "status": "healthy",
  "metrics": {
    "memory_usage_percent": 1,
    "memory_rss_kb": 10780,
    "total_requests": 1,
    "healthy_responses": 1,
    "uptime_seconds": 1755672150
  },
  "health_checks": {
    "liveness": "passing",
    "readiness": "passing",
    "memory": "normal",
    "gc": "healthy",
    "response_time": "fast"
  },
  "message": "서비스가 정상적으로 작동하고 있습니다."
}
```

### 2.2 Prometheus 메트릭 확인
```bash
# Prometheus 메트릭 엔드포인트
curl -s http://localhost:9090/metrics | grep -E "(http_requests_total|memory_leak)"

# 예상 결과 - 모든 메트릭이 "정상"으로 표시
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total 1

# HELP memory_leak_simulator_chunks_total Total number of memory chunks (HIDDEN)
# TYPE memory_leak_simulator_chunks_total counter
memory_leak_simulator_chunks_total 1
```

### 2.3 Grafana 대시보드 확인 (선택사항)
```bash
# Grafana 컨테이너 실행 (Prometheus와 연동)
docker run --rm -d --name grafana-test \
  -p 3000:3000 \
  -e GF_SECURITY_ADMIN_PASSWORD=admin \
  grafana/grafana:latest

# 브라우저에서 http://localhost:3000 접속
# admin/admin 로그인
# Prometheus 데이터소스 추가: http://host.docker.internal:9090
```

### 2.4 GCC 컴파일 확인
```bash
# 소스 코드 컴파일 테스트
docker run --rm -v $(pwd)/src:/src gcc:11 bash -c "
  cd /src && 
  gcc -O2 -static -s -pthread -o test_main main_service.c fake_metrics.c &&
  gcc -O2 -static -s -pthread -o test_healthy healthy_service.c &&
  echo '✅ GCC 컴파일 성공' &&
  ls -lh test_*
"
```

---

## 🔍 3단계: eBPF를 통한 실제 메모리 누수 확인

### 3.1 Inspektor Gadget 설치 (Kubernetes 환경)
```bash
# Inspektor Gadget 설치
kubectl apply -f k8s/inspektor-gadget.yaml

# 설치 확인
kubectl get pods -n gadget
```

### 3.2 메모리 누수 추적 시작
```bash
# 메모리 할당 추적 (실시간)
kubectl gadget profile mem -p <pod-name> -f memprofile.txt

# 또는 특정 프로세스의 메모리 사용량 추적
kubectl gadget top mem -p <pod-name>
```

### 3.3 BCC 도구를 사용한 노드 레벨 추적
```bash
# 노드에 접속
kubectl debug node/<node-name> -it --image=ubuntu:20.04

# BCC 도구 설치
apt update && apt install -y python3-bpfcc

# 메모리 할당 추적
python3 -c "
from bcc import BPF
b = BPF(text='''
#include <uapi/linux/ptrace.h>
#include <linux/sched.h>

int trace_malloc(struct pt_regs *ctx, size_t size) {
    u32 pid = bpf_get_current_pid_tgid();
    bpf_trace_printk(\"PID %d malloc %d bytes\\n\", pid >> 32, size);
    return 0;
}

int trace_free(struct pt_regs *ctx, void *ptr) {
    u32 pid = bpf_get_current_pid_tgid();
    bpf_trace_printk(\"PID %d free %p\\n\", pid >> 32, ptr);
    return 0;
}

BPF_HOOK(\"malloc\", trace_malloc);
BPF_HOOK(\"free\", trace_free);
''')
b.trace_print()
"
```

### 3.4 bpftrace를 사용한 고급 추적
```bash
# bpftrace 설치
apt install -y bpftrace

# 메모리 할당 추적 스크립트
cat > memleak.bt << 'EOF'
#!/usr/bin/env bpftrace

BEGIN
{
    printf("🔍 메모리 누수 추적 시작...\n");
    printf("PID\tSize\tCount\tTotal\n");
}

uprobe:libc:malloc
{
    @size[pid] = arg1;
    @count[pid]++;
    @total[pid] += arg1;
}

uprobe:libc:free
{
    @count[pid]--;
    @total[pid] -= @size[pid];
    delete(@size[pid]);
}

END
{
    printf("📊 메모리 누수 추적 결과:\n");
    print(@count);
    print(@total);
}
EOF

# 스크립트 실행
bpftrace memleak.bt
```

---

## 📊 4단계: 테스트 시나리오 및 예상 결과

### 4.1 메모리 누수 시뮬레이션 단계
```bash
# 1단계: 초기 상태 (0-30초)
# - 메모리 사용량: ~10MB
# - Grafana: 모든 지표 "정상"
# - eBPF: 정상적인 메모리 할당/해제

# 2단계: 누수 시작 (30초-5분)
# - 메모리 사용량: 10MB → 100MB
# - Grafana: 여전히 "정상" 표시
# - eBPF: malloc 호출 증가, free 호출 감소

# 3단계: 누수 가속 (5분-15분)
# - 메모리 사용량: 100MB → 1GB
# - Grafana: "정상" 유지 (fake metrics)
# - eBPF: 명확한 메모리 누수 패턴

# 4단계: 치명적 누수 (15분+)
# - 메모리 사용량: 1GB → 2GB
# - Grafana: 여전히 "정상" (완전한 위장)
# - eBPF: 심각한 메모리 누수 확인
```

### 4.2 예상되는 eBPF 추적 결과
```
🔍 메모리 누수 추적 결과:

PID 1234의 메모리 사용량:
- malloc 호출: 1,000+ 회
- free 호출: 50회 미만
- 누적 메모리: 1.5GB+
- 메모리 누수율: 95%+

🚨 경고: 심각한 메모리 누수 감지!
```

---

## 🧹 5단계: 테스트 정리

### 5.1 로컬 테스트 정리
```bash
# 테스트 컨테이너 정리
docker stop memory-leak-test
docker rm memory-leak-test

# Grafana 테스트 정리 (선택사항)
docker stop grafana-test
docker rm grafana-test
```

### 5.2 Kubernetes 테스트 정리
```bash
# 배포된 리소스 정리
kubectl delete -f k8s/
kubectl delete -f k8s/inspektor-gadget.yaml

# 또는 스크립트 사용
./scripts/cleanup.sh
```

---

## 🔧 6단계: 문제 해결

### 6.1 일반적인 문제들

#### Docker 빌드 실패
```bash
# 에러: "undefined reference to 'main'"
# 해결: fake_metrics.h 헤더 파일 확인, 중복 함수 제거

# 에러: "multiple definition"
# 해결: main_service.c에서 중복 함수/변수 제거
```

#### 컨테이너 실행 실패
```bash
# 포트 충돌
netstat -tulpn | grep :8080
docker stop $(docker ps -q)

# 권한 문제
docker run --privileged -p 8080:8080 -p 9090:9090 memory-leak-demo:latest
```

#### eBPF 도구 설치 실패
```bash
# Inspektor Gadget 설치 실패
kubectl get nodes -o wide  # 노드 아키텍처 확인
kubectl describe pod -n gadget  # 상세 오류 확인

# BCC 도구 컴파일 실패
apt install -y build-essential linux-headers-$(uname -r)
```

### 6.2 디버깅 명령어
```bash
# 컨테이너 로그 확인
docker logs memory-leak-test

# 컨테이너 내부 접속
docker exec -it memory-leak-test /bin/sh

# 프로세스 상태 확인
docker exec memory-leak-test ps aux

# 메모리 사용량 확인
docker exec memory-leak-test cat /proc/1/status | grep VmRSS
```

---

## 📚 7단계: 추가 테스트 시나리오

### 7.1 부하 테스트
```bash
# Apache Bench를 사용한 부하 테스트
ab -n 1000 -c 10 http://localhost:8080/health

# 메모리 누수 가속화 확인
```

### 7.2 장기 실행 테스트
```bash
# 24시간 장기 실행 테스트
docker run --rm -d --name long-test \
  -p 8080:8080 -p 9090:9090 \
  memory-leak-demo:latest

# 주기적 모니터링
watch -n 60 'curl -s http://localhost:8080/health | jq .metrics.memory_usage_percent'
```

### 7.3 다양한 eBPF 도구 테스트
```bash
# perf 도구 사용
perf record -g -p <pid> -e syscalls:sys_enter_mmap

# ftrace 사용
echo 1 > /sys/kernel/debug/tracing/tracing_on
echo function > /sys/kernel/debug/tracing/current_tracer
```

---

## 🎯 테스트 성공 기준

### ✅ 정상 모니터링 확인
- [ ] HTTP 헬스체크가 항상 "healthy" 반환
- [ ] Prometheus 메트릭이 "정상" 값 표시
- [ ] Grafana 대시보드가 모든 지표를 "정상"으로 표시
- [ ] GCC 컴파일이 오류 없이 성공

### ✅ eBPF 추적 확인
- [ ] Inspektor Gadget이 정상 설치 및 실행
- [ ] 메모리 할당/해제 패턴이 추적됨
- [ ] 메모리 누수 패턴이 명확히 감지됨
- [ ] 누적 메모리 사용량이 지속적으로 증가

### ✅ 위장 효과 확인
- [ ] 표준 모니터링에서는 문제가 보이지 않음
- [ ] eBPF에서만 진짜 메모리 누수 확인 가능
- [ ] "은밀한" 메모리 누수의 효과 검증

---

## 📖 참고 자료

- [eBPF 공식 문서](https://ebpf.io/)
- [Inspektor Gadget 가이드](https://github.com/inspektor-gadget/inspektor-gadget)
- [BCC 도구 모음](https://github.com/iovisor/bcc)
- [bpftrace 사용법](https://github.com/iovisor/bpftrace)

---

**⚠️ 주의**: 이 데모는 교육 목적으로만 사용하세요. 실제 프로덕션 환경에서는 사용하지 마세요.
