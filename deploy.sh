#!/bin/bash

# Onushilon Backend VPS Deployment Script
# Deploys Node.js app with Nginx, MongoDB, PM2, and SSL
# Author: Onushilon Team
# Date: $(date +%Y-%m-%d)

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Configuration variables
APP_NAME="onushilon-backend"
APP_USER="onushilon"
APP_DIR="/var/www/${APP_NAME}"
NGINX_SITES_AVAILABLE="/etc/nginx/sites-available"
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled"
PORT=3000

# Get server IP address
SERVER_IP=$(curl -s ifconfig.me || wget -qO- ifconfig.me || echo "127.0.0.1")

echo -e "${BLUE}"
echo "=================================================="
echo "    Onushilon Backend VPS Deployment Script"
echo "=================================================="
echo -e "${NC}"

# Get domain name from user
read -p "Enter your domain name (leave empty to use IP address $SERVER_IP): " DOMAIN_NAME

if [ -z "$DOMAIN_NAME" ]; then
    DOMAIN_NAME=$SERVER_IP
    warn "Using IP address: $DOMAIN_NAME"
else
    log "Using domain: $DOMAIN_NAME"
fi

# Get MongoDB password
echo ""
read -s -p "Enter a password for MongoDB admin user: " MONGO_PASSWORD
echo ""
if [ -z "$MONGO_PASSWORD" ]; then
    error "MongoDB password cannot be empty"
fi

# Get JWT secret
echo ""
read -s -p "Enter JWT secret (leave empty to generate random): " JWT_SECRET
echo ""
if [ -z "$JWT_SECRET" ]; then
    JWT_SECRET=$(openssl rand -base64 32)
    log "Generated random JWT secret"
fi

# Confirmation
echo ""
echo -e "${YELLOW}Deployment Configuration:${NC}"
echo "Domain/IP: $DOMAIN_NAME"
echo "App Directory: $APP_DIR"
echo "Port: $PORT"
echo "MongoDB with authentication: Yes"
echo ""
read -p "Continue with deployment? (y/N): " CONFIRM

if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    error "Deployment cancelled by user"
fi

log "Starting deployment process..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    error "Please run this script as root (use sudo)"
fi

# Update system packages
log "Updating system packages..."
apt update && apt upgrade -y

# Install essential packages
log "Installing essential packages..."
apt install -y curl wget gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release

# Install Node.js (Latest LTS)
log "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install -y nodejs

# Verify Node.js installation
NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)
log "Node.js installed: $NODE_VERSION"
log "NPM installed: $NPM_VERSION"

# Install MongoDB
log "Installing MongoDB..."
wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list
apt update
apt install -y mongodb-org

# Start and enable MongoDB
systemctl start mongod
systemctl enable mongod

# Wait for MongoDB to start
sleep 5

# Configure MongoDB with authentication
log "Configuring MongoDB authentication..."
mongo --eval "
db = db.getSiblingDB('admin');
db.createUser({
  user: 'admin',
  pwd: '$MONGO_PASSWORD',
  roles: ['userAdminAnyDatabase', 'dbAdminAnyDatabase', 'readWriteAnyDatabase']
});
db = db.getSiblingDB('onushilon');
db.createUser({
  user: 'onushilon_user',
  pwd: '$MONGO_PASSWORD',
  roles: ['readWrite']
});
"

# Enable MongoDB authentication
sed -i 's/#security:/security:\n  authorization: enabled/' /etc/mongod.conf
systemctl restart mongod

# Install Nginx
log "Installing Nginx..."
apt install -y nginx

# Install PM2 globally
log "Installing PM2..."
npm install -g pm2

# Create application user
log "Creating application user..."
if ! id "$APP_USER" &>/dev/null; then
    useradd -m -s /bin/bash $APP_USER
    usermod -aG sudo $APP_USER
    log "User $APP_USER created"
else
    log "User $APP_USER already exists"
fi

# Create application directory
log "Setting up application directory..."
mkdir -p $APP_DIR
chown $APP_USER:$APP_USER $APP_DIR

# Copy application files (assuming script is run from project directory)
log "Copying application files..."
if [ -f "package.json" ]; then
    cp -r . $APP_DIR/
    # Remove unnecessary files
    rm -f $APP_DIR/deploy.sh
    rm -rf $APP_DIR/.git
    rm -rf $APP_DIR/node_modules
    chown -R $APP_USER:$APP_USER $APP_DIR
