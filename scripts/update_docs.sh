#!/bin/bash

# =======================================================
# AI 문서 자동 업데이트 및 GitHub 백업 스크립트
# 사용법: ./scripts/update_docs.sh "커밋 메시지"
# =======================================================

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 현재 시간
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
TODAY=$(date '+%Y-%m-%d')

echo -e "${BLUE}🤖 AI 문서 자동 업데이트 시스템${NC}"
echo -e "${BLUE}=================================${NC}"
echo -e "시작 시간: ${TIMESTAMP}"
echo ""

# 커밋 메시지 확인
if [ -z "$1" ]; then
    COMMIT_MSG="docs: AI 자동 문서 업데이트 (${TIMESTAMP})"
    echo -e "${YELLOW}⚠️  커밋 메시지가 없어 기본 메시지 사용: ${COMMIT_MSG}${NC}"
else
    COMMIT_MSG="$1"
    echo -e "${GREEN}✅ 커밋 메시지: ${COMMIT_MSG}${NC}"
fi

echo ""

# Git 상태 확인
echo -e "${BLUE}📋 Git 상태 확인...${NC}"
if ! git status &> /dev/null; then
    echo -e "${RED}❌ Git 저장소가 아닙니다!${NC}"
    exit 1
fi

# docs 폴더 존재 확인
if [ ! -d "docs/obsidian_backup" ]; then
    echo -e "${YELLOW}📁 docs/obsidian_backup 폴더를 생성합니다...${NC}"
    mkdir -p docs/obsidian_backup
fi

# 변경사항 추가
echo -e "${BLUE}📝 변경사항을 Git에 추가...${NC}"
git add docs/
git add scripts/

# 변경사항이 있는지 확인
if git diff --staged --quiet; then
    echo -e "${YELLOW}ℹ️  변경사항이 없습니다.${NC}"
else
    echo -e "${GREEN}✅ 변경사항 발견 - 커밋을 진행합니다.${NC}"
    
    # 커밋
    echo -e "${BLUE}💾 커밋 진행...${NC}"
    git commit -m "${COMMIT_MSG}"
    
    # GitHub에 푸시
    echo -e "${BLUE}🚀 GitHub에 푸시...${NC}"
    git push origin main
    
    echo ""
    echo -e "${GREEN}🎉 성공적으로 완료되었습니다!${NC}"
    echo -e "${GREEN}📄 문서가 GitHub에 백업되었습니다.${NC}"
fi

echo ""
echo -e "${BLUE}📊 현재 상태:${NC}"
echo -e "   - 날짜: ${TODAY}"
echo -e "   - 시간: ${TIMESTAMP}"
echo -e "   - 저장소: GitHub (menamiji/class)"
echo -e "   - 백업 위치: docs/obsidian_backup/"

echo ""
echo -e "${GREEN}✨ AI 문서 업데이트 완료!${NC}"



