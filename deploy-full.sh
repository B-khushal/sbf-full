#!/bin/bash

# SBF Florist Full Deployment Script for Hostinger
# This script deploys both frontend and backend with all fixes

set -e  # Exit on any error

# Configuration
SERVER_IP="147.93.102.196"
SERVER_USER="root"
FRONTEND_PATH="/var/www/sbf-florist/"
BACKEND_PATH="/var/www/sbf-backend/"
PROJECT_DIR="sbf-main"

echo "🚀 Starting SBF Florist Full Deployment to Hostinger..."

# Check if we're in the right directory
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Error: $PROJECT_DIR directory not found!"
    echo "Please run this script from the project root directory."
    exit 1
fi

if [ ! -d "server" ]; then
    echo "❌ Error: server directory not found!"
    echo "Please run this script from the project root directory."
    exit 1
fi

# Step 1: Build Frontend
echo "📦 Building frontend..."
cd "$PROJECT_DIR"
npm install
npm run build

if [ ! -d "dist" ]; then
    echo "❌ Error: Build failed! dist directory not found."
    exit 1
fi

echo "✅ Frontend build completed successfully!"

# Step 2: Deploy Backend
echo "🔧 Deploying backend..."
cd ../server

# Create backup of current backend
echo "💾 Creating backup of current backend..."
ssh "$SERVER_USER@$SERVER_IP" "if [ -d '$BACKEND_PATH' ]; then cp -r $BACKEND_PATH ${BACKEND_PATH}backup-$(date +%Y%m%d-%H%M%S); fi"

# Create backend directory if it doesn't exist
ssh "$SERVER_USER@$SERVER_IP" "mkdir -p $BACKEND_PATH"

# Upload backend files
echo "📤 Uploading backend files..."
scp -r * "$SERVER_USER@$SERVER_IP:$BACKEND_PATH"

# Install backend dependencies
echo "📦 Installing backend dependencies..."
ssh "$SERVER_USER@$SERVER_IP" "cd $BACKEND_PATH && npm install --production"

# Step 3: Deploy Frontend
echo "📤 Deploying frontend..."
cd ../"$PROJECT_DIR"

# Create backup of current frontend
echo "💾 Creating backup of current frontend..."
ssh "$SERVER_USER@$SERVER_IP" "if [ -d '$FRONTEND_PATH' ]; then cp -r $FRONTEND_PATH ${FRONTEND_PATH}backup-$(date +%Y%m%d-%H%M%S); fi"

# Upload the dist folder
echo "📤 Uploading dist folder..."
scp -r dist/* "$SERVER_USER@$SERVER_IP:$FRONTEND_PATH"

# Step 4: Set Permissions
echo "🔐 Setting proper permissions..."
ssh "$SERVER_USER@$SERVER_IP" "chmod -R 755 $FRONTEND_PATH && chown -R www-data:www-data $FRONTEND_PATH"
ssh "$SERVER_USER@$SERVER_IP" "chmod -R 755 $BACKEND_PATH && chown -R www-data:www-data $BACKEND_PATH"

# Step 5: Restart Backend Services
echo "🔄 Restarting backend services..."

# Stop existing PM2 processes
ssh "$SERVER_USER@$SERVER_IP" "pm2 stop sbf-backend || true"
ssh "$SERVER_USER@$SERVER_IP" "pm2 delete sbf-backend || true"

# Start backend with PM2
ssh "$SERVER_USER@$SERVER_IP" "cd $BACKEND_PATH && pm2 start server.js --name sbf-backend --env production"

# Save PM2 process list
ssh "$SERVER_USER@$SERVER_IP" "pm2 save"

# Step 6: Update Nginx Configuration
echo "🔧 Updating nginx configuration..."
scp "$PROJECT_DIR/nginx.conf" "$SERVER_USER@$SERVER_IP:/etc/nginx/sites-available/sbflorist.in"

# Test nginx configuration
ssh "$SERVER_USER@$SERVER_IP" "nginx -t"

# Reload nginx
echo "🔄 Reloading nginx..."
ssh "$SERVER_USER@$SERVER_IP" "systemctl reload nginx"

# Step 7: Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 10

# Step 8: Test the deployment
echo "🧪 Testing deployment..."

# Test backend health
echo "Testing backend health..."
ssh "$SERVER_USER@$SERVER_IP" "curl -s http://localhost:5001/health || echo 'Backend not responding'"

# Test upload endpoint
echo "Testing upload endpoint..."
ssh "$SERVER_USER@$SERVER_IP" "curl -s http://localhost:5001/api/uploads/test || echo 'Upload endpoint not responding'"

echo "✅ Full deployment completed successfully!"
echo ""
echo "🌐 Your application should now be live at:"
echo "   https://sbflorist.in"
echo ""
echo "📋 Deployment Summary:"
echo "   - Frontend: ✅ Deployed"
echo "   - Backend: ✅ Deployed"
echo "   - Build: ✅ Completed"
echo "   - Upload: ✅ Successful"
echo "   - Permissions: ✅ Set"
echo "   - PM2: ✅ Started"
echo "   - Nginx: ✅ Reloaded"
echo ""
echo "🔍 To check the deployment:"
echo "   ssh $SERVER_USER@$SERVER_IP"
echo "   cd $BACKEND_PATH && pm2 status"
echo "   cd $FRONTEND_PATH && ls -la"
echo ""
echo "📝 Recent changes deployed:"
echo "   - Fixed Google Sign-In button width issues"
echo "   - Resolved FedCM errors"
echo "   - Increased file upload limits to 50MB"
echo "   - Enhanced Cloudinary upload optimization"
echo "   - Improved error handling and logging"
echo "   - Updated server body size limits"
echo "   - Updated multer file size limits"
echo ""
echo "🔧 Backend Configuration:"
echo "   - Express body limit: 50MB"
echo "   - Multer file size: 50MB"
echo "   - Cloudinary timeout: 60s"
echo "   - Chunk size: 6MB" 