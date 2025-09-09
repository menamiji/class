# Ubuntu Server 운영 가이드

## 시스템 개요
### 기본 정보
- **서버명**: gaoni
- **OS**: Ubuntu Server 24.04.3 LTS
- **IP 주소**: 10.231.59.251
- **사용자**: menamiji
- **GPU**: NVIDIA RTX 4090
- **스토리지**: 시놀로지 NAS (42TB, NFSv4.1)
- **외부 도메인**: info.pocheonil.hs.kr (Cloudflare 터널)

### 네트워크 접근
```bash
# SSH 접속
ssh menamiji@10.231.59.251

# 내부 네트워크 접근
http://10.231.59.251/          # 메인 페이지
http://10.231.59.251:3000      # OpenWebUI
http://10.231.59.251/class/    # Class 프로젝트

# 외부 접근 (Cloudflare 터널)
https://info.pocheonil.hs.kr/         # 메인 페이지
https://info.pocheonil.hs.kr/class/   # Class 프로젝트
```

## Docker 서비스 관리

### 현재 실행 중인 서비스
| 서비스 | 포트 | 용도 | 상태 확인 |
|--------|------|------|-----------|
| nginx | 80 | 웹서버 | `curl http://localhost` |
| ollama | 11434 | AI 모델 | `curl http://localhost:11434` |
| openwebui | 3000 | 웹 인터페이스 | `curl http://localhost:3000` |
| cloudflared | - | 터널 서비스 | `docker compose logs cloudflared` |

### 필수 관리 명령어
```bash
# 작업 디렉터리로 이동
cd ~/docker-services

# 서비스 상태 확인
docker compose ps

# 모든 서비스 시작
docker compose up -d

# 특정 서비스 재시작
docker compose restart nginx
docker compose restart ollama
docker compose restart openwebui
docker compose restart cloudflared

# 서비스 중지
docker compose down

# 로그 확인
docker compose logs -f nginx
docker compose logs -f ollama --tail=50
docker compose logs -f cloudflared

# 리소스 사용량 확인
docker stats
```

### Cloudflare 터널 관리
```bash
# 터널 상태 확인
docker compose logs cloudflared

# 터널 연결 상태 확인 (성공 시 "Registered tunnel connection" 메시지)
docker compose logs cloudflared | grep "Registered tunnel connection"

# 외부 접근 테스트
curl -I https://info.pocheonil.hs.kr/
curl -I https://info.pocheonil.hs.kr/class/

# 터널 재시작
docker compose restart cloudflared

# 터널 설정 확인
cat .env | grep CLOUDFLARE_TUNNEL_TOKEN
```

### 서비스별 트러블슈팅

#### nginx 문제 해결
```bash
# 설정 파일 확인
cat ~/docker-services/services/nginx/conf/default.conf

# 문법 검사
docker exec nginx nginx -t

# 설정 리로드
docker exec nginx nginx -s reload

# 파일 권한 확인
ls -la ~/docker-services/data/apps/

# 권한 수정
sudo chown -R menamiji:docker ~/docker-services/data/apps/
```

#### Cloudflare 터널 문제 해결
```bash
# 터널 연결 상태 확인
docker compose logs cloudflared | tail -20

# 터널 토큰 확인
echo $CLOUDFLARE_TUNNEL_TOKEN

# nginx 연결 테스트 (컨테이너 내부에서)
docker exec cloudflared wget -qO- http://nginx:80 | head -5

# 터널 재시작
docker compose restart cloudflared

# 외부 도메인 DNS 확인
nslookup info.pocheonil.hs.kr
```

#### ollama 문제 해결
```bash
# GPU 사용 확인
nvidia-smi

# 모델 목록 확인
docker exec ollama ollama list

# 모델 다운로드 (예시)
docker exec ollama ollama pull llama2

# NAS 마운트 확인
df -h | grep nas
mount | grep nfs
```

#### OpenWebUI 문제 해결
```bash
# 데이터 디렉터리 확인
ls -la ~/docker-services/data/openwebui/

# 설정 리셋 (주의: 데이터 삭제됨)
docker compose down openwebui
sudo rm -rf ~/docker-services/data/openwebui/*
docker compose up -d openwebui
```

