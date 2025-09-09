#!/bin/bash

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR=~/backups/class/$DATE

mkdir -p $BACKUP_DIR

echo "Creating backup: $BACKUP_DIR"

# 소스코드 백업
echo "Backing up source code..."
tar -czf $BACKUP_DIR/source.tar.gz ~/docker-services/projects/class/

# 배포 파일 백업
echo "Backing up deployed files..."
tar -czf $BACKUP_DIR/deployed.tar.gz ~/docker-services/data/apps/class/

# 설정 파일 백업
echo "Backing up configurations..."
cp ~/docker-services/services/nginx/conf/default.conf $BACKUP_DIR/
cp ~/docker-services/docker-compose.yml $BACKUP_DIR/
cp ~/docker-services/.env $BACKUP_DIR/

# 백업 목록 생성
echo "Creating backup manifest..."
cat > $BACKUP_DIR/manifest.txt << EOF
Class Project Backup
Created: $DATE
Contents:
- source.tar.gz: Flutter source code
- deployed.tar.gz: Deployed web files
- default.conf: nginx configuration
- docker-compose.yml: Docker services
- .env: Environment variables
EOF

echo "Backup completed: $BACKUP_DIR"
echo "Size: $(du -sh $BACKUP_DIR | cut -f1)"