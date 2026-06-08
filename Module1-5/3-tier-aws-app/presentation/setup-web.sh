#!/bin/bash
set -e

if [ -z "$APP_SERVER_IP" ]; then
    echo "❌ Error: APP_SERVER_IP env variable is required!"
    exit 1
fi

echo "🔄 Installing Nginx..."
sudo apt update -y
sudo apt install nginx -y

echo "📁 Deploying Frontend..."
sudo mkdir -p /var/www/flashfeed
sudo cp index.html /var/www/flashfeed/index.html

echo "⚙️ Configuring Nginx Reverse Proxy..."
sudo tee /etc/nginx/sites-available/flashfeed << EOF
server {
    listen 80;
    server_name _;

    root /var/www/flashfeed;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location /api/ {
        proxy_pass http://$APP_SERVER_IP:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/flashfeed /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default || true

sudo nginx -t
sudo systemctl restart nginx
echo "✅ Web Layer Setup Completed Successfully!"