## 시스템 모니터링

### 일일 체크리스트
```bash
# 1. 시스템 상태 확인
uptime
df -h
free -h
nvidia-smi

# 2. Docker 서비스 상태
cd ~/docker-services && docker compose ps

# 3. 로그 확인
docker compose logs --tail=10 nginx
docker compose logs --tail=10 ollama
docker compose logs --tail=10 cloudflared

# 4. 네트워크 연결 확인 (내부)
curl -s http://10.231.59.251/ | head -5
curl -s http://10.231.59.251:3000 | head -5

# 5. 외부 접근 확인 (Cloudflare 터널)
curl -s https://info.pocheonil.hs.kr/ | head -5
curl -s https://info.pocheonil.hs.kr/class/ | head -5
```

### 성능 모니터링
```bash
# CPU/메모리 사용량
htop

# 디스크 I/O
iotop

# 네트워크 연결
netstat -tulnp | grep -E "(80|3000|11434)"

# Docker 컨테이너 리소스
docker stats --no-stream

# GPU 상태 (5초마다 갱신)
watch -n 5 nvidia-smi

# Cloudflare 터널 연결 수 확인
docker compose logs cloudflared | grep "Registered tunnel connection" | wc -l
```

## 백업 및 복구

### 중요 파일 백업 위치
- **Docker 설정**: `~/docker-services/`
- **웹앱 데이터**: `~/docker-services/data/apps/`
- **OpenWebUI 데이터**: `~/docker-services/data/openwebui/`
- **Ollama 모델**: NAS (`/mnt/nas-ollama-models`)
- **Cloudflare 설정**: `~/docker-services/.env` (터널 토큰)

### 백업 스크립트
```bash
#!/bin/bash
# backup.sh
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="~/backups/$BACKUP_DATE"

mkdir -p $BACKUP_DIR

# Docker 설정 백업
tar -czf $BACKUP_DIR/docker-services.tar.gz ~/docker-services/

# 중요 데이터 백업 (NAS 제외)
tar -czf $BACKUP_DIR/app-data.tar.gz ~/docker-services/data/

# 환경변수 백업 (Cloudflare 토큰 포함)
cp ~/docker-services/.env $BACKUP_DIR/

echo "Backup completed: $BACKUP_DIR"
```

### 복구 절차
```bash
# 1. Docker 서비스 중지
cd ~/docker-services && docker compose down

# 2. 백업에서 복원
tar -xzf backup_file.tar.gz -C ~/

# 3. 권한 수정
sudo chown -R menamiji:docker ~/docker-services/

# 4. 환경변수 복원
cp backup/.env ~/docker-services/

# 5. 서비스 재시작
docker compose up -d

# 6. 상태 확인
docker compose ps
curl -I https://info.pocheonil.hs.kr/
```

## 보안 관리

### SSH 보안 설정
```bash
# SSH 키 확인
ls -la ~/.ssh/

# 실패한 로그인 시도 확인
sudo grep "Failed password" /var/log/auth.log | tail -10

# 현재 SSH 연결 확인
who
```

### 방화벽 관리 (Cloudflare 터널 사용 시)
```bash
# 현재 방화벽 상태
sudo ufw status

# Cloudflare 터널 사용 시 외부 포트 차단 가능
sudo ufw deny 80     # HTTP (터널로만 접근)
sudo ufw deny 3000   # OpenWebUI (터널로만 접근)
sudo ufw allow 22    # SSH만 허용

# 방화벽 활성화
sudo ufw enable
```

### Cloudflare 보안
```bash
# 터널 토큰 권한 확인
chmod 600 ~/docker-services/.env

# 터널 토큰이 Git에 노출되지 않도록
echo ".env" >> ~/docker-services/.gitignore

# 터널 연결 로그 모니터링
docker compose logs cloudflared | grep -E "(connection|error)" | tail -10
```

### Docker 보안
```bash
# 취약한 컨테이너 확인
docker security scan (Docker Desktop 필요)

# 불필요한 이미지 정리
docker image prune -f

# 사용하지 않는 컨테이너 정리
docker container prune -f
```

