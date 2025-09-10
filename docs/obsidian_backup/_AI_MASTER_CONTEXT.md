# 🤖 AI 마스터 컨텍스트 - Class 프로젝트

> **이 파일을 AI에게 읽어주면 모든 프로젝트 상황을 파악할 수 있습니다**

## 📊 현재 상황 (2025-09-10 업데이트)

### 🎯 프로젝트 진행률
- **전체 진행률**: 65%
- **현재 단계**: 백엔드 API 개발 중
- **현재 작업**: file-service FastAPI 구현
- **다음 작업**: 프론트엔드-백엔드 연동
- **블로커**: 없음
- **마지막 업데이트**: 2025-09-10 (AI 자동)

### ⚡ 즉시 파악해야 할 핵심 사항
- Flutter Web 프론트엔드는 90% 완성 (UI, 인증, 화면 구성 완료)
- FastAPI 백엔드 서버 구조는 있지만 실제 기능 구현 필요
- Supabase 데이터베이스 스키마 설계 완료
- 서버 인프라 (Docker, nginx, Cloudflare) 완전 운영 중
- **급한 것**: file-service 백엔드 API 완성이 최우선

## 🏗️ 시스템 아키텍처 현황

```
사용자(브라우저) → Cloudflare 터널 → nginx → Flutter Web + file-service API
                                              ↓
                                         NAS 파일저장 + Supabase 메타데이터
```

### 🔧 기술 스택 완성도
- **Frontend**: Flutter Web (90% 완성)
- **Backend**: FastAPI (30% 완성) ← 현재 작업 중
- **Database**: Supabase PostgreSQL (스키마 100% 완성)
- **Storage**: NAS 42TB (설정 완료)
- **Infra**: Docker + nginx + Cloudflare (100% 운영 중)
- **Auth**: Supabase Google OAuth (100% 완성)

## 📁 현재 코드 상태

### ✅ 완료된 기능들
- **인증 시스템**: Google OAuth, 역할 기반 접근 제어
- **Flutter 화면들**: 로그인, 메인(학생), 관리자 화면 UI 완성
- **관리자 화면**: 과목/콘텐츠/권한 관리 UI (백엔드 연결 대기)
- **학생 화면**: 파일 업로드/목록 UI (백엔드 연결 대기)
- **서버 인프라**: 완전 자동화된 배포 시스템

### 🚧 현재 작업 중
- **file-service FastAPI**: `/class/api` 엔드포인트 구현
- **파일 업로드 로직**: NAS 저장 + Supabase 메타데이터
- **API 엔드포인트들**:
  - `POST /submissions/upload` (파일 업로드)
  - `GET /submissions?date=YYYYMMDD` (제출 내역)
  - `DELETE /submissions/file` (파일 삭제)
  - 관리자용 콘텐츠 관리 API들

### 🔄 다음 단계
1. FastAPI 백엔드 완성 (최우선)
2. 프론트엔드 API 연동
3. 에러 처리 및 UX 개선
4. 실습파일 다운로드 기능
5. Ollama AI 분석 연동 (향후)

## 🌐 현재 서비스 상태

### 📍 접근 URL
- **내부**: http://10.231.59.251/class/ ✅ 정상
- **외부**: https://info.pocheonil.hs.kr/class/ ✅ 정상
- **서버**: Ubuntu 24.04, RTX 4090, 42TB NAS ✅ 정상

### 🖥️ 서버 환경
- **위치**: 10.231.59.251 (gaoni 서버)
- **OS**: Ubuntu Server 24.04.3 LTS
- **GPU**: NVIDIA RTX 4090
- **스토리지**: 시놀로지 NAS 42TB (NFSv4.1)
- **도메인**: info.pocheonil.hs.kr (Cloudflare 터널)

## ❗ 알려진 문제들

### 🐛 현재 발견된 문제
- file-service API 엔드포인트들이 구현되지 않음 (우선순위 1)
- 프론트엔드에서 백엔드 API 호출 시 CORS 이슈 가능성
- 파일 업로드 시 용량 제한 설정 필요

### ✅ 해결된 문제들
- Cloudflare 터널 연결 안정화 완료
- nginx 프록시 설정 완료
- Docker 네트워크 연결 문제 해결
- Supabase 인증 플로우 완성

## 🔍 개발 환경 정보

### 💻 로컬 환경
- **주 개발기**: 맥북, 맥미니
- **동기화**: Obsidian Sync (연간 구독)
- **AI 도구**: Cursor AI Pro + Claude Code 유료 구독
- **코드 관리**: GitHub (menamiji/class)

### 🛠️ 개발 도구 설정
- **Flutter**: 최신 버전, 웹 개발 환경
- **IDE**: Cursor AI (메인), VS Code (보조)
- **API 테스트**: curl, Postman
- **서버 접속**: SSH (menamiji@10.231.59.251)

## 📋 파일 저장 구조

```
NAS 저장소:
- 콘텐츠: /mnt/nas-class/content/<과목>/<카테고리>/<항목>/<파일명>
- 제출물: /mnt/nas-class/submissions/<YYYYMMDD>/<학번>/<파일명>

Supabase 테이블:
- subjects: 과목 정보
- subject_contents: 콘텐츠 메타데이터  
- submissions: 제출물 메타데이터
- roles: 사용자 권한
```

## 🤖 AI 작업 로그 (자동 업데이트)

### 2025-09-10 세션
- **시작 시간**: 오후 3시경
- **주요 작업**: 
  - 옵시디언 문서들 분석 완료
  - 프로젝트 전체 상황 파악
  - AI 마스터 컨텍스트 파일 생성 (현재)
  - 문서 구조 재정리 계획 수립
  - GitHub 자동화 설정 진행 중
- **다음 계획**: file-service FastAPI 구현
- **사용자 요청**: 자동 문서 업데이트 시스템 구축

---

## 📚 상세 문서 위치

- **GitHub 백업**: /docs/obsidian_backup/
- **시스템 전반**: ubuntu_server.md (옵시디언)
- **프로젝트 상세**: 20501_class/ 디렉터리 (옵시디언)
- **일일 로그**: dev_logs/ (옵시디언 + GitHub)

---
*마지막 AI 자동 업데이트: 2025-09-10 오후 4:42*
*다음 자동 업데이트: 작업 완료 시 또는 사용자 요청 시*
