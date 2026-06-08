# Module 3 Assignment
## Nginx Web Server with HTTPS, SSL & Reverse Proxy on AWS EC2

---

## Project Overview
This project demonstrates a production-like deployment using AWS EC2, Nginx, SSL, and Reverse Proxy.

---

## 1. EC2 Setup

- Ubuntu Server 22.04 LTS
- Instance Type: t2.micro
- Key Pair: my-ec2-key.pem

### SSH Connection
```bash
chmod 400 my-ec2-key.pem
ssh -i my-ec2-key.pem ubuntu@<EC2_PUBLIC_IP>
```

---

## 2. System Update
```bash
sudo apt update && sudo apt upgrade -y
```

---

## 3. Install Nginx & OpenSSL
```bash
sudo apt install nginx openssl -y
```

Enable Nginx:
```bash
sudo systemctl enable nginx
sudo systemctl start nginx
```

---

## 4. Static Website Setup
```bash
sudo mkdir -p /var/www/secure-app
```

Create HTML:
```bash
sudo nano /var/www/secure-app/index.html
```

Content:
```html
<h1>Secure Server Running via Nginx</h1>
```

---

## 5. Nginx HTTP Config
```bash
sudo nano /etc/nginx/sites-available/secure-app
```

```nginx
server {
    listen 80;
    server_name _;

    root /var/www/secure-app;
    index index.html;
}
```

Enable site:
```bash
sudo ln -s /etc/nginx/sites-available/secure-app /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

---

## 6. SSL Setup
```bash
sudo mkdir -p /etc/nginx/ssl
```

Generate SSL:
```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-keyout /etc/nginx/ssl/self.key \
-out /etc/nginx/ssl/self.crt
```

---

## 7. HTTPS + Reverse Proxy

```nginx
server {
    listen 80;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;

    ssl_certificate /etc/nginx/ssl/self.crt;
    ssl_certificate_key /etc/nginx/ssl/self.key;

    root /var/www/secure-app;
    index index.html;

    location /api/ {
        proxy_pass http://127.0.0.1:3000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## 8. Backend Setup (Port 3000)

```bash
sudo apt install nodejs npm -y
```

### server.js
```javascript
const http = require('http');

http.createServer((req, res) => {
    res.end('Backend Running on Port 3000');
}).listen(3000);
```

Run:
```bash
node server.js
```

---

## 9. Testing

- https://<EC2_IP>
- http://<EC2_IP> → redirect
- https://<EC2_IP>/api/

---

## Architecture

Browser → Nginx (HTTPS) → Static Site + Reverse Proxy → Backend (3000)
