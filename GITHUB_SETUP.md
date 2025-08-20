# 🚀 GitHub 저장소 설정 가이드

## 📋 개요

이 가이드는 로컬 Git 저장소를 GitHub 원격 저장소에 연결하고, 다른 클러스터에서 `git clone`으로 프로젝트를 받을 수 있도록 설정하는 방법을 설명합니다.

## 🔧 1단계: GitHub 저장소 생성

### 1. GitHub 웹사이트 접속
- [GitHub.com](https://github.com)에 로그인
- 우측 상단의 **"+"** 버튼 클릭
- **"New repository"** 선택

### 2. 저장소 정보 입력
```
Repository name: memory-leak-demo
Description: Memory Leak Simulation and Diagnosis Demo for Kubernetes
Visibility: Public (또는 Private)
Initialize this repository with: 체크하지 않음
```

### 3. 저장소 생성
- **"Create repository"** 버튼 클릭

## 🔗 2단계: 원격 저장소 연결

### 1. 원격 저장소 추가
```bash
# 원격 저장소 추가 (YOUR_USERNAME을 실제 사용자명으로 변경)
git remote add origin https://github.com/YOUR_USERNAME/memory-leak-demo.git

# 원격 저장소 확인
git remote -v
```

### 2. 브랜치 이름 설정 (필요시)
```bash
# 기본 브랜치를 main으로 설정
git branch -M main
```

### 3. 원격 저장소에 푸시
```bash
# 첫 번째 푸시
git push -u origin main

# 이후 푸시
git push
```

## 📥 3단계: 다른 클러스터에서 사용

### 1. 프로젝트 클론
```bash
# 공개 저장소인 경우
git clone https://github.com/YOUR_USERNAME/memory-leak-demo.git

# 비공개 저장소인 경우 (토큰 필요)
git clone https://YOUR_TOKEN@github.com/YOUR_USERNAME/memory-leak-demo.git
```

### 2. 프로젝트 디렉토리로 이동
```bash
cd memory-leak-demo
```

### 3. 배포 패키지 사용
```bash
# 배포 패키지로 이동
cd deploy-package

# 클러스터 설정
./scripts/setup-cluster.sh

# 배포 실행
./deploy.sh
```

## 🔐 4단계: 비공개 저장소 설정 (선택사항)

### 1. Personal Access Token 생성
- GitHub → Settings → Developer settings → Personal access tokens
- **"Generate new token"** 클릭
- 권한 설정:
  - `repo` (전체 저장소 접근)
  - `workflow` (GitHub Actions)
- 토큰 생성 및 안전한 곳에 저장

### 2. 토큰을 사용한 클론
```bash
# 토큰을 사용한 클론
git clone https://YOUR_TOKEN@github.com/YOUR_USERNAME/memory-leak-demo.git
```

## 🌐 5단계: GitHub Pages 설정 (선택사항)

### 1. GitHub Pages 활성화
- 저장소 → Settings → Pages
- Source: **"Deploy from a branch"** 선택
- Branch: **"main"** 선택
- **"Save"** 클릭

### 2. 문서 접근
- `https://YOUR_USERNAME.github.io/memory-leak-demo/`에서 문서 확인

## 🔄 6단계: 지속적인 업데이트

### 1. 로컬에서 변경사항 커밋
```bash
# 변경사항 확인
git status

# 변경사항 추가
git add .

# 커밋
git commit -m "feat: add new feature description"

# 푸시
git push
```

### 2. 다른 클러스터에서 업데이트
```bash
# 변경사항 가져오기
git pull origin main

# 또는 저장소 새로 클론
rm -rf memory-leak-demo
git clone https://github.com/YOUR_USERNAME/memory-leak-demo.git
```

## 📚 7단계: 고급 설정

### 1. 브랜치 보호 규칙
- 저장소 → Settings → Branches
- **"Add rule"** 클릭
- Branch name pattern: `main`
- 설정:
  - ✅ Require a pull request before merging
  - ✅ Require status checks to pass before merging
  - ✅ Require branches to be up to date before merging

### 2. GitHub Actions 설정
- `.github/workflows/leak-check.yml` 파일이 자동으로 활성화됨
- Pull Request나 main 브랜치에 푸시할 때마다 자동 실행

### 3. 이슈 템플릿 설정
- `.github/ISSUE_TEMPLATE/` 디렉토리 생성
- 버그 리포트 및 기능 요청 템플릿 추가

## 🚨 문제 해결

### 1. 인증 오류
```bash
# GitHub CLI 사용
gh auth login

# 또는 토큰 재설정
git remote set-url origin https://YOUR_TOKEN@github.com/YOUR_USERNAME/memory-leak-demo.git
```

### 2. 권한 오류
```bash
# 저장소 권한 확인
gh repo view YOUR_USERNAME/memory-leak-demo

# 협업자 추가 (필요시)
gh repo edit YOUR_USERNAME/memory-leak-demo --add-collaborator USERNAME
```

### 3. 브랜치 충돌
```bash
# 원격 변경사항 가져오기
git fetch origin

# 로컬 변경사항 백업
git stash

# 원격 변경사항 적용
git pull origin main

# 로컬 변경사항 복원
git stash pop
```

## 📊 8단계: 프로젝트 홍보

### 1. README 최적화
- 프로젝트 설명 및 사용법
- 스크린샷 및 다이어그램
- 라이선스 및 기여 가이드

### 2. Topics 추가
- 저장소 → About → Topics
- 추가할 키워드:
  - `kubernetes`
  - `memory-leak`
  - `ebpf`
  - `go`
  - `monitoring`
  - `diagnosis`
  - `education`

### 3. 릴리스 태그
```bash
# 버전 태그 생성
git tag -a v1.0.0 -m "Release version 1.0.0"

# 태그 푸시
git push origin v1.0.0
```

## 🔍 9단계: 사용 통계 확인

### 1. GitHub Insights
- 저장소 → Insights → Traffic
- 클론 수, 방문자 수, 인기 페이지 확인

### 2. GitHub Actions
- Actions 탭에서 CI/CD 실행 상태 확인
- 성공/실패율 및 실행 시간 분석

### 3. 이슈 및 Pull Request
- 기여자 수, 이슈 해결 속도, 코드 품질 확인

## 📞 지원 및 도움

### 1. GitHub 도움말
- [GitHub Docs](https://docs.github.com/)
- [GitHub Guides](https://guides.github.com/)

### 2. 커뮤니티
- [GitHub Discussions](../../discussions)
- [GitHub Issues](../../issues)

### 3. 연락처
- 이슈나 토론을 통해 질문
- Pull Request로 기여

---

**🎉 축하합니다!** 이제 다른 클러스터에서 `git clone`으로 프로젝트를 받아 사용할 수 있습니다.

## 📋 체크리스트

- [ ] GitHub 저장소 생성
- [ ] 원격 저장소 연결
- [ ] 첫 번째 푸시 완료
- [ ] 다른 클러스터에서 클론 테스트
- [ ] 배포 패키지 실행 테스트
- [ ] 문서 및 설정 최적화
- [ ] 프로젝트 홍보 및 공유