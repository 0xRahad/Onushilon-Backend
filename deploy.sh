#!/bin/bash

# Onushilon Backend VPS Deployment Script (Plain Version)

set -e

# Configs
APP_NAME="onushilon-backend"
APP_USER="onushilon"
APP_DIR="/var/www/${APP_NAME}"
NGINX_SITES_AVAILABLE="/etc/nginx/sites-available"
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled"
PORT=3000

# Detect IP
SERVER_IP=$(curl -s ifconfig.me || wget -qO- ifconfig.me || echo "127.0.0.1")

echo "=================================================="
echo "     Onushilon Backend VPS Deployment Script"
echo "=================================================="
read -p "Enter your domain name (leave empty to use IP $SERVER_IP): " DOMAIN_NAME
DOMAIN_NAME=${DOMAIN_NAME:-$SERVER_IP}
[ "$DOMAIN_NAME" == "$SERVER_IP" ] && echo "[INFO] Using IP address: $DOMAIN_NAME" || echo "[INFO] Using domain: $DOMAIN_NAME"

# Secrets
read -s -p "Enter MongoDB admin password: " MONGO_PASSWORD; echo ""
[ -z "$MONGO_PASSWORD" ] && { echo "MongoDB password cannot be empty"; exit 1; }

read -s -p "Enter JWT secret (leave blank to auto-generate): " JWT_SECRET; echo ""
[ -z "$JWT_SECRET" ] && JWT_SECRET=$(openssl rand -base64 32)

# Confirm
echo ""
echo "================= Configuration ================="
echo " Domain/IP     : $DOMAIN_NAME"
echo " App Directory : $APP_DIR"
echo " Mongo Auth    : Enabled"
echo "=================================================="
read -p "Continue with deployment? (y/N): " CONFIRM
[[ ! $CONFIRM =~ ^[Yy]$ ]] && { echo "Deployment cancelled"; exit 1; }

# Check root
[ "$EUID" -ne 0 ] && { echo "Run this script as root"; exit 1; }

echo "[STEP] Updating system..."
apt update && apt upgrade -y

echo "[STEP] Installing dependencies..."
apt install -y curl wget gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release jq

echo "[STEP] Installing Node.js LTS..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install -y nodejs

echo "[STEP] Installing MongoDB..."
MONGO_KEYRING="/usr/share/keyrings/mongodb-server-7.0.gpg"
UBUNTU_CODENAME=$(lsb_release -cs)
[ "$UBUNTU_CODENAME" == "plucky" ] && UBUNTU_CODENAME="jammy"

curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor -o "$MONGO_KEYRING"
echo "deb [ arch=amd64,arm64 signed-by=$MONGO_KEYRING ] https://repo.mongodb.org/apt/ubuntu $UBUNTU_CODENAME/mongodb-org/7.0 multiverse" > /etc/apt/sources.list.d/mongodb-org-7.0.list

apt update
apt install -y mongodb-org
systemctl start mongod
systemctl enable mongod
sleep 10

echo "[STEP] Creating MongoDB users..."
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

echo "[STEP] Installing Nginx and PM2..."
apt install -y nginx
npm install -g pm2

echo "[STEP] Creating app user and directory..."
id "$APP_USER" &>/dev/null || { useradd -m -s /bin/bash $APP_USER; usermod -aG sudo $APP_USER; }
mkdir -p "$APP_DIR"
chown -R $APP_USER:$APP_USER "$APP_DIR"

if [ -f "package.json" ]; then
    echo "[STEP] Copying application files..."
    cp -r . "$APP_DIR"
    rm -f "$APP_DIR/deploy.sh"
    rm -rf "$APP_DIR/.git" "$APP_DIR/node_modules"
    chown -R $APP_USER:$APP_USER "$APP_DIR"
else
    echo "[WARNING] No package.json found. Upload your app to $APP_DIR manually."
fi

echo "[STEP] Creating .env file..."
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

echo "[STEP] Installing npm dependencies..."
cd "$APP_DIR"
sudo -u $APP_USER npm install --production

echo "[STEP] Creating PM2 config..."
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

echo "[STEP] Starting PM2..."
cd "$APP_DIR"
sudo -u $APP_USER pm2 start ecosystem.config.js
sudo -u $APP_USER pm2 save
STARTUP_CMD=$(sudo -u $APP_USER pm2 startup | tail -n1)
eval "$STARTUP_CMD"

echo "[STEP] Configuring Nginx..."
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

echo "[STEP] Configuring firewall..."
ufw --force enable
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw allow 27017

if [[ ! $DOMAIN_NAME =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "[STEP] Installing SSL with Certbot..."
    apt install -y certbot python3-certbot-nginx
    certbot --nginx -d "$DOMAIN_NAME" --non-interactive --agree-tos --email "admin@$DOMAIN_NAME" --redirect || echo "Certbot failed"
else
    echo "[INFO] SSL skipped for IP address"
fi

# Summary
echo ""
echo "=================================================="
echo "           ✅ Deployment Complete!"
echo "=================================================="
echo "🌐 App URL        : http://$DOMAIN_NAME"
[[ ! $DOMAIN_NAME =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && echo "🔒 HTTPS URL      : https://$DOMAIN_NAME"
echo "📁 App Directory  : $APP_DIR"
echo "🗃️  MongoDB URI    : mongodb://onushilon_user:***@localhost:27017/onushilon"
echo "⚙️  Env File       : $APP_DIR/.env"
echo "📜 PM2 Logs       : sudo -u $APP_USER pm2 logs $APP_NAME"
echo "🔄 Restart App    : sudo -u $APP_USER pm2 restart $APP_NAME"
echo "🛑 Stop App       : sudo -u $APP_USER pm2 stop $APP_NAME"
echo "📈 PM2 Monitor    : sudo -u $APP_USER pm2 monit"
echo "=================================================="
