#!/bin/bash

# Exit on any error
set -e

echo "🚀 Starting deployment to Hostinger..."

# Variables
DEPLOY_PATH="/home/u947451575/domains/sbflorist.in"
BACKEND_PATH="$DEPLOY_PATH/backend"
FRONTEND_PATH="$DEPLOY_PATH/public_html"
LOG_DIR="/home/u947451575/logs/sbf"

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p "$BACKEND_PATH"
mkdir -p "$LOG_DIR"

# Stop existing PM2 process
echo "🛑 Stopping existing PM2 process..."
pm2 stop sbf-backend || true
pm2 delete sbf-backend || true

# Kill any existing Node processes
echo "🔪 Killing existing Node processes..."
pkill -f "node" || true

# Copy backend files
echo "📋 Copying backend files..."
cp -r ./server/* "$BACKEND_PATH/"
cp ecosystem.config.js "$BACKEND_PATH/"

# Install backend dependencies
echo "📦 Installing backend dependencies..."
cd "$BACKEND_PATH"
npm install --production

# Build and copy frontend files
echo "🏗️ Building frontend..."
cd ../sbf-main
npm install
npm run build
cp -r dist/* "$FRONTEND_PATH/"

# Start the backend with PM2
echo "🚀 Starting backend with PM2..."
cd "$BACKEND_PATH"
pm2 start ecosystem.config.js --env production

# Wait for server to start
echo "⏳ Waiting for server to start..."
sleep 5

# Check if server is running
if pm2 show sbf-backend | grep -q "online"; then
    echo "✅ Deployment successful! Server is running."
else
    echo "❌ Deployment failed! Server is not running."
    pm2 logs sbf-backend --lines 50
    exit 1
fi

# Save PM2 process list
echo "💾 Saving PM2 process list..."
pm2 save

echo "✨ Deployment complete!" 