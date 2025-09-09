# Class 프로젝트 트러블슈팅 가이드

## 🚨 긴급 상황 대응

### 서비스 완전 다운
```bash
# 1. 모든 서비스 상태 확인
cd ~/docker-services && docker compose ps

# 2. 시스템 리소스 확인
free -h && df -h

# 3. Docker 재시작
sudo systemctl restart docker
docker compose up -d

# 4. 개별 서비스 재시작
docker compose restart nginx
docker compose restart ollama
```

### 웹사이트 접근 불가
```bash
# Step 1: 기본 네트워크 확인
ping 10.231.59.251
curl -I http://10.231.59.251/

# Step 2: nginx 상태 확인
docker compose ps nginx
docker compose logs --tail=20 nginx

# Step 3: 포트 확인
netstat -tulnp | grep :80

# Step 4: 방화벽 확인 (필요시)
sudo ufw status
```

## 🔧 일반적인 문제 해결

### 1. 하얀 화면 (Class 앱)

**증상**: http://10.231.59.251/class/ 접속 시 하얀 화면

**원인 분석**:
```bash
# 파일 존재 확인
ls -la ~/docker-services/data/apps/class/

# 브라우저 개발자 도구 확인 (F12)
# Console 탭에서 JavaScript 오류 확인
# Network 탭에서 파일 로딩 실패 확인
```

**해결 방법**:
```bash
# 방법 1: base-href로 다시 빌드
cd ~/docker-services/projects/class/frontend
flutter build web --base-href="/class/"
cp -r build/web/* ../../../data/apps/class/

# 방법 2: nginx 설정 확인
cat ~/docker-services/services/nginx/conf/default.conf
# location /class/ 블록이 있는지 확인

# 방법 3: 파일 권한 수정
sudo chown -R menamiji:docker ~/docker-services/data/apps/class/
```

### 2. Flutter 빌드 실패

**증상**: `flutter build web` 명령어 실패

**해결 방법**:
```bash
# Step 1: Flutter 상태 확인
flutter doctor

# Step 2: 의존성 업데이트
flutter clean
flutter pub get

# Step 3: 웹 지원 확인
flutter config --enable-web

# Step 4: 캐시 정리
flutter clean
rm -rf build/

# Step 5: 재빌드
flutter build web --base-href="/class/"
```

### 3. Git Pull 실패

**증상**: `git pull origin main` 실패

**해결 방법**:
```bash
# 인증 문제 해결
git config --global credential.helper store
git pull origin main  # 토큰 재입력

# 병합 충돌 해결
git status
git add .
git commit -m "Resolve conflicts"
git pull origin main

# 강제 업데이트 (주의: 로컬 변경사항 손실)
git fetch origin
git reset --hard origin/main
```

### 4. Docker 컨테이너 문제

**nginx 컨테이너 문제**:
```bash
# 컨테이너 로그 확인
docker compose logs nginx

# 설정 파일 검증
docker exec nginx nginx -t

# 컨테이너 재생성
docker compose down nginx
docker compose up -d nginx
```

**ollama 컨테이너 문제**:
```bash
# GPU 접근 확인
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi

# 볼륨 마운트 확인
docker compose exec ollama ls -la /root/.ollama

# 컨테이너 재시작
docker compose restart ollama
```

### 5. 성능 문제

**느린 응답 시간**:
```bash
# 시스템 리소스 확인
htop
iotop

# Docker 리소스 사용량
docker stats

# 디스크 I/O 확인
iostat -x 1

# 네트워크 상태
ss -tulnp | grep -E "(80|3000|11434)"
```

**메모리 부족**:
```bash
# 메모리 사용량 확인
free -h

# 스왑 사용량 확인
swapon --show

# 메모리 정리
sync && echo 3 > /proc/sys/vm/drop_caches

# 불필요한 Docker 이미지 정리
docker image prune -f
```

## 🔍 진단 도구

### 자동 진단 스크립트
```bash
cat > ~/diagnose-class.sh << 'EOF'
#!/bin/bash
echo "=== Class Project Diagnosis ==="
echo

echo "1. Service Status:"
cd ~/docker-services && docker compose ps
echo

echo "2. Web Access Test:"
curl -I http://10.231.59.251/class/ 2>/dev/null | head -1 || echo "❌ Connection failed"
echo

echo "3. File Check:"
if [ -f ~/docker-services/data/apps/class/index.html ]; then
    echo "✅ index.html exists"
else
    echo "❌ index.html missing"
fi
echo

echo "4. Git Status:"
cd ~/docker-services/projects/class/frontend
git status --porcelain | head -5
echo

echo "5. System Resources:"
echo "Memory: $(free -h | grep Mem | awk '{print $3"/"$2}')"
echo "Disk: $(df -h / | tail -1 | awk '{print $3"/"$2" ("$5")"}')"
echo "GPU: $(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)%"
echo

echo "6. Recent Errors:"
docker compose logs --tail=5 nginx | grep -i error || echo "No recent errors"
EOF

chmod +x ~/diagnose-class.sh
```

