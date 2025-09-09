#!/bin/bash

cd ~/docker-services/projects/class/frontend

echo "Pulling latest code..."
git pull origin main

echo "Building Flutter app..."
flutter build web --base-href="/class/"

echo "Deploying..."
cp -r build/web/* ../../../data/apps/class/

echo "Done! Check: http://10.231.59.251/class/"