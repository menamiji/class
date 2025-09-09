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