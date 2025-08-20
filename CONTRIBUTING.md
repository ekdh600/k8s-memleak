# 🤝 기여 가이드

## 📋 기여하기 전에

이 프로젝트에 기여하기 전에 다음 사항을 확인해주세요:

1. **프로젝트 목적 이해**: 교육용 메모리 누수 시뮬레이션 및 진단 도구
2. **라이선스 확인**: MIT 라이선스 하에 배포
3. **코드 품질**: Go 언어 표준 및 베스트 프랙티스 준수

## 🚀 기여 방법

### 1. 저장소 포크
GitHub에서 이 저장소를 포크하세요.

### 2. 로컬 클론
```bash
git clone https://github.com/YOUR_USERNAME/memory-leak-demo.git
cd memory-leak-demo
```

### 3. 원격 저장소 추가
```bash
git remote add upstream https://github.com/ORIGINAL_OWNER/memory-leak-demo.git
```

### 4. 기능 브랜치 생성
```bash
git checkout -b feature/amazing-feature
```

### 5. 변경사항 커밋
```bash
git add .
git commit -m "Add: amazing feature description"
```

### 6. 브랜치 푸시
```bash
git push origin feature/amazing-feature
```

### 7. Pull Request 생성
GitHub에서 Pull Request를 생성하세요.

## 📝 커밋 메시지 규칙

### 형식
```
<type>: <description>

[optional body]

[optional footer]
```

### 타입
- **feat**: 새로운 기능
- **fix**: 버그 수정
- **docs**: 문서 변경
- **style**: 코드 스타일 변경 (기능에 영향 없음)
- **refactor**: 코드 리팩토링
- **test**: 테스트 추가 또는 수정
- **chore**: 빌드 프로세스 또는 보조 도구 변경

### 예시
```
feat: add memory leak detection threshold configuration

- Add configurable threshold for memory leak detection
- Support both percentage and absolute value thresholds
- Update documentation with new configuration options

Closes #123
```

## 🔧 개발 환경 설정

### 필수 도구
- Go 1.22+
- Docker
- kubectl
- Git

### 선택 도구
- Kind (로컬 쿠버네티스)
- Minikube (로컬 쿠버네티스)
- Helm (패키지 매니저)

### 개발 환경 설정
```bash
# 의존성 설치
go mod tidy

# 테스트 실행
go test -v

# 빌드
go build -o app main.go

# Docker 이미지 빌드
docker build -t memleak:latest .
```

## 🧪 테스트

### 테스트 실행
```bash
# 모든 테스트
go test -v

# 특정 테스트
go test -v -run TestMemoryLeak

# 커버리지
go test -cover

# 벤치마크
go test -bench=.
```

### 테스트 작성 규칙
1. **테스트 파일명**: `*_test.go`
2. **테스트 함수명**: `Test*`
3. **벤치마크 함수명**: `Benchmark*`
4. **예시 함수명**: `Example*`

## 📚 문서화

### 코드 주석
- 모든 공개 함수에 주석 작성
- Go 표준 주석 형식 사용
- 예시 코드 포함

### README 업데이트
- 새로운 기능 추가 시 README.md 업데이트
- 사용법 및 예시 포함
- 스크린샷 또는 다이어그램 추가

### API 문서
- 새로운 API 추가 시 문서화
- 예시 요청/응답 포함
- 에러 코드 및 메시지 설명

## 🔍 코드 리뷰

### Pull Request 체크리스트
- [ ] 코드가 프로젝트 목적에 부합하는가?
- [ ] 테스트가 포함되어 있는가?
- [ ] 문서가 업데이트되었는가?
- [ ] 코드 스타일이 일관성 있는가?
- [ ] 에러 처리가 적절한가?
- [ ] 성능에 영향을 주는가?

### 리뷰어 가이드라인
1. **건설적인 피드백**: 문제점뿐만 아니라 개선 방안 제시
2. **코드 품질**: 가독성, 유지보수성, 성능 고려
3. **보안**: 잠재적 보안 위험 확인
4. **접근성**: 다양한 사용자가 사용할 수 있는지 확인

## 🚨 보안

### 보안 취약점 보고
보안 취약점을 발견하셨다면:
1. **즉시 보고**: security@example.com으로 이메일
2. **공개하지 않음**: 공개적으로 공유하지 마세요
3. **상세 정보**: 재현 방법 및 영향 범위 포함

### 보안 코딩 가이드라인
1. **입력 검증**: 모든 사용자 입력 검증
2. **권한 최소화**: 필요한 최소 권한만 부여
3. **에러 처리**: 민감한 정보 노출 방지
4. **의존성 관리**: 정기적인 보안 업데이트

## 📊 성능

### 성능 테스트
```bash
# 메모리 사용량 테스트
./ci/leak_check.sh

# CPU 사용량 테스트
go test -bench=BenchmarkMemoryLeak

# 프로파일링
go tool pprof -http=:8080 cpu.prof
```

### 성능 가이드라인
1. **메모리 효율성**: 불필요한 메모리 할당 방지
2. **CPU 효율성**: 알고리즘 최적화
3. **I/O 효율성**: 적절한 버퍼링 및 캐싱
4. **확장성**: 대용량 데이터 처리 고려

## 🌍 국제화

### 다국어 지원
1. **언어 파일**: `locales/` 디렉토리에 언어별 파일
2. **번역**: 전문 번역가 검토
3. **문화적 고려**: 지역별 사용자 경험 최적화

## 📈 릴리스

### 릴리스 프로세스
1. **버전 태그**: `v1.0.0` 형식으로 태그
2. **릴리스 노트**: 주요 변경사항 및 마이그레이션 가이드
3. **체크리스트**: 배포 전 확인사항
4. **롤백 계획**: 문제 발생 시 대응 방안

## 🤝 커뮤니티

### 토론 참여
- [GitHub Discussions](../../discussions)에서 아이디어 공유
- [GitHub Issues](../../issues)에서 버그 리포트 및 기능 요청
- [Wiki](../../wiki)에서 문서 작성 및 수정

### 행동 강령
1. **존중**: 모든 기여자 존중
2. **포용성**: 다양한 배경과 경험 수용
3. **건설적**: 건설적인 피드백과 토론
4. **전문성**: 전문적이고 정중한 소통

## 📞 연락처

### 질문 및 지원
- **GitHub Issues**: [이슈 생성](../../issues/new)
- **GitHub Discussions**: [토론 참여](../../discussions)
- **이메일**: support@example.com

### 기여 관련 문의
- **기여 가이드**: 이 문서
- **코드 리뷰**: Pull Request에서 직접
- **프로젝트 방향**: GitHub Discussions

---

**감사합니다!** 🎉 이 프로젝트에 기여해주셔서 감사합니다.
여러분의 기여가 더 나은 교육 도구와 진단 환경을 만들어갑니다.