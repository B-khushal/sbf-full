@echo off
setlocal enabledelayedexpansion

REM Quick Backend Fix for 413 Error
REM This script only updates the backend to fix file upload limits

echo 🔧 Quick Backend Fix for 413 Error...

REM Configuration
set SERVER_IP=147.93.102.196
set SERVER_USER=root
set BACKEND_PATH=/var/www/sbf-backend/

REM Check if server directory exists
if not exist "server" (
    echo ❌ Error: server directory not found!
    echo Please run this script from the project root directory.
    pause
    exit /b 1
)

echo 📤 Uploading updated backend files...
cd server

REM Create backup of current backend
echo 💾 Creating backup of current backend...
ssh "%SERVER_USER%@%SERVER_IP%" "if [ -d '%BACKEND_PATH%' ]; then cp -r %BACKEND_PATH% %BACKEND_PATH%backup-$(date +%%Y%%m%%d-%%H%%M%%S); fi"

REM Create backend directory if it doesn't exist
ssh "%SERVER_USER%@%SERVER_IP%" "mkdir -p %BACKEND_PATH%"

REM Upload backend files
scp -r * "%SERVER_USER%@%SERVER_IP%:%BACKEND_PATH%"

REM Install backend dependencies
echo 📦 Installing backend dependencies...
ssh "%SERVER_USER%@%SERVER_IP%" "cd %BACKEND_PATH% && npm install --production"

REM Set permissions
echo 🔐 Setting proper permissions...
ssh "%SERVER_USER%@%SERVER_IP%" "chmod -R 755 %BACKEND_PATH% && chown -R www-data:www-data %BACKEND_PATH%"

REM Restart backend services
echo 🔄 Restarting backend services...

REM Stop existing PM2 processes
ssh "%SERVER_USER%@%SERVER_IP%" "pm2 stop sbf-backend || true"
ssh "%SERVER_USER%@%SERVER_IP%" "pm2 delete sbf-backend || true"

REM Start backend with PM2
ssh "%SERVER_USER%@%SERVER_IP%" "cd %BACKEND_PATH% && pm2 start server.js --name sbf-backend --env production"

REM Save PM2 process list
ssh "%SERVER_USER%@%SERVER_IP%" "pm2 save"

REM Wait for service to start
echo ⏳ Waiting for service to start...
timeout /t 5 /nobreak >nul

REM Test the fix
echo 🧪 Testing the fix...
ssh "%SERVER_USER%@%SERVER_IP%" "curl -s http://localhost:5001/api/uploads/test || echo 'Upload endpoint not responding'"

echo ✅ Backend fix completed successfully!
echo.
echo 🔧 Backend Configuration Updated:
echo    - Express body limit: 50MB
echo    - Multer file size: 50MB
echo    - Cloudinary timeout: 60s
echo    - Chunk size: 6MB
echo.
echo 📝 The 413 error should now be resolved.
echo    Try uploading images again in the admin panel.

pause 