else
    warn "package.json not found in current directory"
    log "Please upload your application files to $APP_DIR manually"
fi

# Create .env file
log "Creating environment configuration..."
cat > $APP_DIR/.env << EOF
NODE_ENV=production
PORT=$PORT
MONGODB_URI=mongodb://onushilon_user:$MONGO_PASSWORD@localhost:27017/onushilon?authSource=onushilon
JWT_SECRET=$JWT_SECRET
JWT_EXPIRE=7d

# Email configuration (update these with your actual email settings)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password
EMAIL_FROM=your-email@gmail.com
EOF

chown $APP_USER:$APP_USER $APP_DIR/.env
chmod 600 $APP_DIR/.env

# Install application dependencies
log "Installing application dependencies..."
cd $APP_DIR
sudo -u $APP_USER npm install --production

# Create PM2 ecosystem file
log "Creating PM2 configuration..."
cat > $APP_DIR/ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: '$APP_NAME',
    script: 'index.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: $PORT
    },
    error_file: '/var/log/pm2/$APP_NAME-error.log',
    out_file: '/var/log/pm2/$APP_NAME-out.log',
    log_file: '/var/log/pm2/$APP_NAME.log',
    time: true,
    max_memory_restart: '1G',
    node_args: '--max-old-space-size=1024'
  }]
};
EOF

chown $APP_USER:$APP_USER $APP_DIR/ecosystem.config.js

# Create PM2 log directory
mkdir -p /var/log/pm2
chown $APP_USER:$APP_USER /var/log/pm2

# Start application with PM2
log "Starting application with PM2..."
cd $APP_DIR
sudo -u $APP_USER pm2 start ecosystem.config.js
sudo -u $APP_USER pm2 save
sudo -u $APP_USER pm2 startup

# Get the startup command and execute it
STARTUP_CMD=$(sudo -u $APP_USER pm2 startup | tail -n 1)
eval $STARTUP_CMD

# Configure Nginx
log "Configuring Nginx..."
cat > $NGINX_SITES_AVAILABLE/$APP_NAME << EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json;

    location / {
        proxy_pass http://localhost:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;

        # Rate limiting
        limit_req_status 429;
    }

    # Health check endpoint
    location /api/health {
        proxy_pass http://localhost:$PORT/api/health;
        access_log off;
    }

    # Static files caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        proxy_pass http://localhost:$PORT;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Enable the site
ln -sf $NGINX_SITES_AVAILABLE/$APP_NAME $NGINX_SITES_ENABLED/
rm -f $NGINX_SITES_ENABLED/default

# Test Nginx configuration
nginx -t

# Start and enable Nginx
systemctl restart nginx
systemctl enable nginx

# Configure UFW firewall
log "Configuring firewall..."
ufw --force enable
ufw allow ssh
ufw allow 'Nginx Full'
ufw allow 27017  # MongoDB (you may want to restrict this to localhost only)

