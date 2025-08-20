# 🚀 배포 패키지

## 📋 개요

이 패키지는 C 기반 메모리 누수 시뮬레이터를 다른 쿠버네티스 클러스터에 쉽게 배포할 수 있도록 설계되었습니다.

## 🎯 특징

- ✅ **Go 환경 불필요**: Docker 이미지만으로 실행
- ✅ **자동화된 배포**: 원클릭 배포 및 정리
- ✅ **eBPF 트래킹 최적화**: 커널 레벨 메모리 추적
- ✅ **클러스터 자동 감지**: Kind, Minikube, 클라우드 클러스터 지원

## 🚀 빠른 시작

### 1. 배포
```bash
chmod +x deploy.sh
./deploy.sh
```

### 2. 정리
```bash
chmod +x cleanup.sh
./cleanup.sh
```

## 📁 구조

```
deploy-package/
├── deploy.sh              # 자동 배포 스크립트
├── cleanup.sh             # 리소스 정리 스크립트
├── README.md              # 이 파일
└── k8s/                   # 쿠버네티스 매니페스트
    ├── deployment.yaml    # 애플리케이션 배포
    ├── service.yaml       # 서비스 설정
    └── namespace.yaml     # 네임스페이스
```

## 🔧 사용법

### 자동 배포
```bash
./deploy.sh
```

### 수동 배포
```bash
# 네임스페이스 생성
kubectl create namespace memleak-demo

# 리소스 배포
kubectl apply -f k8s/
```

### 상태 확인
```bash
# Pod 상태
kubectl -n memleak-demo get all

# 로그 확인
kubectl -n memleak-demo logs -f deployment/memory-leaker
```

### eBPF 트래킹
```bash
# Inspektor Gadget 설치
kubectl apply -f https://raw.githubusercontent.com/inspektor-gadget/inspektor-gadget/main/deploy/gadget.yaml

# 메모리 누수 추적
kubectl gadget memleak -n memleak-demo -p <pod-name>
```

## 🎯 지원하는 클러스터

- **로컬**: Kind, Minikube, Docker Desktop
- **클라우드**: AKS, EKS, GKE
- **엔터프라이즈**: OpenShift
- **사용자 정의**: 모든 쿠버네티스 클러스터

## 🔍 문제 해결

### 일반적인 문제들

#### 1. 권한 문제
```bash
# Pod가 privileged 모드로 실행되는지 확인
kubectl -n memleak-demo describe pod <pod-name>
```

#### 2. 이미지 로드 실패
```bash
# 클러스터 타입 확인
kubectl config current-context
```

#### 3. 배포 실패
```bash
# 이벤트 확인
kubectl -n memleak-demo get events
```

## 📚 추가 리소스

- [메인 README](../../README.md)
- [eBPF 트래킹 가이드](../../EBPF_GUIDE.md)
- [설치 가이드](../../INSTALL.md)

## 🤝 지원

문제가 발생하거나 질문이 있으시면:
- [GitHub Issues](../../issues)에 버그 리포트
- [GitHub Discussions](../../discussions)에서 질문

---

**💡 팁**: 배포 후 `kubectl -n memleak-demo get all`로 상태를 확인하세요!