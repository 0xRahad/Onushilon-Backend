# Onushilon Backend VPS Deployment Guide

This deployment script automatically sets up your Node.js application on a VPS with production-ready configuration including Nginx, MongoDB, PM2, SSL certificates, and monitoring.

## Prerequisites

- Fresh Ubuntu 20.04+ VPS
- Root access to the server
- Domain name pointed to your server IP (optional)

## Features

✅ **Automated Setup**

- Node.js (Latest LTS)
- MongoDB with authentication
- Nginx reverse proxy
- PM2 process manager
- SSL certificates (Let's Encrypt)
- UFW firewall configuration

✅ **Production Ready**

- Security headers
- Gzip compression
- Rate limiting
- Memory monitoring
- Automatic restarts
- Log management

✅ **Backup & Monitoring**

- Daily automated backups
- Health monitoring every 5 minutes
- Memory usage monitoring
- Easy update script

## Quick Start

### 1. Upload Files to Server

```bash
# Copy project to server
scp -r . root@your-server-ip:/tmp/onushilon-backend
```

### 2. Run Deployment Script

```bash
# SSH into your server
ssh root@your-server-ip

# Navigate to project directory
cd /tmp/onushilon-backend

# Run the deployment script
sudo ./deploy.sh
```

### 3. Follow Interactive Setup

The script will ask for:

- **Domain name** (or use server IP)
- **MongoDB password** (for database security)
- **JWT secret** (or auto-generate)

## Post-Deployment

### Application Management

```bash
# Check application status
sudo -u onushilon pm2 status

# View application logs
sudo -u onushilon pm2 logs onushilon-backend

# Restart application
sudo -u onushilon pm2 restart onushilon-backend

# Monitor real-time logs
sudo -u onushilon pm2 logs onushilon-backend --lines 50
```

### System Management

```bash
# Check all services
systemctl status nginx mongod

# Restart Nginx
systemctl restart nginx

# Restart MongoDB
systemctl restart mongod

# Check firewall status
ufw status
```

### Backup & Updates

```bash
# Manual backup
/usr/local/bin/onushilon-backup.sh

# Update application
/usr/local/bin/onushilon-update.sh

# View backup logs
cat /var/log/onushilon-backup.log

# View monitoring logs
cat /var/log/onushilon-monitor.log
```

## File Locations

| Component    | Location                                         |
| ------------ | ------------------------------------------------ |
| Application  | `/var/www/onushilon-backend/`                    |
| Environment  | `/var/www/onushilon-backend/.env`                |
| Nginx Config | `/etc/nginx/sites-available/onushilon-backend`   |
| PM2 Config   | `/var/www/onushilon-backend/ecosystem.config.js` |
| Backups      | `/var/backups/onushilon/`                        |
| Logs         | `/var/log/pm2/`                                  |

## Environment Variables

Update `/var/www/onushilon-backend/.env` with your actual values:

```env
NODE_ENV=production
PORT=3000
MONGODB_URI=mongodb://onushilon_user:YOUR_PASSWORD@localhost:27017/onushilon?authSource=onushilon
JWT_SECRET=YOUR_JWT_SECRET
JWT_EXPIRE=7d

# Email Configuration
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password
EMAIL_FROM=your-email@gmail.com
```

## SSL Certificate

If you provided a domain name, SSL is automatically configured. For manual SSL setup:

```bash
# Install certificate for domain
certbot --nginx -d yourdomain.com

# Auto-renewal is already configured
```

## Troubleshooting

### Application Won't Start

```bash
# Check PM2 logs
sudo -u onushilon pm2 logs onushilon-backend

# Check if port is in use
netstat -tlnp | grep :3000

# Restart with verbose logging
sudo -u onushilon pm2 restart onushilon-backend --log-date-format="YYYY-MM-DD HH:mm:ss"
```

### Database Connection Issues

```bash
# Test MongoDB connection
mongo mongodb://onushilon_user:YOUR_PASSWORD@localhost:27017/onushilon

# Check MongoDB status
systemctl status mongod

# Check MongoDB logs
tail -f /var/log/mongodb/mongod.log
```

### Nginx Issues

```bash
# Test Nginx configuration
nginx -t

# Check Nginx logs
tail -f /var/log/nginx/error.log

# Reload Nginx configuration
systemctl reload nginx
```

### Memory Issues

```bash
# Check system memory
free -h

# Check application memory usage
sudo -u onushilon pm2 monit

# Restart if memory usage is high
sudo -u onushilon pm2 restart onushilon-backend
```

## Security Notes

1. **Change default passwords** in the `.env` file
2. **Configure email settings** for notifications
3. **Regular updates**: `apt update && apt upgrade`
4. **Monitor logs** regularly for suspicious activity
5. **Backup regularly** (automated daily backups are configured)

## Performance Optimization

1. **Clustering**: PM2 runs in cluster mode for better performance
2. **Caching**: Nginx caches static files
3. **Compression**: Gzip enabled for better bandwidth usage
4. **Memory management**: Automatic restarts on high memory usage

## Support

For issues or questions:

1. Check logs first: `sudo -u onushilon pm2 logs`
2. Verify all services are running: `systemctl status nginx mongod`
3. Check application health: `curl http://localhost:3000/api/health`

---

**Deployment completed successfully! 🎉**

Your application is now running at: `http://your-domain-or-ip`
