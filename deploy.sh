#!/bin/bash

# Onushilon Backend VPS Deployment Script
# Deploys Node.js app with Nginx, MongoDB, PM2, and SSL
# Author: Onushilon Team
# Date: $(date +%Y-%m-%d)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()    { echo -e "${GREEN}[$(date +'%F %T')] $1${NC}"; }
warn()   { echo -e "${YELLOW}[$(date +'%F %T')] WARNING: $1${NC}"; }
error()  { echo -e "${RED}[$(date +'%F %T')] ERROR: $1${NC}"; exit 1; }

# Configs
APP_NAME="onushilon-backend"
APP_USER="onushilon"
APP_DIR="/var/www/${APP_NAME}"
NGINX_SITES_AVAILABLE="/etc/nginx/sites-available"
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled"
PORT=3000

# Detect IP
SERVER_IP=$(curl -s ifconfig.me || wget -qO- ifconfig.me || echo "127.0.0.1")

# Ask for domain
echo -e "${BLUE}=================================================="
echo "     Onushilon Backend VPS Deployment Script"
echo -e "==================================================${NC}"
read -p "Enter your domain name (leave empty to use IP $SERVER_IP): " DOMAIN_NAME
DOMAIN_NAME=${DOMAIN_NAME:-$SERVER_IP}
[[ "$DOMAIN_NAME" == "$SERVER_IP" ]] && warn "Using IP address: $DOMAIN_NAME" || log "Using domain: $DOMAIN_NAME"

# Ask for passwords/secrets
read -s -p "Enter MongoDB admin password: " MONGO_PASSWORD; echo ""
[ -z "$MONGO_PASSWORD" ] && error "MongoDB password cannot be empty"

read -s -p "Enter JWT secret (leave blank to auto-generate): " JWT_SECRET; echo ""
[ -z "$JWT_SECRET" ] && JWT_SECRET=$(openssl rand -base64 32) && log "Generated random JWT secret"

# Confirm
echo -e "${YELLOW}\nDeployment Configuration:${NC}"
echo "Domain/IP: $DOMAIN_NAME"
echo "App Directory: $APP_DIR"
echo "Port: $PORT"
echo "MongoDB Authentication: Enabled"
read -p "Continue with deployment? (y/N): " CONFIRM
[[ ! $CONFIRM =~ ^[Yy]$ ]] && error "Deployment cancelled"

# Check root
[ "$EUID" -ne 0 ] && error "Run as root"

# System update
log "Updating system packages..."
apt update && apt upgrade -y

# Essential packages
log "Installing dependencies..."
apt install -y curl wget gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release jq

# Node.js
log "Installing Node.js LTS..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install -y nodejs

log "Node: $(node -v), NPM: $(npm -v)"

# MongoDB (with plucky fix)
log "Installing MongoDB..."
MONGO_KEYRING="/usr/share/keyrings/mongodb-server-7.0.gpg"
UBUNTU_CODENAME=$(lsb_release -cs)
[[ "$UBUNTU_CODENAME" == "plucky" ]] && warn "Using 'jammy' MongoDB repo for Ubuntu 24.04" && UBUNTU_CODENAME="jammy"

curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor -o "$MONGO_KEYRING"
echo "deb [ arch=amd64,arm64 signed-by=$MONGO_KEYRING ] https://repo.mongodb.org/apt/ubuntu $UBUNTU_CODENAME/mongodb-org/7.0 multiverse" > /etc/apt/sources.list.d/mongodb-org-7.0.list

apt update
apt install -y mongodb-org

systemctl start mongod
systemctl enable mongod
sleep 10

log "Creating MongoDB users..."
mongosh --eval "
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

sed -i 's/#security:/security:\n  authorization: enabled/' /etc/mongod.conf
systemctl restart mongod

# Nginx + PM2
log "Installing Nginx and PM2..."
apt install -y nginx
npm install -g pm2