# Install and configure Certbot for SSL (if domain is provided and not an IP)
if [[ $DOMAIN_NAME =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    warn "Skipping SSL certificate installation for IP address"
else
    log "Installing SSL certificate..."
    apt install -y certbot python3-certbot-nginx
    
    # Attempt to get SSL certificate
    if certbot --nginx -d $DOMAIN_NAME --non-interactive --agree-tos --email admin@$DOMAIN_NAME --redirect; then
        log "SSL certificate installed successfully"
    else
        warn "SSL certificate installation failed. You can try running: certbot --nginx -d $DOMAIN_NAME"
    fi
fi

# Create backup script
log "Creating backup script..."
cat > /usr/local/bin/onushilon-backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/var/backups/onushilon"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# Backup MongoDB
mongodump --host localhost --port 27017 --username onushilon_user --password $MONGO_PASSWORD --db onushilon --out $BACKUP_DIR/mongo_$DATE

# Backup application files
tar -czf $BACKUP_DIR/app_$DATE.tar.gz -C /var/www onushilon-backend

# Keep only last 7 backups
find $BACKUP_DIR -name "mongo_*" -mtime +7 -delete
find $BACKUP_DIR -name "app_*" -mtime +7 -delete

echo "Backup completed: $DATE"
EOF

chmod +x /usr/local/bin/onushilon-backup.sh

# Add backup to crontab (daily at 2 AM)
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/onushilon-backup.sh >> /var/log/onushilon-backup.log 2>&1") | crontab -

# Create monitoring script
log "Creating monitoring script..."
cat > /usr/local/bin/onushilon-monitor.sh << 'EOF'
#!/bin/bash
APP_NAME="onushilon-backend"
MAX_MEMORY=1073741824  # 1GB in bytes

# Check if PM2 process is running
if ! sudo -u onushilon pm2 list | grep -q "$APP_NAME.*online"; then
    echo "$(date): $APP_NAME is not running, restarting..." >> /var/log/onushilon-monitor.log
    sudo -u onushilon pm2 restart $APP_NAME
fi

# Check memory usage
MEMORY_USAGE=$(sudo -u onushilon pm2 jlist | jq -r ".[] | select(.name==\"$APP_NAME\") | .pid" | xargs ps -o rss= -p | awk '{sum+=$1} END {print sum*1024}')

if [ "$MEMORY_USAGE" -gt "$MAX_MEMORY" ]; then
    echo "$(date): $APP_NAME memory usage ($MEMORY_USAGE bytes) exceeds limit, restarting..." >> /var/log/onushilon-monitor.log
    sudo -u onushilon pm2 restart $APP_NAME
fi
EOF

chmod +x /usr/local/bin/onushilon-monitor.sh

# Add monitoring to crontab (every 5 minutes)
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/onushilon-monitor.sh") | crontab -

# Create update script
log "Creating update script..."
cat > /usr/local/bin/onushilon-update.sh << EOF
#!/bin/bash
APP_DIR="$APP_DIR"
APP_USER="$APP_USER"
APP_NAME="$APP_NAME"

echo "Starting application update..."

# Backup current version
/usr/local/bin/onushilon-backup.sh

# Pull latest changes (if using git)
cd \$APP_DIR
if [ -d ".git" ]; then
    sudo -u \$APP_USER git pull
fi

# Install/update dependencies
sudo -u \$APP_USER npm install --production

# Restart application
sudo -u \$APP_USER pm2 restart \$APP_NAME

echo "Application updated successfully"
EOF

chmod +x /usr/local/bin/onushilon-update.sh

# Final status check
log "Performing final status check..."
sleep 5

# Check services
SERVICES=("mongod" "nginx")
for service in "${SERVICES[@]}"; do
    if systemctl is-active --quiet $service; then
        log "$service is running ✓"
    else
        warn "$service is not running ✗"
    fi
done

# Check PM2 status
if sudo -u $APP_USER pm2 list | grep -q "$APP_NAME.*online"; then
    log "PM2 application is running ✓"
else
    warn "PM2 application is not running ✗"
fi

# Check application endpoint
if curl -f -s http://localhost:$PORT/api/health > /dev/null; then
    log "Application health check passed ✓"
else
    warn "Application health check failed ✗"
fi

echo ""
echo -e "${GREEN}=================================================="
echo "          Deployment Complete!"
echo "==================================================${NC}"
echo ""
echo "🌐 Application URL: http://$DOMAIN_NAME"
echo "📊 PM2 Status: sudo -u $APP_USER pm2 status"
echo "📝 Application Logs: sudo -u $APP_USER pm2 logs $APP_NAME"
echo "🔄 Restart App: sudo -u $APP_USER pm2 restart $APP_NAME"
echo "🆙 Update App: /usr/local/bin/onushilon-update.sh"
echo "💾 Backup App: /usr/local/bin/onushilon-backup.sh"
echo ""
echo "📁 Application Directory: $APP_DIR"
echo "⚙️  Environment File: $APP_DIR/.env"
echo "🔧 Nginx Config: $NGINX_SITES_AVAILABLE/$APP_NAME"
echo ""
echo -e "${YELLOW}Important Notes:${NC}"
echo "1. Update email configuration in $APP_DIR/.env"
echo "2. MongoDB admin password: [HIDDEN]"
echo "3. Backups are scheduled daily at 2 AM"
echo "4. Monitoring runs every 5 minutes"
if [[ ! $DOMAIN_NAME =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "5. SSL certificate is configured for $DOMAIN_NAME"
fi
echo ""
echo -e "${GREEN}Deployment completed successfully! 🎉${NC}"