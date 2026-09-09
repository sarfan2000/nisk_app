@echo off
echo ========================================================
echo        NISK APP - PLATFORM INITIALIZATION
echo ========================================================
echo.
echo Installing Backend Dependencies...
cd backend
call npm install
echo.
echo Initializing Database Seed Data...
call node seed.js
echo.
echo Starting Backend Server on Port 5000...
start cmd /k "node server.js"
cd ..
echo.
echo Backend Running!
echo.
echo Initializing Flutter Environment...
cd mobile
call flutter create .
call flutter pub get
echo.
echo To run the mobile app, ensure your emulator is active and run:
echo cd mobile 
echo flutter run
echo.
pause
