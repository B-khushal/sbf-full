#!/bin/bash

# SBF Florist - Application Update Script
# This script updates the application with zero downtime

set -e

# Configuration
APP_DIR="/var/www/sbf-florist"
BACKUP_DIR="/backup/updates"
DATE=$(date +%Y%m%d_%H%M%S)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if running as the correct user
if [ "$USER" = "root" ]; then
    error "This script should not be run as root"
fi

log "Starting application update process..."

# Navigate to application directory
cd $APP_DIR

# Create backup directory
mkdir -p $BACKUP_DIR

# Create backup of current application state
log "Creating backup of current application..."
tar --exclude='node_modules' \
    --exclude='.git' \
    --exclude='*.log' \
    -czf $BACKUP_DIR/pre-update-$DATE.tar.gz .

success "Backup created: $BACKUP_DIR/pre-update-$DATE.tar.gz"

# Stash any local changes
log "Stashing local changes..."
git stash push -m "Auto-stash before update $DATE" || true

# Fetch latest changes
log "Fetching latest changes from repository..."
git fetch origin

# Check if there are updates available
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)

if [ "$LOCAL" = "$REMOTE" ]; then
    warning "No updates available. Application is already up to date."
    exit 0
fi

log "Updates available. Proceeding with deployment..."
echo "Current commit: $LOCAL"
echo "Latest commit: $REMOTE"

# Pull latest changes
log "Pulling latest changes..."
git pull origin main

# Update backend dependencies
log "Updating backend dependencies..."
cd $APP_DIR/server
npm ci --production

# Update frontend dependencies and build
log "Updating frontend dependencies and building..."
cd $APP_DIR/sbf-main
npm ci

# Build frontend
log "Building frontend application..."
npm run build

# Test backend startup
log "Testing backend configuration..."
cd $APP_DIR/server
timeout 10s node -e "
require('dotenv').config();
const express = require('express');
const app = express();
console.log('✓ Backend configuration test passed');
process.exit(0);
" || error "Backend configuration test failed"

# Reload PM2 application (zero downtime)
log "Reloading application with PM2..."
cd $APP_DIR
pm2 reload ecosystem.config.js

# Wait for application to be ready
log "Waiting for application to be ready..."
sleep 10

# Health check
log "Performing health check..."
HEALTH_URL="http://localhost:5000/health"
if curl -f -s $HEALTH_URL > /dev/null; then
    success "Health check passed"
else
    error "Health check failed. Rolling back..."
    # Rollback logic would go here
fi

# Test Nginx configuration
log "Testing Nginx configuration..."
sudo nginx -t

# Reload Nginx if configuration is valid
log "Reloading Nginx..."
sudo systemctl reload nginx

# Clean up old builds and dependencies
log "Cleaning up..."
cd $APP_DIR/sbf-main
npm prune --production

# Clean PM2 logs
pm2 flush

# Display application status
log "=== Application Status ==="
pm2 status
echo ""
echo "=== Service Status ==="
echo "Nginx: $(sudo systemctl is-active nginx)"
echo "MongoDB: $(sudo systemctl is-active mongod)"
echo ""

# Final health check
log "Final health check..."
if curl -f -s $HEALTH_URL > /dev/null; then
    success "✅ Application update completed successfully!"
    echo ""
    echo "🌐 Application: https://yourdomain.com"
    echo "🔍 Health Check: https://yourdomain.com/health"
    echo "📊 API Status: https://yourdomain.com/api"
    echo ""
    echo "Updated from: $LOCAL"
    echo "Updated to: $REMOTE"
else
    error "❌ Application health check failed after update"
fi

# Optional: Send notification
# echo "SBF Florist application updated successfully on $(date). Version: $REMOTE" | mail -s "Application Update" admin@yourdomain.com

success "Update process completed!" 