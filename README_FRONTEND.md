# Class 파일 제출 시스템 - Flutter 프론트엔드

## 📋 프로젝트 개요

교육용 파일 제출 시스템의 Flutter Web 프론트엔드입니다. 학생들이 과제를 제출하고 관리자가 콘텐츠를 관리할 수 있는 웹 애플리케이션입니다.

## 🚀 빠른 시작

### 1️⃣ 개발 환경 실행

```bash
# 권한 설정 (최초 1회)
chmod +x scripts/dev_run.sh

# 개발 서버 실행
./scripts/dev_run.sh
```

### 2️⃣ 수동 실행 (디버깅용)

```bash
# 의존성 설치
flutter pub get

# 개발 서버 실행
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://znocjtfrtxwulyngzqfy.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpub2NqdGZydHh3dWx5bmd6cWZ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjU3NzU3ODEsImV4cCI6MjA0MTM1MTc4MX0.JRtBpgcNYG9hCO-aQCeizGnU5gNLSBjrW6pElgHgKcM
```

## 🏗️ 빌드 및 배포

### 1️⃣ 웹 빌드

```bash
# 권한 설정 (최초 1회)
chmod +x scripts/build_web.sh

# 웹 빌드 실행
./scripts/build_web.sh
```

### 2️⃣ 수동 빌드

```bash
flutter build web \
  --base-href="/class/" \
  --dart-define=SUPABASE_URL=https://znocjtfrtxwulyngzqfy.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<ANON_KEY> \
  --release
```

### 3️⃣ 서버 배포

```bash
# 서버에 배포 (서버 측 스크립트 실행)
ssh menamiji@10.231.59.251 '~/deploy-class.sh'
```

## 🔧 프로젝트 구조

```
lib/
├── main.dart                 # 앱 진입점 및 Supabase 초기화
├── services/
│   ├── auth_service.dart     # 인증 관련 서비스
│   └── api_client.dart       # 백엔드 API 클라이언트
└── screens/
    ├── login_screen.dart     # 로그인 화면
    └── main_screen.dart      # 메인 화면 (파일 업로드/관리)
```

## 🎯 주요 기능

### 📝 로그인
- **테스트 로그인**: 개발용 이메일/비밀번호
- **Google OAuth**: 실제 서비스용 Google 계정 로그인
- **도메인 제한**: `@pocheonil.hs.kr` 도메인만 접근 가능

### 📤 파일 업로드
- 다중 파일 선택 및 업로드
- 실시간 업로드 상태 표시
- 파일명/크기 표시

### 📋 제출 내역 관리
- 오늘 날짜 기준 제출 파일 목록
- 파일 삭제 기능
- 새로고침으로 목록 갱신

## 🔐 환경 변수

개발/빌드 시 필요한 환경 변수:

- `SUPABASE_URL`: Supabase 프로젝트 URL
- `SUPABASE_ANON_KEY`: Supabase Anonymous Key

## 📡 API 연동

백엔드 API 엔드포인트:
- `POST /class/api/submissions/upload` - 파일 업로드
- `GET /class/api/submissions?date=YYYYMMDD` - 제출 내역 조회
- `DELETE /class/api/submissions/file` - 파일 삭제
- `GET /class/api/healthz` - 헬스체크

## 🧪 테스트

### 코드 분석
```bash
flutter analyze
```

### 의존성 검증
```bash
flutter pub deps
```

## 📦 주요 의존성

- `supabase_flutter: ^2.5.6` - Supabase 통합
- `http: ^1.1.0` - HTTP 클라이언트
- `intl: ^0.19.0` - 날짜/시간 포맷팅
- `file_picker: ^8.0.0+1` - 파일 선택기

## 🌐 접근 URL

- **개발**: http://localhost:3000 (Flutter 개발 서버)
- **내부**: http://10.231.59.251/class/
- **외부**: https://info.pocheonil.hs.kr/class/

## 🔍 트러블슈팅

### 의존성 오류
```bash
flutter clean
flutter pub get
```

### 빌드 오류
```bash
flutter pub deps
flutter analyze
```

### CORS 오류
- Chrome 개발자 도구에서 네트워크 탭 확인
- Supabase 설정에서 허용된 도메인 확인

## 👥 개발팀

- **개발자**: menamiji
- **프로젝트**: Class 파일 제출 시스템
- **업데이트**: 2025-01-13

## 📚 관련 문서

- `_doc/20501_class/개발문서 (20250908_1).md` - 전체 시스템 설계
- `_doc/20501_class/summary.md` - 운영 가이드
- `_doc/20501_class/deployment-guide.md` - 배포 가이드