## 네트워크 설정

### Cloudflare 터널 구성
```bash
# 터널 설정 정보
# 도메인: info.pocheonil.hs.kr
# 서비스: nginx:80
# 터널 ID: f06eff80-6393-440e-8d4b-d0cdcd9debf2

# docker-compose.yml 설정 확인
grep -A 10 "cloudflared:" ~/docker-services/docker-compose.yml

# 환경변수 확인
grep CLOUDFLARE_TUNNEL_TOKEN ~/docker-services/.env
```

### NAS 마운트 관리
```bash
# 현재 마운트 상태
mount | grep nfs
df -h | grep nas

# 마운트 해제
sudo umount /mnt/nas-ollama-models

# 다시 마운트
sudo mount -t nfs4 [NAS_IP]:/volume1/ollama-models /mnt/nas-ollama-models

# 자동 마운트 설정 확인
cat /etc/fstab | grep nas
```

### 네트워크 진단
```bash
# 네트워크 인터페이스 확인
ip addr show

# 라우팅 테이블
ip route

# DNS 확인
nslookup google.com
nslookup info.pocheonil.hs.kr

# 포트 확인
ss -tulnp | grep -E "(80|3000|11434)"

# Cloudflare 연결 확인
ping 198.41.192.227  # Cloudflare edge server
```

## 업데이트 및 유지보수

### 시스템 업데이트
```bash
# 패키지 업데이트
sudo apt update && sudo apt upgrade -y

# Docker 버전 확인
docker --version
docker compose --version

# 재부팅 필요 여부 확인
if [ -f /var/run/reboot-required ]; then
    echo "Reboot required"
fi
```

### Docker 이미지 업데이트
```bash
cd ~/docker-services

# 새 이미지 가져오기
docker compose pull

# 서비스 재시작 (새 이미지 적용)
docker compose up -d

# 사용하지 않는 이미지 정리
docker image prune -f
```

### Cloudflare 터널 업데이트
```bash
# cloudflared 이미지 업데이트
docker compose pull cloudflared
docker compose up -d cloudflared

# 터널 연결 상태 확인
docker compose logs cloudflared | tail -10
```

## 비상 상황 대응

### 서비스 전체 다운 시
```bash
# 1. Docker 데몬 상태 확인
sudo systemctl status docker

# 2. Docker 재시작
sudo systemctl restart docker

# 3. 서비스 재시작
cd ~/docker-services && docker compose up -d

# 4. 상태 확인
docker compose ps
curl -I https://info.pocheonil.hs.kr/
```

### Cloudflare 터널 다운 시
```bash
# 1. 터널 로그 확인
docker compose logs cloudflared | tail -20

# 2. 터널 재시작
docker compose restart cloudflared

# 3. 네트워크 연결 확인
ping 198.41.192.227

# 4. 내부 서비스 확인
curl -I http://10.231.59.251/

# 5. 터널 재연결 확인
docker compose logs cloudflared | grep "Registered tunnel connection"
```

### 디스크 용량 부족 시
```bash
# 1. 용량 확인
df -h

# 2. 큰 파일 찾기
sudo du -h / | sort -rh | head -20

# 3. Docker 정리
docker system prune -af

# 4. 로그 정리
sudo journalctl --vacuum-time=7d
```

### GPU 인식 안될 시
```bash
# 1. 드라이버 확인
nvidia-smi

# 2. Docker GPU 설정 확인
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi

# 3. 컨테이너 재시작
docker compose restart ollama
```

## 성능 최적화

### Docker 최적화
```bash
# Docker 리소스 제한 설정 (docker-compose.yml)
services:
  ollama:
    deploy:
      resources:
        limits:
          memory: 8G
        reservations:
          memory: 4G
```

### Cloudflare 터널 최적화
```bash
# 터널 성능 확인
docker compose logs cloudflared | grep "quic-go"

# UDP 버퍼 사이즈 최적화 (시스템 레벨)
echo 'net.core.rmem_max = 7340032' | sudo tee -a /etc/sysctl.conf
echo 'net.core.wmem_max = 7340032' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### 시스템 최적화
```bash
# 스왑 사용량 확인
swapon --show

