# 📝 변경 이력

이 파일은 이 프로젝트의 모든 중요한 변경사항을 기록합니다.

형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.0.0/)를 따르며,
이 프로젝트는 [Semantic Versioning](https://semver.org/lang/ko/)을 준수합니다.

## [Unreleased]

### 추가 예정
- Prometheus + Grafana 대시보드 자동 구축
- eBPF 도구 자동 설치 및 설정
- 다양한 클러스터 환경 지원 확장
- 성능 벤치마크 도구 추가

## [1.0.0] - 2025-08-20

### 추가
- 🚀 메모리 누수 시뮬레이션 Go 애플리케이션
- 📊 pprof 디버그 서버 (포트 6060)
- 🐳 Docker 멀티스테이지 빌드 지원
- ☸️ 쿠버네티스 매니페스트 (Deployment, Service, Ingress)
- 🔍 메모리 누수 감지 스크립트
- 🧪 Go 단위 테스트 (pprof 기반)
- 📈 실시간 메모리 모니터링 스크립트
- 🔧 eBPF 진단 도구 스크립트
- 🚀 자동화된 배포 패키지
- 📋 GitHub Actions CI/CD 파이프라인
- 📚 상세한 문서 및 가이드

### 지원하는 클러스터 타입
- **로컬 개발**: Kind, Minikube, Docker Desktop
- **클라우드**: AKS (Azure), EKS (AWS), GKE (Google)
- **엔터프라이즈**: OpenShift
- **사용자 정의**: 사용자 정의 클러스터

### 핵심 기능
- **메모리 누수 시뮬레이션**: 5초마다 1MB씩 메모리 누수
- **실시간 모니터링**: RSS, VMSize 변화 추적
- **프로파일링**: 힙, 고루틴, CPU 프로파일 자동 수집
- **자동화**: 원클릭 배포 및 정리
- **교육적 가치**: 실제 운영 환경과 유사한 시나리오

### 기술 스택
- **언어**: Go 1.22
- **컨테이너**: Docker
- **오케스트레이션**: Kubernetes
- **모니터링**: Prometheus + Grafana (준비됨)
- **진단**: eBPF (Inspektor Gadget)
- **프로파일링**: pprof
- **CI/CD**: GitHub Actions

## [0.1.0] - 2025-08-19

### 추가
- 초기 프로젝트 구조
- 기본 Go 애플리케이션
- Docker 설정
- 쿠버네티스 매니페스트 초안

## 📋 변경 유형

- **추가**: 새로운 기능
- **변경**: 기존 기능의 변경
- **사용 중단**: 곧 제거될 기능
- **제거**: 제거된 기능
- **수정**: 버그 수정
- **보안**: 보안 관련 수정

## 🔗 링크

- [GitHub Releases](../../releases)
- [GitHub Issues](../../issues)
- [GitHub Discussions](../../discussions)
- [GitHub Wiki](../../wiki)

---

**참고**: 이 파일은 [Keep a Changelog](https://keepachangelog.com/ko/1.0.0/) 형식을 따릅니다.