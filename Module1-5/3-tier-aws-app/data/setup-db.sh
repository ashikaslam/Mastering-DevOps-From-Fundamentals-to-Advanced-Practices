#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "=================================================="
echo "🚀 Starting Automated PostgreSQL Setup for 3-Tier App..."
echo "=================================================="

# 1. Update system and install PostgreSQL
echo "🔄 Updating packages and installing PostgreSQL..."
sudo apt update
sudo apt install postgresql postgresql-contrib -y

# 2. Get PostgreSQL Version (Dynamic path handling)
PG_VERSION=$(psql --version | awk '{print $3}' | cut -d. -f1)
CONF_DIR="/etc/postgresql/$PG_VERSION/main"

echo "📌 Detected PostgreSQL Version: $PG_VERSION"
echo "📌 Configuration Directory: $CONF_DIR"

# 3. Create Database, User, and Grant Privileges
echo "🔑 Configuring Database and User..."
sudo -i -u postgres psql -c "CREATE DATABASE mydb;" || echo "Database might already exist, skipping..."
sudo -i -u postgres psql -c "CREATE USER dbuser WITH PASSWORD 'securepassword123';" || echo "User might already exist, skipping..."
sudo -i -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE mydb TO dbuser;"

# 4. Configure listen_addresses to '*' in postgresql.conf
echo "🌐 Updating postgresql.conf to listen on all interfaces..."
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" "$CONF_DIR/postgresql.conf"
# If already uncommented but set to localhost, handle that too
sudo sed -i "s/listen_addresses = 'localhost'/listen_addresses = '*'/g" "$CONF_DIR/postgresql.conf"

# 5. Append host rule to pg_hba.conf for remote connection
echo "🔒 Updating pg_hba.conf for App-Server network access..."
# Check if rule already exists to avoid duplication
if ! sudo grep -q "host    mydb            dbuser" "$CONF_DIR/pg_hba.conf"; then
    echo "host    mydb            dbuser          0.0.0.0/0               md5" | sudo tee -a "$CONF_DIR/pg_hba.conf"
fi

# 6. Restart PostgreSQL to apply changes
echo "🔄 Restarting PostgreSQL Service..."
sudo systemctl restart postgresql

echo "=================================================="
echo "✅ Data Layer Setup Completed Successfully!"
echo "=================================================="