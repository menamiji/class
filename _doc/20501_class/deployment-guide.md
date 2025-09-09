# Class 프로젝트 배포 가이드

## 배포 아키텍처

### 시스템 구성
```
로컬 개발 환경 (Cursor AI)
        ↓ git push
    GitHub 저장소
        ↓ git pull
Ubuntu 서버 (10.231.59.251)
        ↓ flutter build
    정적 파일 생성
        ↓ file copy
    nginx 웹서빙
        ↓ HTTP
사용자 브라우저 접근
```

## 자동 배포 스크립트

### 배포 스크립트 설치
```bash
# 서버에서 실행
cat > ~/deploy-class.sh << 'EOF'
#!/bin/bash

cd ~/docker-services/projects/class/frontend

echo "Pulling latest code..."
git pull origin main

echo "Building Flutter app..."
flutter build web --base-href="/class/"

echo "Deploying..."
cp -r build/web/* ../../../data/apps/class/

echo "Done! Check: http://10.231.59.251/class/"
EOF

chmod +x ~/deploy-class.sh
```

### 배포 실행
```bash
# 단일 명령어로 배포
~/deploy-class.sh

# 또는 상세 로그와 함께
bash -x ~/deploy-class.sh
```

## 수동 배포 절차

### 1단계: 코드 업데이트
```bash
ssh menamiji@10.231.59.251
cd ~/docker-services/projects/class/frontend

# 현재 브랜치 확인
git branch

# 최신 코드 가져오기
git pull origin main

# 변경사항 확인
git log --oneline -5
```

### 2단계: Flutter 빌드
```bash
# 빌드 전 의존성 확인
flutter doctor

# 웹용 빌드 (base-href 필수)
flutter build web --base-href="/class/"

# 빌드 결과 확인
ls -la build/web/
du -sh build/web/
```

### 3단계: 파일 배포
```bash
# 기존 파일 백업 (안전성)
cp -r ~/docker-services/data/apps/class/ ~/docker-services/data/apps/class.backup.$(date +%Y%m%d_%H%M%S)

# 새 파일 복사
cp -r build/web/* ../../../data/apps/class/

# 권한 확인
ls -la ~/docker-services/data/apps/class/
```

### 4단계: 배포 검증
```bash
# HTTP 응답 확인
curl -I http://10.231.59.251/class/

# 파일 내용 확인
curl -s http://10.231.59.251/class/ | head -10

# nginx 로그 확인
docker compose logs --tail=10 nginx
```

## Git 인증 설정

### Personal Access Token 설정
```bash
# credential store 활성화 (한 번만)
git config --global credential.helper store

# 첫 번째 pull 시 토큰 입력
git pull origin main
# Username: menamiji
# Password: [Personal Access Token]

# 이후 자동 인증됨
```

### SSH 키 방식 (대안)
```bash
# SSH 키가 있는 경우
git remote set-url origin git@github.com:menamiji/class.git

# SSH 연결 테스트
ssh -T git@github.com
```

## 환경별 배포 설정

### 개발 환경 (로컬)
```bash
# 개발 서버 실행
flutter run -d chrome

# 빌드 테스트
flutter build web

# 로컬 서빙 테스트
cd build/web && python3 -m http.server 8000
```

### 스테이징 환경 (향후)
```bash
# 별도 포트로 테스트 배포
flutter build web --base-href="/class-staging/"
cp -r build/web/* ../../../data/apps/class-staging/
```

### 프로덕션 환경
```bash
# 현재 설정
flutter build web --base-href="/class/"
cp -r build/web/* ../../../data/apps/class/

# 성능 최적화 빌드
flutter build web --release --base-href="/class/"
```

## 배포 전 체크리스트

### 로컬 테스트
- [ ] `flutter run -d chrome` 정상 작동
- [ ] 모든 페이지 네비게이션 테스트
- [ ] 브라우저 개발자 도구에서 오류 없음
- [ ] `flutter build web` 성공
- [ ] build/web/ 디렉터리에 모든 파일 생성

### 코드 품질
- [ ] Git commit 메시지 작성
- [ ] 불필요한 console.log 제거
- [ ] TODO 주석 확인
- [ ] 코드 포맷팅 적용

### 배포 준비
- [ ] GitHub에 최신 코드 push 완료
- [ ] 서버 접속 가능 확인
- [ ] 서버 디스크 용량 충분 (>1GB)
- [ ] nginx 서비스 정상 작동

