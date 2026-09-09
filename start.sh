#!/bin/bash
echo "========================================================"
echo "       NISK APP - PLATFORM INITIALIZATION (LINUX/MAC)"
echo "========================================================"
echo ""
echo "Installing Backend Dependencies..."
cd backend
npm install
echo ""
echo "Initializing Database Seed Data..."
node seed.js
echo ""
echo "Starting Backend Server on Port 5000 in background..."
node server.js &
cd ..
echo ""
echo "Backend Running!"
echo ""
echo "Initializing Flutter Environment..."
cd mobile
flutter create .
flutter pub get
echo ""
echo "To run the mobile app, ensure your emulator is active and run:"
echo "cd mobile"
echo "flutter run"
echo ""
