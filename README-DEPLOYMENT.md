# SBF Florist - Ubuntu VPS Deployment Files

This repository contains all the necessary files and scripts for deploying the SBF Florist e-commerce application on a Hostinger VPS with Ubuntu OS.

## 📁 Deployment Files Overview

### Core Deployment Files

| File | Description | Purpose |
|------|-------------|---------|
| `deploy-ubuntu.sh` | Main deployment script | Automated setup of entire application stack |
| `ecosystem.config.js` | PM2 configuration | Process management and monitoring |
| `nginx-production.conf` | Nginx configuration | Web server and reverse proxy setup |
| `.env.example` | Environment template | Backend configuration template |
| `sbf-florist.service` | Systemd service | System service management |

### Utility Scripts

| File | Description | Usage |
|------|-------------|-------|
| `backup-script.sh` | Automated backup | Daily backups of database and application |
| `update-app.sh` | Zero-downtime updates | Deploy updates without service interruption |

### Documentation

| File | Description |
|------|-------------|
| `DEPLOYMENT_GUIDE.md` | Comprehensive deployment guide |
| `README-DEPLOYMENT.md` | This file - quick reference |

## 🚀 Quick Start

### 1. Prerequisites
- Ubuntu 20.04+ VPS
- Domain name pointing to VPS IP
- Root/sudo access
- Git repository with your code

### 2. One-Command Deployment

```bash
# Connect to your VPS
ssh username@your-server-ip

# Download and run deployment script
wget https://raw.githubusercontent.com/your-repo/SBF/main/deploy-ubuntu.sh
chmod +x deploy-ubuntu.sh
./deploy-ubuntu.sh
```

### 3. Follow the Prompts
- Enter your Git repository URL
- Provide your domain name
- Configure SSL certificates
- Update environment variables

## ⚙️ Configuration Required

### Environment Variables (server/.env)

**Critical settings to configure:**

```env
# Database
MONGO_URI=mongodb://localhost:27017/sbf-florist

# Security
JWT_SECRET=your-secure-jwt-secret

# Domain
FRONTEND_URL=https://yourdomain.com

# Email (Gmail example)
EMAIL_HOST=smtp.gmail.com
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password

# Cloudinary (Image hosting)
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret

# Razorpay (Payment gateway)
RAZORPAY_KEY_ID=your-razorpay-key-id
RAZORPAY_KEY_SECRET=your-razorpay-key-secret

# Google OAuth
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
```

### Frontend Configuration

Update `sbf-main/.env.production` with:
- Your domain name
- API endpoints
- Service keys (Razorpay, Google OAuth)

### Nginx Configuration

Update `nginx-production.conf`:
- Replace `yourdomain.com` with your actual domain
- Update SSL certificate paths

## 🔧 Manual Installation Steps

If you prefer manual installation:

1. **System Setup**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Install Dependencies**
   ```bash
   # Node.js 18.x
   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
   sudo apt install -y nodejs
   
   # PM2
   sudo npm install -g pm2
   
   # Nginx
   sudo apt install -y nginx
   
   # MongoDB
   # (See DEPLOYMENT_GUIDE.md for detailed MongoDB setup)
   ```

3. **Deploy Application**
   ```bash
   # Clone repository
   git clone YOUR_REPO_URL /var/www/sbf-florist
   cd /var/www/sbf-florist
   
   # Install dependencies
   cd server && npm install --production
   cd ../sbf-main && npm install && npm run build
   ```

4. **Configure Services**
   ```bash
   # Copy configuration files
   sudo cp nginx-production.conf /etc/nginx/sites-available/sbf-florist
   sudo ln -s /etc/nginx/sites-available/sbf-florist /etc/nginx/sites-enabled/
   
   # Start services
   pm2 start ecosystem.config.js
   pm2 save
   pm2 startup
   ```

## 📊 Service Management

### PM2 Commands
```bash
pm2 status                    # Check application status
pm2 logs sbf-backend         # View application logs
pm2 restart sbf-backend      # Restart application
pm2 reload sbf-backend       # Zero-downtime reload
pm2 monit                    # Resource monitoring
```

