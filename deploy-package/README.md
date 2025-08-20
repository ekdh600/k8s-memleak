# 🚨 메모리 누수 시뮬레이션 배포 패키지

## 📋 개요

이 패키지는 다른 쿠버네티스 클러스터에서 메모리 누수 시뮬레이션을 쉽게 배포하고 모니터링할 수 있도록 설계되었습니다.

## 🎯 지원하는 클러스터 타입

- **로컬 개발**: Kind, Minikube, Docker Desktop
- **클라우드**: AKS (Azure), EKS (AWS), GKE (Google)
- **엔터프라이즈**: OpenShift
- **사용자 정의**: 사용자 정의 클러스터

## 🚀 빠른 시작

### 1. 패키지 다운로드
```bash
# 프로젝트 클론
git clone <repository-url>
cd memory-leak-demo/deploy-package

# 실행 권한 부여
chmod +x *.sh scripts/*.sh
```

### 2. 클러스터 설정
```bash
# 클러스터 타입 선택 및 설정
./scripts/setup-cluster.sh
```

### 3. 배포
```bash
# 자동 배포 실행
./deploy.sh
```

### 4. 모니터링
```bash
# 메모리 사용량 모니터링
./scripts/monitor-memory.sh

# 프로파일 수집
./scripts/collect-profiles.sh
```

### 5. 정리
```bash
# 환경 정리
./scripts/cleanup.sh --cleanup-all
```

## 📁 패키지 구조

```
deploy-package/
├── README.md                 # 이 파일
├── deploy.sh                 # 메인 배포 스크립트
├── k8s/                      # 쿠버네티스 매니페스트
│   ├── namespace.yaml        # 네임스페이스
│   ├── deployment.yaml       # 애플리케이션 배포
│   ├── service.yaml          # 서비스
│   ├── ingress.yaml          # 인그레스
│   └── prometheus-config.yaml # Prometheus 설정
└── scripts/                  # 유틸리티 스크립트
    ├── setup-cluster.sh      # 클러스터 설정
    ├── monitor-memory.sh     # 메모리 모니터링
    ├── collect-profiles.sh   # 프로파일 수집
    └── cleanup.sh            # 환경 정리
```

## 🛠️ 상세 사용법

### 클러스터 설정 (setup-cluster.sh)

```bash
# 기본 설정
./scripts/setup-cluster.sh

# 특정 네임스페이스 지정
NAMESPACE=my-namespace ./scripts/setup-cluster.sh
```

**지원하는 클러스터 타입:**
1. **kind**: 로컬 개발용 (권장)
2. **minikube**: 로컬 개발용
3. **docker-desktop**: Docker Desktop 내장
4. **aks**: Azure Kubernetes Service
5. **eks**: Amazon EKS
6. **gke**: Google GKE
7. **openshift**: OpenShift
8. **custom**: 사용자 정의

### 배포 (deploy.sh)

```bash
# 기본 배포
./deploy.sh

# 환경 변수로 설정
NAMESPACE=production IMAGE_TAG=v1.0.0 ./deploy.sh
```

**환경 변수:**
- `NAMESPACE`: 쿠버네티스 네임스페이스
- `IMAGE_NAME`: Docker 이미지 이름
- `IMAGE_TAG`: Docker 이미지 태그
- `CLUSTER_TYPE`: 클러스터 타입

### 메모리 모니터링 (monitor-memory.sh)

```bash
# 기본 모니터링 (10초 간격, 무한 실행)
./scripts/monitor-memory.sh

# 5초 간격으로 5분간 모니터링
./scripts/monitor-memory.sh -i 5 -d 300

# 특정 네임스페이스 모니터링
./scripts/monitor-memory.sh -n production -l app=myapp
```

**옵션:**
- `-n, --namespace`: 네임스페이스
- `-l, --label`: Pod 라벨 선택자
- `-i, --interval`: 모니터링 간격 (초)
- `-d, --duration`: 총 모니터링 시간 (초)
- `-f, --log-file`: 로그 파일 경로

### 프로파일 수집 (collect-profiles.sh)

```bash
# 기본 프로파일 수집 (5분 간격)
./scripts/collect-profiles.sh

# 10분 간격으로 프로파일 수집
./scripts/collect-profiles.sh -t 600

# 특정 디렉토리에 저장
./scripts/collect-profiles.sh -d ./my-profiles
```