## 배포 후 검증

### 기능 테스트
```bash
# 1. 기본 접근 테스트
curl -s -o /dev/null -w "%{http_code}" http://10.231.59.251/class/

# 2. 정적 파일 로딩 테스트
curl -s -o /dev/null -w "%{http_code}" http://10.231.59.251/class/main.dart.js

# 3. 응답 시간 측정
time curl -s http://10.231.59.251/class/ > /dev/null
```

### 브라우저 테스트
- [ ] http://10.231.59.251/class/ 정상 로딩
- [ ] 모든 UI 요소 표시
- [ ] 개발자 도구에서 JavaScript 오류 없음
- [ ] 네트워크 탭에서 모든 리소스 로딩 성공
- [ ] 모바일 반응형 디자인 확인

### 로그 확인
```bash
# nginx 액세스 로그
docker compose logs nginx | grep "GET /class/"

# 에러 로그 확인
docker compose logs nginx | grep -i error | tail -5

# 시스템 리소스 확인
docker stats --no-stream
```

## 롤백 절차

### 빠른 롤백 (파일 기반)
```bash
# 1. 백업에서 복원
BACKUP_DIR=$(ls -t ~/docker-services/data/apps/class.backup.* | head -1)
rm -rf ~/docker-services/data/apps/class/*
cp -r $BACKUP_DIR/* ~/docker-services/data/apps/class/

# 2. 확인
curl -I http://10.231.59.251/class/
```

### Git 기반 롤백
```bash
# 1. 이전 커밋으로 되돌리기
cd ~/docker-services/projects/class/frontend
git log --oneline -5  # 커밋 해시 확인
git reset --hard [이전_커밋_해시]

# 2. 다시 빌드 및 배포
flutter build web --base-href="/class/"
cp -r build/web/* ../../../data/apps/class/
```

### 긴급 롤백 (nginx 설정)
```bash
# 임시로 메인 페이지로 리다이렉트
echo '<meta http-equiv="refresh" content="0; url=/" />' > ~/docker-services/data/apps/class/index.html
```

## 성능 최적화

### 빌드 최적화
```bash
# 트리 셰이킹 비활성화 (필요시)
flutter build web --no-tree-shake-icons

# 소스맵 생성 (디버깅용)
flutter build web --source-maps

# 웹 어셈블리 사용 (실험적)
flutter build web --wasm
```

### nginx 캐싱 설정
```nginx
# nginx 설정에 추가
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
    expires 30d;
    add_header Cache-Control "public, no-transform";
}
```

### 파일 압축
```bash
# gzip 압축 활성화 (nginx)
location /class/ {
    gzip on;
    gzip_types text/plain text/css application/javascript application/json;
    try_files $uri $uri/ /class/index.html;
}
```

## 모니터링 및 알림

### 배포 상태 모니터링
```bash
# 배포 상태 체크 스크립트
cat > ~/check-deployment.sh << 'EOF'
#!/bin/bash
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://10.231.59.251/class/)
if [ $RESPONSE -eq 200 ]; then
    echo "✅ Deployment OK"
else
    echo "❌ Deployment Failed: HTTP $RESPONSE"
fi
EOF

chmod +x ~/check-deployment.sh
```

### 로그 모니터링
```bash
# 실시간 에러 모니터링
docker compose logs -f nginx | grep -E "(error|Error|ERROR)" --color=always

# 액세스 패턴 분석
docker compose logs nginx | grep "GET /class/" | awk '{print $1}' | sort | uniq -c | sort -nr
```

## 백업 전략

### 자동 백업 스크립트
```bash
cat > ~/backup-class.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR=~/backups/class/$DATE

mkdir -p $BACKUP_DIR

# 소스코드 백업
tar -czf $BACKUP_DIR/source.tar.gz ~/docker-services/projects/class/

# 배포 파일 백업
tar -czf $BACKUP_DIR/deployed.tar.gz ~/docker-services/data/apps/class/

# 설정 파일 백업
cp ~/docker-services/services/nginx/conf/default.conf $BACKUP_DIR/

echo "Backup completed: $BACKUP_DIR"
EOF

chmod +x ~/backup-class.sh
```

### 정기 백업 설정 (cron)
```bash
# crontab 편집
crontab -e

# 매일 새벽 3시 백업
0 3 * * * /home/menamiji/backup-class.sh
```

---
*배포 가이드 버전: 1.0*
*최종 업데이트: 2025-09-04*