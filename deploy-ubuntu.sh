#!/bin/bash

# SBF Florist - Ubuntu VPS Deployment Script
# This script sets up the entire application on a fresh Ubuntu VPS

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root. Please run as a regular user with sudo privileges."
fi

log "Starting SBF Florist deployment on Ubuntu VPS..."

# Update system packages
log "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential packages
log "Installing essential packages..."
sudo apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# Install Node.js 18.x
log "Installing Node.js 18.x..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Verify Node.js installation
node_version=$(node --version)
npm_version=$(npm --version)
log "Node.js version: $node_version"
log "npm version: $npm_version"

# Install PM2 globally
log "Installing PM2 process manager..."
sudo npm install -g pm2

# Install Nginx
log "Installing Nginx..."
sudo apt install -y nginx

# Install MongoDB
log "Installing MongoDB..."
curl -fsSL https://pgp.mongodb.com/server-7.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
sudo apt update
sudo apt install -y mongodb-org

# Start and enable MongoDB
log "Starting MongoDB service..."
sudo systemctl start mongod
sudo systemctl enable mongod

# Install SSL certificates (Let's Encrypt)
log "Installing Certbot for SSL certificates..."
sudo apt install -y certbot python3-certbot-nginx

# Create application directory
APP_DIR="/var/www/sbf-florist"
log "Creating application directory: $APP_DIR"
sudo mkdir -p $APP_DIR
sudo chown -R $USER:$USER $APP_DIR

# Clone or copy application code
read -p "Enter your Git repository URL (or press Enter to skip): " REPO_URL
if [ ! -z "$REPO_URL" ]; then
    log "Cloning repository..."
    git clone $REPO_URL $APP_DIR
    cd $APP_DIR
else
    warning "Repository URL not provided. Please manually copy your application code to $APP_DIR"
    read -p "Press Enter when you have copied the application code..."
    cd $APP_DIR
fi

# Install backend dependencies
log "Installing backend dependencies..."
cd $APP_DIR/server
npm install --production

# Install frontend dependencies and build
log "Installing frontend dependencies and building..."
cd $APP_DIR/sbf-main
npm install
npm run build

# Create uploads directory
log "Creating uploads directory..."
sudo mkdir -p $APP_DIR/server/uploads
sudo chown -R $USER:$USER $APP_DIR/server/uploads

# Create logs directory
log "Creating logs directory..."
sudo mkdir -p /var/log/sbf-florist
sudo chown -R $USER:$USER /var/log/sbf-florist

# Create environment files
log "Creating environment configuration..."
cd $APP_DIR

# Backend environment file
if [ ! -f "server/.env" ]; then
    log "Creating backend .env file..."
    cat > server/.env << EOF
# Environment
NODE_ENV=production

# Server Configuration
PORT=5000

# MongoDB Configuration
MONGO_URI=mongodb://localhost:27017/sbf-florist

# JWT Configuration
JWT_SECRET=$(openssl rand -base64 32)
JWT_EXPIRE=30d

# Frontend URL
FRONTEND_URL=https://yourdomain.com

# Email Configuration (Configure with your email provider)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password

# Cloudinary Configuration (Sign up at cloudinary.com)
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret

# Razorpay Configuration (Sign up at razorpay.com)
RAZORPAY_KEY_ID=your-razorpay-key-id
RAZORPAY_KEY_SECRET=your-razorpay-key-secret

# Google OAuth (Configure at console.developers.google.com)
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret

# Twilio Configuration (Optional, for SMS)
TWILIO_ACCOUNT_SID=your-twilio-sid
TWILIO_AUTH_TOKEN=your-twilio-token
TWILIO_PHONE_NUMBER=your-twilio-phone
EOF
    warning "Please edit server/.env file with your actual configuration values"
fi

# Create PM2 ecosystem file
log "Creating PM2 configuration..."
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [
    {
      name: 'sbf-backend',
      script: './server/server.js',
      cwd: '$APP_DIR',
      instances: 1,
      exec_mode: 'cluster',
      env: {
        NODE_ENV: 'production',
        PORT: 5000
      },
      error_file: '/var/log/sbf-florist/backend-error.log',
      out_file: '/var/log/sbf-florist/backend-out.log',
      log_file: '/var/log/sbf-florist/backend-combined.log',
      time: true,
      watch: false,
      max_memory_restart: '1G',
      node_args: '--max-old-space-size=1024'
    }
  ]
};
EOF

# Configure Nginx
log "Configuring Nginx..."
read -p "Enter your domain name (e.g., yourdomain.com): " DOMAIN_NAME
if [ -z "$DOMAIN_NAME" ]; then
    DOMAIN_NAME="localhost"
    warning "No domain provided, using localhost"
