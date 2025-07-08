#!/bin/bash

# SBF Florist - Automated Backup Script
# This script creates backups of the database and application files

set -e

# Configuration
BACKUP_DIR="/backup"
APP_DIR="/var/www/sbf-florist"
DB_NAME="sbf-florist"
RETENTION_DAYS=7
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

# Create backup directories
log "Creating backup directories..."
sudo mkdir -p $BACKUP_DIR/{mongodb,application,logs}

# Database backup
log "Creating MongoDB backup..."
if command -v mongodump &> /dev/null; then
    mongodump --db $DB_NAME --out $BACKUP_DIR/mongodb/$DATE
    
    # Compress database backup
    cd $BACKUP_DIR/mongodb
    tar -czf $DB_NAME-$DATE.tar.gz $DATE
    rm -rf $DATE
    
    success "Database backup created: $DB_NAME-$DATE.tar.gz"
else
    warning "mongodump not found, skipping database backup"
fi

# Application backup (excluding node_modules and uploads)
log "Creating application backup..."
cd /var/www
tar --exclude='node_modules' \
    --exclude='dist' \
    --exclude='uploads' \
    --exclude='.git' \
    --exclude='*.log' \
    -czf $BACKUP_DIR/application/sbf-florist-$DATE.tar.gz sbf-florist

success "Application backup created: sbf-florist-$DATE.tar.gz"

# Logs backup
log "Creating logs backup..."
if [ -d "/var/log/sbf-florist" ]; then
    tar -czf $BACKUP_DIR/logs/logs-$DATE.tar.gz -C /var/log sbf-florist
    success "Logs backup created: logs-$DATE.tar.gz"
fi

# Uploads backup (if exists)
log "Creating uploads backup..."
if [ -d "$APP_DIR/server/uploads" ]; then
    tar -czf $BACKUP_DIR/application/uploads-$DATE.tar.gz -C $APP_DIR/server uploads
    success "Uploads backup created: uploads-$DATE.tar.gz"
fi

# Clean old backups
log "Cleaning old backups (older than $RETENTION_DAYS days)..."

# Clean old database backups
find $BACKUP_DIR/mongodb -name "*.tar.gz" -type f -mtime +$RETENTION_DAYS -delete

# Clean old application backups
find $BACKUP_DIR/application -name "*.tar.gz" -type f -mtime +$RETENTION_DAYS -delete

# Clean old log backups
find $BACKUP_DIR/logs -name "*.tar.gz" -type f -mtime +$RETENTION_DAYS -delete

success "Old backups cleaned successfully"

# Display backup information
log "=== Backup Summary ==="
echo "Database backup: $BACKUP_DIR/mongodb/$DB_NAME-$DATE.tar.gz"
echo "Application backup: $BACKUP_DIR/application/sbf-florist-$DATE.tar.gz"
echo "Uploads backup: $BACKUP_DIR/application/uploads-$DATE.tar.gz"
echo "Logs backup: $BACKUP_DIR/logs/logs-$DATE.tar.gz"
echo ""
echo "Backup sizes:"
ls -lh $BACKUP_DIR/mongodb/$DB_NAME-$DATE.tar.gz 2>/dev/null || echo "Database backup: Not created"
ls -lh $BACKUP_DIR/application/sbf-florist-$DATE.tar.gz 2>/dev/null || echo "Application backup: Not created"
ls -lh $BACKUP_DIR/application/uploads-$DATE.tar.gz 2>/dev/null || echo "Uploads backup: Not created"
ls -lh $BACKUP_DIR/logs/logs-$DATE.tar.gz 2>/dev/null || echo "Logs backup: Not created"

success "Backup completed successfully!"

# Optional: Send notification (uncomment if you have mail configured)
# echo "SBF Florist backup completed successfully on $(date)" | mail -s "Backup Report" admin@yourdomain.com 