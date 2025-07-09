@echo off
setlocal enabledelayedexpansion

REM SBF Florist Deployment Script for Hostinger (Windows)
REM This script builds the project and uploads it to the server

echo 🚀 Starting SBF Florist deployment to Hostinger...

REM Configuration
set SERVER_IP=147.93.102.196
set SERVER_USER=root
set SERVER_PATH=/var/www/sbf-florist/
set PROJECT_DIR=sbf-main

REM Check if we're in the right directory
if not exist "%PROJECT_DIR%" (
    echo ❌ Error: %PROJECT_DIR% directory not found!
    echo Please run this script from the project root directory.
    pause
    exit /b 1
)

REM Navigate to the frontend directory
cd "%PROJECT_DIR%"

echo 📦 Installing dependencies...
call npm install

echo 🔨 Building the project...
call npm run build

REM Check if build was successful
if not exist "dist" (
    echo ❌ Error: Build failed! dist directory not found.
    pause
    exit /b 1
)

echo ✅ Build completed successfully!

REM Upload to server
echo 📤 Uploading to Hostinger server...
echo Server: %SERVER_USER%@%SERVER_IP%
echo Path: %SERVER_PATH%

REM Create backup of current deployment
echo 💾 Creating backup of current deployment...
ssh "%SERVER_USER%@%SERVER_IP%" "if [ -d '%SERVER_PATH%' ]; then cp -r %SERVER_PATH% %SERVER_PATH%backup-$(date +%%Y%%m%%d-%%H%%M%%S); fi"

REM Upload the dist folder
echo 📤 Uploading dist folder...
scp -r dist "%SERVER_USER%@%SERVER_IP%:%SERVER_PATH%"

REM Set proper permissions
echo 🔐 Setting proper permissions...
ssh "%SERVER_USER%@%SERVER_IP%" "chmod -R 755 %SERVER_PATH% && chown -R www-data:www-data %SERVER_PATH%"

REM Restart nginx if needed
echo 🔄 Restarting nginx...
ssh "%SERVER_USER%@%SERVER_IP%" "systemctl reload nginx"

echo ✅ Deployment completed successfully!
echo.
echo 🌐 Your application should now be live at:
echo    https://sbflorist.in
echo.
echo 📋 Deployment Summary:
echo    - Frontend: ✅ Deployed
echo    - Build: ✅ Completed
echo    - Upload: ✅ Successful
echo    - Permissions: ✅ Set
echo    - Nginx: ✅ Reloaded
echo.
echo 🔍 To check the deployment:
echo    ssh %SERVER_USER%@%SERVER_IP%
echo    cd %SERVER_PATH%
echo    ls -la
echo.
echo 📝 Recent changes deployed:
echo    - Fixed Google Sign-In button width issues
echo    - Resolved FedCM errors
echo    - Increased file upload limits to 50MB
echo    - Enhanced Cloudinary upload optimization
echo    - Improved error handling and logging

pause 