# 파일 디스크립터 제한 확인
ulimit -n

# 시스템 부하 확인
uptime
load_average_check=$(uptime | awk '{print $10}' | cut -d',' -f1)
```

## 연락처 및 지원

### 중요 링크
- **GitHub 저장소**: https://github.com/menamiji/class.git
- **외부 접근**: https://info.pocheonil.hs.kr/
- **Ollama 문서**: https://ollama.ai/docs
- **Cloudflare 문서**: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
- **Docker Compose 문서**: https://docs.docker.com/compose/

### 로그 파일 위치
- **시스템 로그**: `/var/log/syslog`
- **인증 로그**: `/var/log/auth.log`
- **Docker 로그**: `docker compose logs [service]`
- **Cloudflare 로그**: `docker compose logs cloudflared`

---
*최종 업데이트: 2025-09-05*
*문서 버전: 1.1 (Cloudflare 터널 추가)*
## Class 하위시스템(개발 연계)

### 개요
- 목적: 수업 실습파일 배포/제출 및 향후 AI 분석 연계
- 저장 아키텍처: 파일은 NAS 직접 저장, 메타데이터/인증은 Supabase 사용
- 참고 문서: `20501_class/개발문서 (20250908_1).md`

### 저장 경로(NAS)
- 콘텐츠: `/mnt/nas-class/content/<subject>/<category>/<item>/<filename>`
- 제출: `/mnt/nas-class/submissions/<YYYYMMDD>/<student_no>/<filename>`
- 권한 권고: 디렉터리 775, 파일 664, 소유자 `menamiji:docker`

### 인증/권한(Supabase)
- Google OAuth, 기본 도메인: `@pocheonil.hs.kr`
- 롤: `student`, `teacher`, `admin` (초기 관리자: `menamiji@pocheonil.hs.kr`)

### 백엔드/API
- 베이스 경로: `/class/api`
- 백엔드: `file-service` (FastAPI, Docker 컨테이너) — nginx 프록시로 연결 예정
- 예시 프록시(nginx):
```nginx
location /class/api/ {
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_pass http://file-service:8000/;
}
```

### 운영 정책
- 제출 날짜 디렉터리: 항상 오늘자 `YYYYMMDD` 자동 생성(추후 설정으로 변경 가능)
- 파일 크기/확장자 제한: 없음(대용량은 프록시/백엔드 타임아웃 고려)

### 데이터 메타(예정)
- Supabase(Postgres) 테이블: `subjects`, `subject_contents`, `submissions`, `roles`
- 감사 로그: 업로드/삭제/다운로드 이벤트 기록 권장

## Class 연계 트러블슈팅 요약 (2025-09-08)
- 프록시 502: `docker network connect docker-services_default $(docker compose ps -q nginx)` → 이후 nginx에서 `curl -i http://file-service:8000/healthz` 200 확인
- 외부 530(업로드): cloudflared 설정 유지(`services/cloudflared/config.yml`)
  - `originRequest.disableChunkedEncoding: true`
  - `originRequest.http2Origin: false`
  - 타임아웃(read/write): 600s
- nginx 설정 핵심: 접두사 제거 후 프록시
  - `rewrite ^/class/api/(.*)$ /$1 break;`
  - `proxy_pass http://file-service:8000;`
- 점검: `curl -i https://info.pocheonil.hs.kr/class/api/healthz | head -10` 200

## Class 운영 퀵스타트(요약)
- 재기동 순서: `docker compose up -d nginx file-service cloudflared`
- 내부 헬스: `curl -i http://127.0.0.1/class/api/healthz | head -10`
- 외부 헬스: `curl -i "https://info.pocheonil.hs.kr/class/api/healthz?t=$(date +%s)" | head -10`
- 업로드 테스트: 토큰 발급 → Authorization 헤더로 업로드/목록/삭제
- Cloudflare: disableChunkedEncoding: true 유지, 터널 상태 로그 확인