### 로그 분석 도구
```bash
# 에러 로그 필터링
docker compose logs nginx | grep -E "(error|Error|ERROR|40[0-9]|50[0-9])" | tail -10

# 액세스 패턴 분석
docker compose logs nginx | grep "GET /class/" | awk '{print $7}' | sort | uniq -c | sort -nr

# 응답 시간 분석
docker compose logs nginx | grep "GET /class/" | awk '{print $(NF-1)}' | grep -o '[0-9.]*' | sort -n
```

## 📊 모니터링 설정

### 실시간 모니터링
```bash
# 실시간 로그 모니터링 (별도 터미널)
watch -n 5 'docker compose logs --tail=5 nginx | grep -E "(error|Error)"'

# 실시간 리소스 모니터링
watch -n 2 'docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"'

# 실시간 웹 접근 테스트
watch -n 10 'curl -s -o /dev/null -w "HTTP: %{http_code} | Time: %{time_total}s\n" http://10.231.59.251/class/'
```

### 알림 설정 (향후)
```bash
# 서비스 다운 알림
cat > ~/monitor-class.sh << 'EOF'
#!/bin/bash
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://10.231.59.251/class/)
if [ $RESPONSE -ne 200 ]; then
    echo "ALERT: Class service is down (HTTP $RESPONSE)" | mail -s "Service Alert" admin@example.com
fi
EOF

# cron에 추가 (5분마다 체크)
# */5 * * * * /home/menamiji/monitor-class.sh
```

## 🛠️ 고급 트러블슈팅

### 네트워크 문제 진단
```bash
# 포트 스캔
nmap -p 80,3000,11434 10.231.59.251

# DNS 해결
nslookup 10.231.59.251

# 라우팅 확인
traceroute 10.231.59.251

# 방화벽 규칙 확인
sudo iptables -L | grep -E "(80|3000|11434)"
```

### Docker 네트워크 문제
```bash
# Docker 네트워크 목록
docker network ls

# 네트워크 상세 정보
docker network inspect docker-services_ollama-network

# 컨테이너 간 통신 테스트
docker exec nginx ping ollama
docker exec openwebui curl http://ollama:11434
```

### 파일 시스템 문제
```bash
# 디스크 오류 확인
sudo dmesg | grep -i error | tail -10

# 파일 시스템 점검
sudo fsck -n /dev/sda1  # 읽기 전용 모드

# inode 사용량 확인
df -i

# 대용량 파일 찾기
find ~/docker-services -type f -size +100M -exec ls -lh {} \;
```

## 🔄 복구 절차

### 데이터 복구
```bash
# 1. 서비스 중지
cd ~/docker-services && docker compose down

# 2. 백업에서 복원
BACKUP_DATE="20250904_140000"  # 예시 날짜
tar -xzf ~/backups/class/$BACKUP_DATE/source.tar.gz -C ~/
tar -xzf ~/backups/class/$BACKUP_DATE/deployed.tar.gz -C ~/

# 3. 권한 수정
sudo chown -R menamiji:docker ~/docker-services/

# 4. 서비스 재시작
docker compose up -d

# 5. 상태 확인
docker compose ps
curl -I http://10.231.59.251/class/
```

### 설정 복구
```bash
# nginx 설정 복구
cp ~/backups/class/latest/default.conf ~/docker-services/services/nginx/conf/
docker compose restart nginx

# Docker Compose 복구
git checkout HEAD -- docker-compose.yml

# 환경 변수 복구
git checkout HEAD -- .env
```

## 📞 에스컬레이션 절차

### 문제 분류
1. **P1 (긴급)**: 서비스 완전 다운, 데이터 손실
2. **P2 (높음)**: 기능 일부 불가, 성능 심각한 저하
3. **P3 (보통)**: 기능 제한적 이슈, 경미한 성능 문제
4. **P4 (낮음)**: 개선 사항, 문서 업데이트

### 문제 보고 템플릿
```
제목: [P1/P2/P3/P4] 문제 요약

발생 시간: YYYY-MM-DD HH:MM
영향 범위: 전체/부분
증상: 구체적인 문제 설명

재현 단계:
1. 
2. 
3. 

에러 메시지:
```

시도한 해결 방법:
- 

시스템 정보:
- OS: Ubuntu 24.04.3
- Docker: [버전]
- 최근 변경사항: [있다면]
```

### 지원 연락처
- **긴급 상황**: 시스템 관리자
- **기술 문의**: 개발팀
- **인프라 문의**: DevOps 팀

---
*트러블슈팅 가이드 버전: 1.0*
*최종 업데이트: 2025-09-04*