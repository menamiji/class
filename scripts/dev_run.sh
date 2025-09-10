#!/bin/bash

# Class 프로젝트 개발 실행 스크립트

echo "🚀 Class 프로젝트 개발 서버를 시작합니다..."

# 프로젝트 디렉토리로 이동
cd "$(dirname "$0")/.."

# 환경변수 설정 (개발용)
SUPABASE_URL="https://znocjtfrtxwulyngzqfy.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpub2NqdGZydHh3dWx5bmd6cWZ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NzMyMTAsImV4cCI6MjA2OTM0OTIxMH0.eOdI8Q3VTrb8HahP-wxlcnVOT0vFBaQA4dfQpcA2JqE"

echo "📦 의존성을 설치합니다..."
flutter pub get

echo "🌐 Chrome에서 Flutter 웹앱을 실행합니다..."
echo "🔧 환경변수:"
echo "  - SUPABASE_URL: $SUPABASE_URL"
echo "  - SUPABASE_ANON_KEY: ${SUPABASE_ANON_KEY:0:20}..."

flutter run -d chrome \
  --web-port=5173 \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
