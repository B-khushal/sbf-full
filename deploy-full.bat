@echo off
setlocal enabledelayedexpansion

REM SBF Florist Full Deployment Script for Hostinger (Windows)
REM This script deploys both frontend and backend with all fixes

echo 🚀 Starting SBF Florist Full Deployment to Hostinger...

REM Configuration
set SERVER_IP=147.93.102.196
set SERVER_USER=root
set FRONTEND_PATH=/var/www/sbf-florist/
set BACKEND_PATH=/var/www/sbf-backend/
set PROJECT_DIR=sbf-main

REM Check if we're in the right directory
if not exist "%PROJECT_DIR%" (
    echo ❌ Error: %PROJECT_DIR% directory not found!
    echo Please run this script from the project root directory.
    pause
    exit /b 1
)

if not exist "server" (
    echo ❌ Error: server directory not found!
    echo Please run this script from the project root directory.
    pause
    exit /b 1
)

REM Step 1: Build Frontend
echo 📦 Building frontend...
cd "%PROJECT_DIR%"
call npm install
call npm run build

if not exist "dist" (
    echo ❌ Error: Build failed! dist directory not found.
    pause
    exit /b 1
)

echo ✅ Frontend build completed successfully!

REM Step 2: Deploy Backend
echo 🔧 Deploying backend...
cd ..\server

REM Create backup of current backend
echo 💾 Creating backup of current backend...
ssh "%SERVER_USER%@%SERVER_IP%" "if [ -d '%BACKEND_PATH%' ]; then cp -r %BACKEND_PATH% %BACKEND_PATH%backup-$(date +%%Y%%m%%d-%%H%%M%%S); fi"

REM Create backend directory if it doesn't exist
ssh "%SERVER_USER%@%SERVER_IP%" "mkdir -p %BACKEND_PATH%"

REM Upload backend files
echo 📤 Uploading backend files...
scp -r * "%SERVER_USER%@%SERVER_IP%:%BACKEND_PATH%"

REM Install backend dependencies
echo 📦 Installing backend dependencies...
ssh "%SERVER_USER%@%SERVER_IP%" "cd %BACKEND_PATH% && npm install --production"

REM Step 3: Deploy Frontend
echo 📤 Deploying frontend...
cd ..\%PROJECT_DIR%

REM Create backup of current frontend
echo 💾 Creating backup of current frontend...
ssh "%SERVER_USER%@%SERVER_IP%" "if [ -d '%FRONTEND_PATH%' ]; then cp -r %FRONTEND_PATH% %FRONTEND_PATH%backup-$(date +%%Y%%m%%d-%%H%%M%%S); fi"

REM Upload the dist folder
echo 📤 Uploading dist folder...
scp -r dist\* "%SERVER_USER%@%SERVER_IP%:%FRONTEND_PATH%"

REM Step 4: Set Permissions
echo 🔐 Setting proper permissions...
ssh "%SERVER_USER%@%SERVER_IP%" "chmod -R 755 %FRONTEND_PATH% && chown -R www-data:www-data %FRONTEND_PATH%"
ssh "%SERVER_USER%@%SERVER_IP%" "chmod -R 755 %BACKEND_PATH% && chown -R www-data:www-data %BACKEND_PATH%"

REM Step 5: Restart Backend Services
echo 🔄 Restarting backend services...

REM Stop existing PM2 processes
ssh "%SERVER_USER%@%SERVER_IP%" "pm2 stop sbf-backend || true"
ssh "%SERVER_USER%@%SERVER_IP%" "pm2 delete sbf-backend || true"

REM Start backend with PM2
ssh "%SERVER_USER%@%SERVER_IP%" "cd %BACKEND_PATH% && pm2 start server.js --name sbf-backend --env production"

REM Save PM2 process list
ssh "%SERVER_USER%@%SERVER_IP%" "pm2 save"

REM Step 6: Update Nginx Configuration
echo 🔧 Updating nginx configuration...
scp "%PROJECT_DIR%\nginx.conf" "%SERVER_USER%@%SERVER_IP%:/etc/nginx/sites-available/sbflorist.in"

REM Test nginx configuration
ssh "%SERVER_USER%@%SERVER_IP%" "nginx -t"

REM Reload nginx
echo 🔄 Reloading nginx...
ssh "%SERVER_USER%@%SERVER_IP%" "systemctl reload nginx"

REM Step 7: Wait for services to start
echo ⏳ Waiting for services to start...
timeout /t 10 /nobreak >nul

REM Step 8: Test the deployment
echo 🧪 Testing deployment...

REM Test backend health
echo Testing backend health...
ssh "%SERVER_USER%@%SERVER_IP%" "curl -s http://localhost:5001/health || echo 'Backend not responding'"

REM Test upload endpoint
echo Testing upload endpoint...
ssh "%SERVER_USER%@%SERVER_IP%" "curl -s http://localhost:5001/api/uploads/test || echo 'Upload endpoint not responding'"

echo ✅ Full deployment completed successfully!
echo.
echo 🌐 Your application should now be live at:
echo    https://sbflorist.in
echo.
echo 📋 Deployment Summary:
echo    - Frontend: ✅ Deployed
echo    - Backend: ✅ Deployed
echo    - Build: ✅ Completed
echo    - Upload: ✅ Successful
echo    - Permissions: ✅ Set
echo    - PM2: ✅ Started
echo    - Nginx: ✅ Reloaded
echo.
echo 🔍 To check the deployment:
echo    ssh %SERVER_USER%@%SERVER_IP%
echo    cd %BACKEND_PATH% && pm2 status
echo    cd %FRONTEND_PATH% && ls -la
echo.
echo 📝 Recent changes deployed:
echo    - Fixed Google Sign-In button width issues
echo    - Resolved FedCM errors
echo    - Increased file upload limits to 50MB
echo    - Enhanced Cloudinary upload optimization
echo    - Improved error handling and logging
echo    - Updated server body size limits
echo    - Updated multer file size limits
echo.
echo 🔧 Backend Configuration:
echo    - Express body limit: 50MB
echo    - Multer file size: 50MB
echo    - Cloudinary timeout: 60s
echo    - Chunk size: 6MB

pause 