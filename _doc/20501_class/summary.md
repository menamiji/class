# Class 프로젝트 운영 가이드

## 프로젝트 개요

### 🎯 목적
학교 수업 중 발생하는 과제물 제출 및 AI 자동 분석 시스템

### 🏗️ 시스템 아키텍처
```
학생 업로드 → 파일 변환 → Ollama 분석 → 결과 표시
     ↓              ↓            ↓           ↓
  Flutter Web → File Processor → RTX 4090 → Web UI
```

### 📊 기술 스택
| 구분 | 기술 | 버전 | 용도 |
|------|------|------|------|
| Frontend | Flutter | 3.35.2 | 웹 인터페이스 |
| Backend | Ollama | Latest | AI 분석 엔진 |
| 웹서버 | nginx | 1.29.1 | 정적 파일 서빙 |
| 터널 | Cloudflare | Latest | 외부 접근 |
| 컨테이너 | Docker | Latest | 서비스 관리 |
| 저장소 | GitHub | - | 코드 관리 |

## 현재 서비스 상태

### ✅ 운영 중인 서비스

**내부 접근 (서버 네트워크):**
- **메인 페이지**: http://10.231.59.251/
- **Class 앱**: http://10.231.59.251/class/
- **OpenWebUI**: http://10.231.59.251:3000

**외부 접근 (Cloudflare 터널):**
- **메인 페이지**: https://info.pocheonil.hs.kr/
- **Class 앱**: https://info.pocheonil.hs.kr/class/
- **터널 상태**: `docker compose logs cloudflared`

### 🔧 개발 상태
- [x] 기본 Flutter 프로젝트 설정
- [x] GitHub 저장소 연동
- [x] 자동 배포 파이프라인
- [x] nginx 다중 프로젝트 설정
- [x] Cloudflare 터널 외부 접근
- [ ] 파일 업로드 UI
- [ ] 파일 변환 시스템 (Excel, PPT, HWP)
- [ ] Ollama API 연동
- [ ] 사용자 권한 관리

## 개발 환경

### 🖥️ 로컬 개발 (권장)
```bash
# 저장소 클론
git clone https://github.com/menamiji/class.git
cd class

# Flutter 의존성 설치
flutter pub get

# 웹 개발 서버 실행
flutter run -d chrome

# 핫 리로드 활성화 (Cursor AI)
# F5 키 또는 Command Palette -> "Flutter: Run Flutter"
```

### 🚀 배포 환경
```bash
# 서버 접속
ssh menamiji@10.231.59.251

# 배포 스크립트 실행
~/deploy-class.sh

# 배포 상태 확인 (내부)
curl -s http://10.231.59.251/class/ | head -5

# 배포 상태 확인 (외부)
curl -s https://info.pocheonil.hs.kr/class/ | head -5
```

## 일일 운영 체크리스트

### 📋 매일 확인 사항
```bash
# 1. 서비스 상태 확인
cd ~/docker-services && docker compose ps

# 2. 웹 접근 테스트 (내부)
curl -I http://10.231.59.251/class/

# 3. 웹 접근 테스트 (외부)
curl -I https://info.pocheonil.hs.kr/class/

# 4. Cloudflare 터널 상태
docker compose logs cloudflared | grep "Registered tunnel connection" | wc -l

# 5. 로그 확인 (오류 없는지)
docker compose logs --tail=20 nginx | grep -i error

# 6. 디스크 사용량 확인
df -h | grep -E "(/$|/mnt)"

# 7. GPU 상태 확인 (AI 분석용)
nvidia-smi --query-gpu=utilization.gpu,memory.used --format=csv
```

### 🔍 주간 점검 사항
- [ ] GitHub 저장소 백업 상태
- [ ] Cloudflare 터널 연결 안정성
- [ ] 외부 도메인 접근 통계 검토
- [ ] 사용자 접근 로그 검토
- [ ] 시스템 업데이트 확인
- [ ] 성능 모니터링 데이터 검토

## 핵심 운영 명령어

### 🎯 배포 관련
```bash
# 코드 변경 후 배포
git add . && git commit -m "기능 추가"
git push origin main
ssh menamiji@10.231.59.251 '~/deploy-class.sh'

# 배포 후 확인 (내부 + 외부)
curl -I http://10.231.59.251/class/
curl -I https://info.pocheonil.hs.kr/class/

# 배포 롤백 (문제 발생 시)
git revert HEAD
git push origin main
ssh menamiji@10.231.59.251 '~/deploy-class.sh'

# 수동 빌드 (디버깅용)
cd ~/docker-services/projects/class/frontend
flutter build web --base-href="/class/" --verbose
```

### 📊 모니터링
```bash
# 실시간 로그 모니터링
docker compose logs -f nginx
docker compose logs -f cloudflared

# 에러 로그만 확인
docker compose logs nginx | grep -E "(error|Error|ERROR)"
docker compose logs cloudflared | grep -E "(error|Error|ERROR)"

# 액세스 로그 분석
docker compose logs nginx | grep "GET /class/" | tail -20

# 터널 연결 상태 확인
docker compose logs cloudflared | grep "Registered tunnel connection"

# 시스템 리소스 확인
docker stats --no-stream
```

### 🛠️ 문제 해결
```bash
# nginx 설정 검사
docker exec nginx nginx -t

# 컨테이너 재시작 (순서 중요)
docker compose restart nginx
docker compose restart cloudflared

# Cloudflare 터널 재연결
docker compose restart cloudflared
docker compose logs cloudflared | tail -10

# 파일 권한 복구
sudo chown -R menamiji:docker ~/docker-services/data/apps/

# 캐시 정리
docker system prune -f
```

## 개발 워크플로우