### Nginx Commands
```bash
sudo systemctl status nginx  # Check Nginx status
sudo nginx -t                # Test configuration
sudo systemctl reload nginx  # Reload configuration
```

### MongoDB Commands
```bash
sudo systemctl status mongod # Check MongoDB status
mongosh                     # Access MongoDB shell
```

## 🔒 Security Features

### Implemented Security Measures
- ✅ SSL/TLS encryption (Let's Encrypt)
- ✅ Security headers (HSTS, CSP, etc.)
- ✅ Rate limiting on API endpoints
- ✅ Firewall configuration (UFW)
- ✅ File upload restrictions
- ✅ Process isolation
- ✅ Regular security updates

### Additional Recommendations
- Change default SSH port
- Set up fail2ban for intrusion prevention
- Regular security audits
- Monitor logs for suspicious activity

## 📈 Monitoring & Maintenance

### Health Checks
```bash
# Application health
curl https://yourdomain.com/health

# Service status
sudo systemctl status nginx mongod
pm2 status
```

### Log Monitoring
```bash
# Application logs
pm2 logs sbf-backend

# Nginx logs
sudo tail -f /var/log/nginx/sbf-florist-access.log
sudo tail -f /var/log/nginx/sbf-florist-error.log

# System logs
sudo journalctl -u nginx
sudo journalctl -u mongod
```

### Backup Management
```bash
# Run manual backup
./backup-script.sh

# Schedule automated backups (crontab)
0 2 * * * /path/to/backup-script.sh
```

### Application Updates
```bash
# Zero-downtime update
./update-app.sh

# Manual update process
cd /var/www/sbf-florist
git pull origin main
cd server && npm ci --production
cd ../sbf-main && npm ci && npm run build
pm2 reload ecosystem.config.js
```

## 🆘 Troubleshooting

### Common Issues

**Application won't start:**
```bash
pm2 logs sbf-backend
cat /var/www/sbf-florist/server/.env
```

**Database connection failed:**
```bash
sudo systemctl status mongod
sudo tail -f /var/log/mongodb/mongod.log
```

**Nginx configuration error:**
```bash
sudo nginx -t
sudo tail -f /var/log/nginx/error.log
```

**SSL certificate issues:**
```bash
sudo certbot certificates
sudo certbot renew --dry-run
```

### Performance Issues

**High memory usage:**
```bash
free -h
pm2 monit
pm2 restart sbf-backend
```

**Slow response times:**
```bash
pm2 logs sbf-backend
htop
iostat -x 1
```

## 📞 Support

### Getting Help

1. **Check logs first:**
   ```bash
   pm2 logs sbf-backend
   sudo tail -f /var/log/nginx/sbf-florist-error.log
   ```

2. **Verify services:**
   ```bash
   sudo systemctl status nginx mongod
   pm2 status
   ```

3. **Check system resources:**
   ```bash
   htop
   df -h
   free -h
   ```

### Useful Resources
- [PM2 Documentation](https://pm2.keymetrics.io/docs/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [MongoDB Documentation](https://docs.mongodb.com/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)

## 🎯 Success Indicators

After successful deployment, verify:

- ✅ **Frontend**: https://yourdomain.com loads correctly
- ✅ **API**: https://yourdomain.com/api responds
- ✅ **Health Check**: https://yourdomain.com/health returns "OK"
- ✅ **SSL**: Certificate is valid and secure
- ✅ **Services**: All services running (nginx, mongod, PM2)
- ✅ **Performance**: Fast loading times and responsiveness

## 📋 Post-Deployment Checklist

- [ ] Update DNS records to point to VPS IP
- [ ] Configure environment variables with actual values
- [ ] Set up SSL certificates
- [ ] Test all application features
- [ ] Configure backup schedules
- [ ] Set up monitoring alerts
- [ ] Update third-party service webhooks
- [ ] Test payment gateway integration
- [ ] Verify email functionality
- [ ] Configure domain redirects if needed

---

## 🏆 Deployment Complete!

Your SBF Florist application is now ready for production use on Ubuntu VPS. For detailed configuration and troubleshooting, refer to `DEPLOYMENT_GUIDE.md`.

**Happy deploying! 🚀** 