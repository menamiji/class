#!/bin/bash

# Class 프로젝트 웹 빌드 스크립트

echo "🏗️  Class 프로젝트를 웹용으로 빌드합니다..."

# 프로젝트 디렉토리로 이동
cd "$(dirname "$0")/.."

# 환경변수 설정 (운영용)
SUPABASE_URL="https://znocjtfrtxwulyngzqfy.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpub2NqdGZydHh3dWx5bmd6cWZ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjU3NzU3ODEsImV4cCI6MjA0MTM1MTc4MX0.JRtBpgcNYG9hCO-aQCeizGnU5gNLSBjrW6pElgHgKcM"

echo "📦 의존성을 설치합니다..."
flutter pub get

echo "🏗️  웹용 빌드를 시작합니다..."
echo "🔧 빌드 설정:"
echo "  - Base href: /class/"
echo "  - SUPABASE_URL: $SUPABASE_URL"
echo "  - SUPABASE_ANON_KEY: ${SUPABASE_ANON_KEY:0:20}..."

flutter build web \
  --base-href="/class/" \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --release

echo "✅ 빌드가 완료되었습니다!"
echo "📁 빌드 파일 위치: build/web/"
echo ""
echo "📊 빌드 결과:"
ls -la build/web/ | head -10
echo ""
echo "💾 총 크기:"
du -sh build/web/

echo ""
echo "🚀 배포하려면 다음 명령어를 실행하세요:"
echo "ssh menamiji@10.231.59.251 '~/deploy-class.sh'"