**옵션:**
- `-n, --namespace`: 네임스페이스
- `-l, --label`: Pod 라벨 선택자
- `-d, --profile-dir`: 프로파일 저장 디렉토리
- `-p, --port`: pprof 서버 포트
- `-t, --duration`: 프로파일 수집 간격 (초)

### 정리 (cleanup.sh)

```bash
# 기본 정리 (쿠버네티스 리소스만)
./scripts/cleanup.sh

# 모든 리소스 정리
./scripts/cleanup.sh --cleanup-all

# 이미지와 프로파일도 정리
./scripts/cleanup.sh -i -p
```

**옵션:**
- `-n, --namespace`: 네임스페이스
- `-l, --label`: Pod 라벨 선택자
- `-i, --cleanup-images`: Docker 이미지 정리
- `-p, --cleanup-profiles`: 프로파일 파일 정리
- `-a, --cleanup-all`: 모든 리소스 정리

## 🔧 사전 요구사항

### 필수 도구
- **kubectl**: 쿠버네티스 CLI
- **Docker**: 컨테이너 엔진
- **Go**: 애플리케이션 빌드

### 선택 도구
- **Helm**: 패키지 매니저 (일부 클러스터)
- **kind**: 로컬 클러스터 (로컬 개발용)
- **minikube**: 로컬 클러스터 (로컬 개발용)

## 📊 모니터링 및 분석

### 1. 실시간 모니터링
```bash
# 메모리 사용량 추적
./scripts/monitor-memory.sh -i 5

# 로그 확인
kubectl -n memleak-demo logs -f deployment/leaky
```

### 2. 프로파일 분석
```bash
# 힙 프로파일 분석
go tool pprof -top ./profiles/heap_final_*.pb

# 웹 인터페이스
go tool pprof -http=:8080 ./profiles/heap_final_*.pb

# 프로파일 비교
go tool pprof -base ./profiles/heap_initial_*.pb ./profiles/heap_final_*.pb
```

### 3. 포트포워딩
```bash
# pprof 접근
kubectl -n memleak-demo port-forward pod/<pod-name> 6060:6060

# 브라우저에서 접근
# http://localhost:6060/debug/pprof/
```

## 🚨 문제 해결

### 일반적인 문제들

1. **권한 문제**
   ```bash
   # RBAC 권한 확인
   kubectl auth can-i create pods --namespace memleak-demo
   
   # 필요한 권한 부여
   kubectl create clusterrolebinding memleak-binding \
     --clusterrole=cluster-admin \
     --serviceaccount=memleak-demo:default
   ```

2. **이미지 로드 실패**
   ```bash
   # Kind 클러스터
   kind load docker-image memleak:latest
   
   # Minikube
   minikube image load memleak:latest
   
   # 클라우드 클러스터
   docker tag memleak:latest <registry>/memleak:latest
   docker push <registry>/memleak:latest
   ```

3. **포트 충돌**
   ```bash
   # 포트 사용 중인 프로세스 확인
   lsof -i :6060
   
   # 포트포워딩 프로세스 종료
   pkill -f "kubectl.*port-forward"
   ```

### 디버깅 명령어

```bash
# Pod 상태 확인
kubectl -n memleak-demo get all

# Pod 상세 정보
kubectl -n memleak-demo describe pod -l app=leaky

# 이벤트 확인
kubectl -n memleak-demo get events --sort-by='.lastTimestamp'

# 로그 확인
kubectl -n memleak-demo logs -l app=leaky --tail=100
```

## 📈 성능 지표

- **메모리 누수 속도**: 1MB/5초
- **탐지 임계값**: 20MB (RSS 증가)
- **프로파일 수집 주기**: 5분 (기본값)
- **모니터링 간격**: 10초 (기본값)

## 🔒 보안 고려사항

1. **권한 최소화**: 필요한 최소 권한만 부여
2. **네트워크 정책**: 적절한 네트워크 정책 설정
3. **리소스 제한**: 메모리 및 CPU 제한 설정
4. **로깅**: 민감한 정보 로깅 방지

## 📚 추가 리소스

- [메모리 누수 시뮬레이션 가이드](../README.md)
- [eBPF 도구 설치 가이드](../eBPF%20도구%20설치%20및%20사용%20가이드.md)
- [Prometheus + Grafana 구축 가이드](../Prometheus%20+%20Grafana%20대시보드%20구축%20가이드.md)

## 🤝 기여하기

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.

---

**⚠️ 주의**: 이 데모는 교육 목적으로만 사용되어야 합니다. 실제 운영 환경에서는 신중하게 테스트하고 검증된 도구들을 사용하세요.