fi

sudo tee /etc/nginx/sites-available/sbf-florist << EOF
server {
    listen 80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;
    
    # Redirect HTTP to HTTPS (will be enabled after SSL setup)
    # return 301 https://\$server_name\$request_uri;
    
    root $APP_DIR/sbf-main/dist;
    index index.html;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "camera=(), microphone=(), geolocation=()" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 10240;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript application/json;
    gzip_disable "MSIE [1-6]\.";

    # API routes - proxy to backend
    location /api/ {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 86400;
    }

    # Auth routes - proxy to backend
    location /auth/ {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Health check
    location /health {
        proxy_pass http://localhost:5000;
        access_log off;
    }

    # Uploads - serve from backend
    location /uploads/ {
        proxy_pass http://localhost:5000;
        add_header Cache-Control "public, max-age=31536000";
    }

    # Static files - serve directly
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files \$uri =404;
    }

    # SPA routing - serve React app
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # Error pages
    error_page 404 /index.html;
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/sbf-florist /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# Start services
log "Starting services..."
sudo systemctl restart nginx
sudo systemctl enable nginx

# Start the application with PM2
cd $APP_DIR
pm2 start ecosystem.config.js
pm2 save
pm2 startup

log "Generating startup script for PM2..."
PM2_STARTUP_CMD=$(pm2 startup | tail -n 1)
eval $PM2_STARTUP_CMD

# Create systemd service for additional reliability
log "Creating systemd service..."
sudo tee /etc/systemd/system/sbf-florist.service << EOF
[Unit]
Description=SBF Florist Application
After=network.target
Wants=mongodb.service

[Service]
Type=forking
User=$USER
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/pm2 start ecosystem.config.js --silent
ExecReload=/usr/bin/pm2 reload ecosystem.config.js --silent
ExecStop=/usr/bin/pm2 stop ecosystem.config.js --silent
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable sbf-florist

# Setup log rotation
log "Setting up log rotation..."
sudo tee /etc/logrotate.d/sbf-florist << EOF
/var/log/sbf-florist/*.log {
    daily
    missingok
    rotate 14
    compress
    notifempty
    create 0644 $USER $USER
    postrotate
        pm2 reloadLogs
    endscript
}
EOF

# Configure firewall
log "Configuring firewall..."
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw allow 80
sudo ufw allow 443
sudo ufw --force enable

# SSL Certificate setup (optional)
read -p "Do you want to set up SSL certificates now? (y/n): " setup_ssl
if [[ $setup_ssl =~ ^[Yy]$ ]]; then
    if [ "$DOMAIN_NAME" != "localhost" ]; then
        log "Setting up SSL certificates..."
        sudo certbot --nginx -d $DOMAIN_NAME -d www.$DOMAIN_NAME --non-interactive --agree-tos --email admin@$DOMAIN_NAME
        
        # Enable auto-renewal
        sudo systemctl enable certbot.timer
        
        success "SSL certificates installed successfully!"
    else
        warning "Cannot setup SSL for localhost. Please configure a proper domain first."
    fi
fi

# Final status check
log "Checking services status..."
echo "=== Service Status ==="
echo "Nginx: $(sudo systemctl is-active nginx)"
echo "MongoDB: $(sudo systemctl is-active mongod)"
echo "PM2: $(pm2 list | grep sbf-backend | awk '{print $18}')"

# Display important information
success "=== Deployment Complete! ==="
echo ""
echo "🌐 Application URL: http://$DOMAIN_NAME"
echo "📊 Backend API: http://$DOMAIN_NAME/api"
echo "🔍 Health Check: http://$DOMAIN_NAME/health"
echo ""
echo "📁 Application Directory: $APP_DIR"
echo "📝 Logs Directory: /var/log/sbf-florist"
echo "⚙️  Environment File: $APP_DIR/server/.env"
echo ""
echo "🔧 Useful Commands:"
echo "  pm2 status                    # Check PM2 processes"
echo "  pm2 logs sbf-backend         # View application logs"
echo "  pm2 restart sbf-backend      # Restart application"
echo "  pm2 reload sbf-backend       # Reload application (zero downtime)"
echo "  sudo systemctl status nginx  # Check Nginx status"
echo "  sudo nginx -t                # Test Nginx configuration"
echo ""
warning "Important: Please edit $APP_DIR/server/.env with your actual configuration values!"
warning "Configure your domain's DNS to point to this server's IP address."
echo ""
success "Deployment completed successfully! 🎉" 