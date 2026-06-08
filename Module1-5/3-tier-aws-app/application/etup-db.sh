#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "=================================================="
echo "🚀 Starting Automated App-Server Setup for 3-Tier App..."
echo "=================================================="

# 1. Update system packages
echo "🔄 Updating system packages..."
sudo apt update -y

# 2. Install Node.js (Version 20 LTS) and NPM
echo "🟢 Installing Node.js 20 LTS and NPM..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install nodejs -y
else
    echo "📌 Node.js is already installed. Skipping..."
fi

echo "📌 Node Version: $(node -v)"
echo "📌 NPM Version: $(npm -v)"

# 3. Create App Directory and Files (If deploying from scratch)
# Note: If cloning from Git later, this part can be replaced with 'git clone'
echo "📂 Setting up Application Directory..."
APP_DIR="$HOME/app"
mkdir -p "$APP_DIR"
cd "$APP_DIR"

# 4. Generate package.json dynamically
echo "📦 Generating package.json..."
cat << 'EOF' > package.json
{
  "name": "flashfeed-backend",
  "version": "1.0.0",
  "description": "Backend API for 3-Tier Architecture",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.19.2",
    "pg": "^8.11.5"
  }
}
EOF

# 5. Generate server.js dynamically
echo "📝 Generating server.js..."
cat << 'EOF' > server.js
const express = require('express');
const { Pool } = require('pg');

const app = express();
const PORT = process.env.PORT || 5000;

// Database connection pool logic
const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'dbuser',
    password: process.env.DB_PASSWORD || 'securepassword123',
    database: process.env.DB_NAME || 'mydb',
    port: 5432,
});

// Health check and status endpoint
app.get('/api/status', async (req, res) => {
    try {
        const dbRes = await pool.query('SELECT NOW()');
        res.json({
            status: "Success",
            message: "Welcome to the 3-Tier Application!",
            database_time: dbRes.rows[0].now
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ 
            status: "Error", 
            message: "Database connection failed" 
        });
    }
});

app.listen(PORT, () => {
    console.log(`Backend running on port ${PORT}`);
});
EOF

# 6. Install Project Dependencies
echo "⚡ Installing node_modules..."
npm install

# 7. Install and Configure PM2 Process Manager Globals
echo "⚙️ Installing PM2 Process Manager..."
if ! command -v pm2 &> /dev/null; then
    sudo npm install -g pm2
else
    echo "📌 PM2 is already installed. Skipping..."
fi

# 8. Start Application using PM2 with proper DB_HOST Inject
echo "📡 Injecting DB Environment and Starting Application..."
# Delete old process if it exists to avoid conflicts
pm2 delete backend-api &> /dev/null || true

# হার্ডকোডেড আইপির বদলে স্ক্রিপ্টটি রান করার সময় DB_HOST ভ্যারিয়েবলটি পাস করতে হবে
# উদাহরণ: DB_HOST="172.31.47.223" ./setup-app.sh
if [ -z "$DB_HOST" ]; then
    echo "⚠️ Warning: DB_HOST environment variable not set. Defaulting to localhost."
    DB_HOST="localhost"
fi

DB_HOST="$DB_HOST" pm2 start server.js --name "backend-api"

# 9. Configure PM2 to start on system boot
echo "🔄 Configuring PM2 to start on system boot..."
pm2 save

echo "=================================================="
echo "✅ App Layer (Backend) Setup Completed Successfully!"
echo "=================================================="