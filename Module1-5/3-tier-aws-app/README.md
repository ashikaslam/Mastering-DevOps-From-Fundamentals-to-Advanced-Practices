# FlashFeed 3-Tier Automated Infrastructure 🚀

This repository contains a fully automated, production-ready **3-Tier Architecture** deployed on AWS EC2 instances. The infrastructure isolates the Presentation, Application, and Data layers to ensure high security, scalability, and clean configuration management.

---

## 🏗️ Architecture Overview

The project is structured into three isolated layers:
1. **Presentation Layer (Web Server):** Managed by **Nginx**, handling public HTTP traffic (Port 80) and acting as a Reverse Proxy.
2. **Application Layer (App Server):** A **Node.js/Express** API running in the background via **PM2** (Port 5000).
3. **Data Layer (Database Server):** A secured **PostgreSQL** database instance (Port 5432).

---

## 📂 Repository Structure

```text
flashfeed-3tier/
├── data-layer/
│   └── setup-db.sh      # Automated Bash script for PostgreSQL installation & configuration
├── app-layer/
│   ├── package.json     # Node.js dependencies (Express, pg)
│   ├── server.js        # Backend REST API core logic
│   └── setup-app.sh     # Automated Bash script for Node.js, PM2 & app runtime
└── web-layer/
    ├── index.html       # Dynamic HTML5/CSS3 frontend monitor interface
    └── setup-web.sh     # Automated Bash script for Nginx installation & Reverse Proxy routing







🛠️ Deployment GuideFollow these steps to deploy each layer on its respective AWS EC2 Instance (Ubuntu 24.04 LTS recommended).🗄️ Step 1: Data Layer (DB Server)SSH into your Database Server instance and execute:Bashcd data-layer/
chmod +x setup-db.sh
./setup-db.sh
What this does: Installs PostgreSQL, creates the database (mydb) and user (dbuser), configures postgresql.conf to listen on all network interfaces, and updates access rules in pg_hba.conf.🧠 Step 2: Application Layer (App Server)SSH into your Application Server instance. When running the script, pass your DB Server's Private IP as an environment variable:Bashcd app-layer/
chmod +x setup-app.sh
DB_HOST="YOUR_DB_SERVER_PRIVATE_IP" ./setup-app.sh
What this does: Installs Node.js 20 LTS, pulls NPM packages, injects runtime environment variables, and starts the service securely under PM2 process management.🌐 Step 3: Presentation Layer (Web Server)SSH into your Web Server instance. Pass your App Server's Private IP during execution:Bashcd web-layer/
chmod +x setup-web.sh
APP_SERVER_IP="YOUR_APP_SERVER_PRIVATE_IP" ./setup-web.sh
What this does: Installs Nginx, deploys the frontend dashboard to /var/www/flashfeed, creates custom server blocks, configurations, and handles the proxy redirection for /api/ traffic.🔒 Network & Security Group Best PracticesTo secure this setup in a real production environment, restrict your AWS Inbound Security Groups as follows:Security GroupInbound PortAllowed SourcePurposeWeb-SG80 (HTTP)0.0.0.0/0 (Anywhere)Public web traffic accessApp-SG5000 (Custom)Web-SG IDAllow requests ONLY from the Web ServerDB-SG5432 (PostgreSQL)App-SG IDAllow queries ONLY from the App Server🎯 Verification & Health CheckOnce deployment is complete, grab the Public IP of your Web Server and open it in any web browser:Plaintexthttp://YOUR_WEB_SERVER_PUBLIC_IP