### 📝 새 기능 개발 프로세스
1. **로컬 환경에서 개발**
   ```bash
   # Cursor AI에서 코드 작성
   # Hot Reload로 즉시 테스트
   ```

2. **기능 테스트**
   ```bash
   # 로컬 빌드 테스트
   flutter build web --base-href="/class/"
   
   # 빌드 파일 검증
   ls -la build/web/
   ```

3. **코드 커밋 & 푸시**
   ```bash
   git add .
   git commit -m "feat: 파일 업로드 UI 추가"
   git push origin main
   ```

4. **서버 배포**
   ```bash
   ssh menamiji@10.231.59.251 '~/deploy-class.sh'
   ```

5. **배포 검증**
   ```bash
   # 내부 접근 테스트
   curl -I http://10.231.59.251/class/
   
   # 외부 접근 테스트
   curl -I https://info.pocheonil.hs.kr/class/
   
   # 브라우저에서 기능 테스트
   # https://info.pocheonil.hs.kr/class/
   ```

### 🔄 Git 브랜치 전략 (향후)
```bash
# 기능 개발용 브랜치
git checkout -b feature/file-upload
git commit -m "feat: 파일 업로드 기능 추가"
git push origin feature/file-upload

# 메인 브랜치 병합
git checkout main
git merge feature/file-upload
git push origin main
```

## 성능 및 모니터링

### 📈 핵심 지표
- **내부 응답 시간**: http://10.231.59.251/class/ < 2초
- **외부 응답 시간**: https://info.pocheonil.hs.kr/class/ < 3초
- **GPU 사용률**: Ollama 실행 시 < 80%
- **메모리 사용률**: 시스템 전체 < 70%
- **디스크 사용률**: < 80%
- **터널 연결 수**: 4개 (정상)

### 🔔 알림 설정 (향후 구현)
```bash
# 디스크 사용률 80% 이상 시 알림
# GPU 온도 80도 이상 시 알림
# 서비스 다운 시 알림
# Cloudflare 터널 연결 끊김 시 알림
```

## 보안 고려사항

### 🔒 현재 보안 설정
- SSH 키 기반 인증
- Docker 네트워크 격리
- GitHub Personal Access Token
- Cloudflare 터널 암호화 (HTTPS)

### 🛡️ 향후 보안 강화
- [ ] 사용자 인증 시스템 (외부 접근용)
- [ ] 파일 업로드 검증
- [ ] API 인증 및 권한 관리
- [ ] 접근 로그 모니터링
- [ ] DDoS 보호 (Cloudflare)

## 네트워크 구성

### 🌐 접근 경로
```
사용자 → Cloudflare Edge → 터널 → nginx → Flutter App
     (HTTPS)         (암호화)    (HTTP)   (정적파일)
```

### 🔧 Cloudflare 설정
- **도메인**: info.pocheonil.hs.kr
- **터널 ID**: f06eff80-6393-440e-8d4b-d0cdcd9debf2
- **백엔드**: nginx:80 (Docker 내부)
- **프로토콜**: HTTP to HTTPS 자동 변환

## 비상 대응 절차

### 🚨 서비스 다운 시
```bash
# 1. 상태 확인
cd ~/docker-services && docker compose ps

# 2. 로그 확인
docker compose logs --tail=50

# 3. 서비스 재시작
docker compose restart

# 4. 상태 재확인 (내부 + 외부)
curl -I http://10.231.59.251/class/
curl -I https://info.pocheonil.hs.kr/class/
```

### 🌐 Cloudflare 터널 다운 시
```bash
# 1. 터널 상태 확인
docker compose logs cloudflared | tail -20

# 2. 터널 재시작
docker compose restart cloudflared

# 3. 연결 재확인
docker compose logs cloudflared | grep "Registered tunnel connection"

# 4. 외부 접근 테스트
curl -I https://info.pocheonil.hs.kr/class/
```

### 💾 데이터 복구
```bash
# 1. 백업에서 복원
tar -xzf backup_YYYYMMDD.tar.gz -C ~/

# 2. 권한 수정
sudo chown -R menamiji:docker ~/docker-services/

# 3. 환경변수 복원 (Cloudflare 토큰 포함)
cp backup/.env ~/docker-services/

# 4. 서비스 재시작
docker compose up -d
```

## 향후 로드맵

### 📅 단기 목표 (1-2주)
- [ ] 파일 업로드 UI 완성
- [ ] 기본 파일 형식 지원 (PDF, TXT)
- [ ] Ollama API 연동
- [ ] 외부 접근 사용자 가이드 작성

### 📅 중기 목표 (1-2개월)
- [ ] Excel, PowerPoint, HWP 변환
- [ ] 사용자 인증 시스템 (외부 접근용)
- [ ] 분석 결과 저장 및 조회
- [ ] 접근 통계 대시보드

### 📅 장기 목표 (3-6개월)
- [ ] 모바일 앱 (Flutter)
- [ ] 실시간 알림 시스템
- [ ] 다중 학교 지원
- [ ] API 문서화 및 외부 연동

## 연락처 및 참고자료

### 🔗 중요 링크
- **GitHub**: https://github.com/menamiji/class.git
- **내부 접근**: http://10.231.59.251/class/
- **외부 접근**: https://info.pocheonil.hs.kr/class/
- **서버 접속**: `ssh menamiji@10.231.59.251`

### 📚 기술 문서
- **Flutter**: https://docs.flutter.dev/
- **Ollama**: https://ollama.ai/docs
- **nginx**: https://nginx.org/en/docs/
- **Cloudflare Tunnels**: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/

---
*최종 업데이트: 2025-09-05*
*담당자: menamiji*
*문서 버전: 1.1 (Cloudflare 터널 추가)*