# User + app dir
log "Creating app user and directory..."
id "$APP_USER" &>/dev/null || { useradd -m -s /bin/bash $APP_USER; usermod -aG sudo $APP_USER; log "User $APP_USER created"; }
mkdir -p "$APP_DIR"
chown -R $APP_USER:$APP_USER "$APP_DIR"

# Copy files
if [ -f "package.json" ]; then
    log "Copying application files..."
    cp -r . "$APP_DIR"
    rm -f "$APP_DIR/deploy.sh"
    rm -rf "$APP_DIR/.git" "$APP_DIR/node_modules"
    chown -R $APP_USER:$APP_USER "$APP_DIR"
else
    warn "No package.json found. Upload app files to $APP_DIR manually."
fi

# .env
log "Creating .env file..."
cat > "$APP_DIR/.env" << EOF
NODE_ENV=production
PORT=$PORT
MONGODB_URI=mongodb://onushilon_user:$MONGO_PASSWORD@localhost:27017/onushilon?authSource=onushilon
JWT_SECRET=$JWT_SECRET
JWT_EXPIRE=7d
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password
EMAIL_FROM=your-email@gmail.com
EOF
chmod 600 "$APP_DIR/.env"
chown $APP_USER:$APP_USER "$APP_DIR/.env"

# Dependencies
log "Installing dependencies..."
cd "$APP_DIR"
sudo -u $APP_USER npm install --production

# PM2 config
log "Creating PM2 ecosystem..."
cat > "$APP_DIR/ecosystem.config.js" << EOF
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
mkdir -p /var/log/pm2
chown -R $APP_USER:$APP_USER /var/log/pm2 "$APP_DIR/ecosystem.config.js"

# Start PM2
log "Starting app with PM2..."
cd "$APP_DIR"
sudo -u $APP_USER pm2 start ecosystem.config.js
sudo -u $APP_USER pm2 save
STARTUP_CMD=$(sudo -u $APP_USER pm2 startup | tail -n1)
eval "$STARTUP_CMD"

# Nginx config
log "Configuring Nginx..."
cat > "$NGINX_SITES_AVAILABLE/$APP_NAME" << EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;

    location / {
        proxy_pass http://localhost:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 300;
    }

    location /api/health {
        proxy_pass http://localhost:$PORT/api/health;
        access_log off;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        proxy_pass http://localhost:$PORT;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

ln -sf "$NGINX_SITES_AVAILABLE/$APP_NAME" "$NGINX_SITES_ENABLED/"
rm -f "$NGINX_SITES_ENABLED/default"
nginx -t
systemctl restart nginx
systemctl enable nginx

# Firewall
log "Configuring UFW firewall..."
ufw --force enable
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw allow 27017

# SSL (skip for IP)
if [[ ! $DOMAIN_NAME =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log "Installing SSL with Certbot..."
    apt install -y certbot python3-certbot-nginx
    certbot --nginx -d "$DOMAIN_NAME" --non-interactive --agree-tos --email "admin@$DOMAIN_NAME" --redirect || warn "Certbot failed"
else
    warn "SSL skipped for IP address"
fi

# Final status
log "Checking services..."
systemctl is-active --quiet mongod && log "MongoDB running ✓" || warn "MongoDB not running ✗"
systemctl is-active --quiet nginx && log "Nginx running ✓" || warn "Nginx not running ✗"
sudo -u $APP_USER pm2 list | grep -q "$APP_NAME.*online" && log "PM2 app running ✓" || warn "PM2 app not running ✗"
curl -f -s http://localhost:$PORT/api/health > /dev/null && log "Health check passed ✓" || warn "Health check failed ✗"

# Done
echo -e "${GREEN}=================================================="
echo "           🎉 Deployment Complete!"
echo "==================================================${NC}"
echo "🌐 URL: http://$DOMAIN_NAME"
echo "📁 App Directory: $APP_DIR"
echo "⚙️  Env File: $APP_DIR/.env"
echo "🛠 Logs: sudo -u $APP_USER pm2 logs $APP_NAME"
echo "🔄 Restart: sudo -u $APP_USER pm2 restart $APP_NAME"
