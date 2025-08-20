# ⚡ 빠른 시작 가이드

## 🚀 5분 만에 시작하기

### 1. 프로젝트 받기
```bash
# GitHub에서 클론
git clone https://github.com/YOUR_USERNAME/memory-leak-demo.git
cd memory-leak-demo
```

### 2. 로컬에서 테스트
```bash
# Go 환경 설정
go mod tidy
go build -o app main.go

# 메모리 누수 시뮬레이션 시작
./app
```

### 3. 쿠버네티스에 배포
```bash
# 배포 패키지 사용
cd deploy-package
./scripts/setup-cluster.sh  # 클러스터 설정
./deploy.sh                  # 자동 배포
```

### 4. 모니터링 및 분석
```bash
# 메모리 사용량 모니터링
./scripts/monitor-memory.sh

# 프로파일 수집
./scripts/collect-profiles.sh
```

## 📋 지원하는 환경

- ✅ **로컬**: Kind, Minikube, Docker Desktop
- ✅ **클라우드**: AKS, EKS, GKE
- ✅ **엔터프라이즈**: OpenShift
- ✅ **사용자 정의**: 모든 쿠버네티스 클러스터

## 🎯 핵심 기능

- 🔍 **메모리 누수 시뮬레이션**: 5초마다 1MB 누수
- 📊 **실시간 모니터링**: RSS, VMSize 변화 추적
- 🧪 **자동화된 테스트**: CI/CD 파이프라인
- 🚀 **원클릭 배포**: 완전 자동화된 배포
- 📈 **프로파일링**: pprof 기반 성능 분석

## 📚 상세 가이드

- [설치 가이드](INSTALL.md) - 상세한 설치 과정
- [GitHub 설정](GITHUB_SETUP.md) - 저장소 설정 및 공유
- [기여 가이드](CONTRIBUTING.md) - 프로젝트 기여 방법
- [변경 이력](CHANGELOG.md) - 버전별 변경사항

## 🆘 문제 해결

### 빠른 진단
```bash
# 상태 확인
kubectl -n memleak-demo get all

# 로그 확인
kubectl -n memleak-demo logs -f deployment/leaky

# 이벤트 확인
kubectl -n memleak-demo get events
```

### 일반적인 문제
- **권한 문제**: eBPF 도구 사용 시 privileged 권한 필요
- **포트 충돌**: 6060 포트 사용 중인지 확인
- **이미지 로드**: 클러스터 타입에 따른 이미지 로드 방법 확인

## 🔗 유용한 링크

- [GitHub 저장소](../../)
- [이슈 리포트](../../issues)
- [토론 참여](../../discussions)
- [Wiki](../../wiki)

---

**💡 팁**: 문제가 발생하면 [GitHub Issues](../../issues)에 버그 리포트를 남겨주세요!