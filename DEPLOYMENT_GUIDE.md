# SBF Florist - Ubuntu VPS Deployment Guide

This guide provides comprehensive instructions for deploying the SBF Florist e-commerce application on a Hostinger VPS with Ubuntu OS.

## 📋 Prerequisites

### System Requirements
- **OS**: Ubuntu 20.04 LTS or newer
- **RAM**: Minimum 2GB (4GB recommended)
- **Storage**: Minimum 20GB free space
- **CPU**: 1 core minimum (2+ cores recommended)
- **Network**: Stable internet connection

### Domain & DNS
- Domain name pointed to your VPS IP
- SSL certificate (Let's Encrypt - automated in script)

### Third-party Services
You'll need accounts and API keys for:
- **MongoDB** (local or MongoDB Atlas)
- **Cloudinary** (image hosting)
- **Razorpay** (payment gateway)
- **Google OAuth** (social login)
- **Email provider** (Gmail/SMTP)

## 🚀 Quick Deployment

### Option 1: Automated Script (Recommended)

1. **Connect to your VPS:**
   ```bash
   ssh your-username@your-server-ip
   ```

2. **Download and run the deployment script:**
   ```bash
   wget https://raw.githubusercontent.com/your-repo/SBF/main/deploy-ubuntu.sh
   chmod +x deploy-ubuntu.sh
   ./deploy-ubuntu.sh
   ```

3. **Follow the prompts:**
   - Enter your Git repository URL
   - Provide your domain name
   - Choose SSL certificate setup

### Option 2: Manual Deployment

Follow the detailed steps below if you prefer manual installation.

## 📝 Manual Deployment Steps

### Step 1: System Preparation

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release
```

### Step 2: Install Node.js 18.x

```bash
# Add NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# Install Node.js
sudo apt install -y nodejs

# Verify installation
node --version
npm --version
```

### Step 3: Install PM2 Process Manager

```bash
# Install PM2 globally
sudo npm install -g pm2

# Verify installation
pm2 --version
```

### Step 4: Install and Configure MongoDB

```bash
# Add MongoDB repository
curl -fsSL https://pgp.mongodb.com/server-7.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor

echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# Update and install MongoDB
sudo apt update
sudo apt install -y mongodb-org

# Start and enable MongoDB
sudo systemctl start mongod
sudo systemctl enable mongod

# Verify MongoDB is running
sudo systemctl status mongod
```

### Step 5: Install and Configure Nginx

```bash
# Install Nginx
sudo apt install -y nginx

# Start and enable Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Verify Nginx is running
sudo systemctl status nginx
```

### Step 6: Deploy Application Code

```bash
# Create application directory
sudo mkdir -p /var/www/sbf-florist
sudo chown -R $USER:$USER /var/www/sbf-florist

# Clone your repository
git clone YOUR_REPOSITORY_URL /var/www/sbf-florist
cd /var/www/sbf-florist

# Install backend dependencies
cd server
npm install --production

# Install frontend dependencies and build
cd ../sbf-main
npm install
npm run build

# Create necessary directories
sudo mkdir -p /var/www/sbf-florist/server/uploads
sudo mkdir -p /var/log/sbf-florist
sudo chown -R $USER:$USER /var/www/sbf-florist/server/uploads
sudo chown -R $USER:$USER /var/log/sbf-florist
```

### Step 7: Configure Environment Variables

```bash
# Copy environment template
cp .env.example server/.env

# Edit environment file
nano server/.env
```

**Important Environment Variables to Configure:**

```env
# Update these with your actual values
NODE_ENV=production
MONGO_URI=mongodb://localhost:27017/sbf-florist
JWT_SECRET=your-super-secret-jwt-key
FRONTEND_URL=https://yourdomain.com

# Email settings
EMAIL_HOST=smtp.gmail.com
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password

# Cloudinary settings
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret

# Razorpay settings
RAZORPAY_KEY_ID=your-razorpay-key-id
RAZORPAY_KEY_SECRET=your-razorpay-key-secret

# Google OAuth settings
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
```

### Step 8: Configure PM2

```bash
# Copy PM2 configuration
cp ecosystem.config.js /var/www/sbf-florist/

# Start application with PM2
cd /var/www/sbf-florist
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save

# Setup PM2 startup script
pm2 startup
# Follow the instructions provided by the command above
```

### Step 9: Configure Nginx

```bash
# Create Nginx configuration
sudo nano /etc/nginx/sites-available/sbf-florist
```

**Copy the content from `nginx-production.conf` and update:**
- Replace `yourdomain.com` with your actual domain
- Update SSL certificate paths after obtaining certificates

```bash
# Enable the site
sudo ln -sf /etc/nginx/sites-available/sbf-florist /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

### Step 10: Setup SSL Certificates

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Obtain SSL certificates
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Enable auto-renewal
sudo systemctl enable certbot.timer
```

### Step 11: Configure Firewall

```bash
# Allow necessary ports
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw allow 80
sudo ufw allow 443

# Enable firewall
sudo ufw --force enable

# Check firewall status
sudo ufw status
```

### Step 12: Setup Log Rotation

```bash
# Create log rotation configuration
sudo nano /etc/logrotate.d/sbf-florist
```

Add the following content:
```
/var/log/sbf-florist/*.log {
    daily
    missingok
    rotate 14
    compress
    notifempty
    create 0644 your-username your-username
    postrotate
        pm2 reloadLogs
    endscript
}
```

## 🔧 Configuration Details

### Environment Variables Guide

| Variable | Description | Example |
|----------|-------------|---------|
| `MONGO_URI` | MongoDB connection string | `mongodb://localhost:27017/sbf-florist` |
| `JWT_SECRET` | Secret key for JWT tokens | Generate with `openssl rand -base64 32` |
| `FRONTEND_URL` | Your domain URL | `https://yourdomain.com` |
| `EMAIL_HOST` | SMTP server hostname | `smtp.gmail.com` |
| `EMAIL_USER` | SMTP username | `your-email@gmail.com` |
| `EMAIL_PASS` | SMTP password/app password | Use Gmail App Password |
| `CLOUDINARY_*` | Image hosting service | Sign up at cloudinary.com |
| `RAZORPAY_*` | Payment gateway | Sign up at razorpay.com |
| `GOOGLE_CLIENT_*` | OAuth credentials | Create at console.developers.google.com |

### Third-party Service Setup

#### 1. Cloudinary (Image Hosting)
1. Sign up at [cloudinary.com](https://cloudinary.com)
2. Get your cloud name, API key, and API secret from dashboard
3. Add to environment variables

#### 2. Razorpay (Payment Gateway)
1. Sign up at [razorpay.com](https://razorpay.com)
2. Complete KYC verification
3. Get API keys from dashboard
4. Add to environment variables

#### 3. Google OAuth (Social Login)
1. Go to [Google Developers Console](https://console.developers.google.com)
2. Create a new project or select existing
3. Enable Google+ API
4. Create OAuth 2.0 credentials
5. Add authorized redirect URIs:
   - `https://yourdomain.com/auth/google/callback`
6. Add to environment variables

#### 4. Email Configuration (Gmail)
1. Enable 2-Factor Authentication on your Google account
2. Generate App Password:
   - Go to [Google Account Settings](https://myaccount.google.com)
   - Security → 2-Step Verification → App passwords
   - Generate password for "Mail"
3. Use the generated password in `EMAIL_PASS`

## 🔍 Monitoring & Maintenance

### PM2 Commands

```bash
# Check application status
pm2 status

# View logs
pm2 logs sbf-backend

# Restart application
pm2 restart sbf-backend

# Reload application (zero downtime)
pm2 reload sbf-backend

# Monitor resources
pm2 monit
```

### Nginx Commands

```bash
# Check Nginx status
sudo systemctl status nginx

# Test configuration
sudo nginx -t

# Reload configuration
sudo systemctl reload nginx

# Restart Nginx
sudo systemctl restart nginx

# View logs
sudo tail -f /var/log/nginx/sbf-florist-access.log
sudo tail -f /var/log/nginx/sbf-florist-error.log
```

### MongoDB Commands

```bash
# Check MongoDB status
sudo systemctl status mongod

# MongoDB shell
mongosh

# View database
use sbf-florist
show collections
```

### System Monitoring

```bash
# Check disk usage
df -h

# Check memory usage
free -h

# Check CPU usage
top

# Check active connections
ss -tuln
```

## 🔒 Security Best Practices

### 1. Regular Updates
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update Node.js packages
cd /var/www/sbf-florist
npm audit
npm update
```

### 2. Backup Strategy
```bash
# Database backup
mongodump --db sbf-florist --out /backup/mongodb/$(date +%Y%m%d)

# Application backup
tar -czf /backup/app/sbf-florist-$(date +%Y%m%d).tar.gz /var/www/sbf-florist

# Automated backup script (add to crontab)
0 2 * * * /path/to/backup-script.sh
```

### 3. SSL Certificate Renewal
```bash
# Test renewal
sudo certbot renew --dry-run

# Check certificate status
sudo certbot certificates
```

## 🐛 Troubleshooting

### Common Issues

#### 1. Application Not Starting
```bash
# Check PM2 logs
pm2 logs sbf-backend

# Check environment variables
cd /var/www/sbf-florist/server
cat .env

# Restart application
pm2 restart sbf-backend
```

#### 2. Database Connection Issues
```bash
# Check MongoDB status
sudo systemctl status mongod

# Check MongoDB logs
sudo tail -f /var/log/mongodb/mongod.log

# Restart MongoDB
sudo systemctl restart mongod
```

#### 3. Nginx Issues
```bash
# Check Nginx configuration
sudo nginx -t

# Check Nginx logs
sudo tail -f /var/log/nginx/error.log

# Restart Nginx
sudo systemctl restart nginx
```

#### 4. SSL Certificate Issues
```bash
# Check certificate status
sudo certbot certificates

# Renew certificates
sudo certbot renew

# Check Nginx SSL configuration
sudo nginx -t
```

### Performance Issues

#### 1. High Memory Usage
```bash
# Check memory usage
free -h
pm2 monit

# Restart application if needed
pm2 restart sbf-backend
```

#### 2. Slow Response Times
```bash
# Check application logs
pm2 logs sbf-backend

# Monitor database performance
mongosh --eval "db.serverStatus()"

# Check disk I/O
iostat -x 1
```

## 📞 Support

If you encounter issues:

1. Check the application logs: `pm2 logs sbf-backend`
2. Check Nginx logs: `sudo tail -f /var/log/nginx/sbf-florist-error.log`
3. Check system resources: `htop` or `top`
4. Verify all services are running:
   ```bash
   sudo systemctl status nginx
   sudo systemctl status mongod
   pm2 status
   ```

## 🎉 Success!

After completing all steps, your SBF Florist application should be running at:
- **Frontend**: `https://yourdomain.com`
- **API**: `https://yourdomain.com/api`
- **Health Check**: `https://yourdomain.com/health`

Your application is now deployed and ready for production use! 