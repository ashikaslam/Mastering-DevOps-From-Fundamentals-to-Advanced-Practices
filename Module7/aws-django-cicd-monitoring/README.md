# AWS Django CI/CD + Monitoring

A production-ready Django backend deployed natively on AWS EC2 (Ubuntu), with automated GitHub Actions CI/CD and a full Prometheus + Grafana + Alertmanager observability stack — no Docker required.

---

## Table of Contents

1. [Repository Structure](#repository-structure)
2. [Local Development Setup](#local-development-setup)
3. [EC2 Server Prerequisites](#ec2-server-prerequisites)
   - [System Packages](#1-system-packages)
   - [PostgreSQL](#2-postgresql)
   - [Project Clone & Virtual Environment](#3-project-clone--virtual-environment)
   - [Gunicorn Systemd Service](#4-gunicorn-systemd-service)
   - [Nginx](#5-nginx)
   - [Node Exporter](#6-node-exporter)
   - [Prometheus](#7-prometheus)
   - [Alertmanager](#8-alertmanager)
   - [Grafana](#9-grafana)
4. [CI/CD Setup](#cicd-setup)
5. [Monitoring Setup](#monitoring-setup)
6. [Port Reference](#port-reference)

---

## Repository Structure

```
aws-django-cicd-monitoring/
├── .env.example                    # Template for environment variables
├── .gitignore
├── manage.py
├── requirements.txt
│
├── core/                           # Django project package
│   ├── settings.py                 # Reads all config from env vars
│   ├── urls.py
│   └── wsgi.py
│
├── api/                            # Sample Django app
│   ├── migrations/
│   ├── models.py
│   ├── views.py                    # GET /api/health/ endpoint
│   └── urls.py
│
├── .github/
│   └── workflows/
│       └── deploy.yml              # GitHub Actions CI/CD pipeline
│
└── monitoring/
    ├── prometheus.yml              # Prometheus scrape config
    ├── alert_rules.yml             # Alerting rules (CPU, RAM, Disk, Down)
    ├── alertmanager.yml            # SMTP email alert routing
    ├── nginx/
    │   └── django.conf             # Nginx reverse proxy config
    └── systemd/
        ├── gunicorn.service
        ├── prometheus.service
        ├── node_exporter.service
        ├── alertmanager.service
        └── grafana-server.service
```

---

## Local Development Setup

```bash
# 1. Clone the repository
git clone https://github.com/<your-username>/aws-django-cicd-monitoring.git
cd aws-django-cicd-monitoring

# 2. Create and activate a virtual environment
python3 -m venv venv
source venv/bin/activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Configure environment variables
cp .env.example .env
# Edit .env — set SECRET_KEY, DEBUG=True, and DB credentials

# 5. Run migrations (uses SQLite locally if you temporarily switch the DB engine)
python manage.py migrate

# 6. Create a superuser
python manage.py createsuperuser

# 7. Start the development server
python manage.py runserver
# Visit: http://127.0.0.1:8000/api/health/
```

---

## EC2 Server Prerequisites

Start with a fresh **Ubuntu 22.04 LTS** EC2 instance (t2.micro or larger).  
Open the following ports in your Security Group: `22`, `80`, `443`, `9090`, `9093`, `9100`, `3000`.

### 1. System Packages

```bash
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y \
    python3 python3-pip python3-venv python3-dev \
    build-essential libpq-dev \
    nginx git curl wget
```

### 2. PostgreSQL

```bash
sudo apt-get install -y postgresql postgresql-contrib

# Start and enable
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Create database and user
sudo -u postgres psql <<EOF
CREATE DATABASE django_db;
CREATE USER django_user WITH PASSWORD 'strongpassword';
ALTER ROLE django_user SET client_encoding TO 'utf8';
ALTER ROLE django_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE django_user SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE django_db TO django_user;
EOF
```

### 3. Project Clone & Virtual Environment

```bash
cd /home/ubuntu
git clone https://github.com/<your-username>/aws-django-cicd-monitoring.git
cd aws-django-cicd-monitoring

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Create .env from template and fill in real values
cp .env.example .env
nano .env

# Run initial migrations and collect static files
python manage.py migrate
python manage.py collectstatic --noinput
python manage.py createsuperuser

# Create Gunicorn log directory
sudo mkdir -p /var/log/gunicorn
sudo chown ubuntu:www-data /var/log/gunicorn
```

### 4. Gunicorn Systemd Service

```bash
sudo cp monitoring/systemd/gunicorn.service /etc/systemd/system/gunicorn.service
sudo systemctl daemon-reload
sudo systemctl enable gunicorn
sudo systemctl start gunicorn
sudo systemctl status gunicorn
```

### 5. Nginx

```bash
# Copy the virtual host config
sudo cp monitoring/nginx/django.conf /etc/nginx/sites-available/django

# Edit the server_name to your EC2 IP or domain
sudo nano /etc/nginx/sites-available/django

# Enable the site
sudo ln -s /etc/nginx/sites-available/django /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default   # remove default site

# Test and reload
sudo nginx -t
sudo systemctl enable nginx
sudo systemctl restart nginx
```

### 6. Node Exporter

```bash
# Download latest Node Exporter (check https://github.com/prometheus/node_exporter/releases)
NODE_EXPORTER_VERSION="1.8.1"
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar xvf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
sudo cp node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
sudo useradd --no-create-home --shell /bin/false node_exporter

sudo cp monitoring/systemd/node_exporter.service /etc/systemd/system/node_exporter.service
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

# Verify metrics endpoint
curl http://localhost:9100/metrics | head -20
```

### 7. Prometheus

```bash
# Download latest Prometheus (check https://github.com/prometheus/prometheus/releases)
PROMETHEUS_VERSION="2.52.0"
wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
tar xvf prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz

sudo cp prometheus-${PROMETHEUS_VERSION}.linux-amd64/prometheus /usr/local/bin/
sudo cp prometheus-${PROMETHEUS_VERSION}.linux-amd64/promtool   /usr/local/bin/

# Create user and directories
sudo useradd --no-create-home --shell /bin/false prometheus
sudo mkdir -p /etc/prometheus /var/lib/prometheus/data
sudo chown prometheus:prometheus /etc/prometheus /var/lib/prometheus/data

# Copy config files
sudo cp monitoring/prometheus.yml  /etc/prometheus/prometheus.yml
sudo cp monitoring/alert_rules.yml /etc/prometheus/alert_rules.yml
sudo chown -R prometheus:prometheus /etc/prometheus

sudo cp monitoring/systemd/prometheus.service /etc/systemd/system/prometheus.service
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

# Verify
curl http://localhost:9090/-/healthy
```

### 8. Alertmanager

```bash
# Download latest Alertmanager (check https://github.com/prometheus/alertmanager/releases)
ALERTMANAGER_VERSION="0.27.0"
wget https://github.com/prometheus/alertmanager/releases/download/v${ALERTMANAGER_VERSION}/alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz
tar xvf alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz

sudo cp alertmanager-${ALERTMANAGER_VERSION}.linux-amd64/alertmanager  /usr/local/bin/
sudo cp alertmanager-${ALERTMANAGER_VERSION}.linux-amd64/amtool         /usr/local/bin/

sudo useradd --no-create-home --shell /bin/false alertmanager
sudo mkdir -p /etc/alertmanager /var/lib/alertmanager/data
sudo chown alertmanager:alertmanager /etc/alertmanager /var/lib/alertmanager/data

# Edit SMTP placeholders before copying
nano monitoring/alertmanager.yml
sudo cp monitoring/alertmanager.yml /etc/alertmanager/alertmanager.yml
sudo chown alertmanager:alertmanager /etc/alertmanager/alertmanager.yml

sudo cp monitoring/systemd/alertmanager.service /etc/systemd/system/alertmanager.service
sudo systemctl daemon-reload
sudo systemctl enable alertmanager
sudo systemctl start alertmanager
```

### 9. Grafana

```bash
# Install via official apt repository
sudo apt-get install -y apt-transport-https software-properties-common
wget -q -O - https://apt.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt-get update
sudo apt-get install -y grafana

sudo systemctl daemon-reload
sudo systemctl enable grafana-server
sudo systemctl start grafana-server

# Default credentials: admin / admin (change on first login)
# Access: http://<EC2_PUBLIC_IP>:3000
```

---

## CI/CD Setup

The pipeline in `.github/workflows/deploy.yml` triggers on every push to `main` and deploys via SSH.

### Required GitHub Secrets

Go to your repository → **Settings → Secrets and variables → Actions → New repository secret** and add:

| Secret Name        | Description                                              | Example                        |
|--------------------|----------------------------------------------------------|--------------------------------|
| `AWS_EC2_SSH_KEY`  | Full contents of your EC2 private key (`.pem` file)      | `-----BEGIN RSA PRIVATE KEY...`|
| `EC2_HOST`         | Public IP address or DNS of your EC2 instance            | `54.123.45.67`                 |
| `EC2_USER`         | SSH username for the EC2 instance                        | `ubuntu`                       |

### How it works

1. A push to `main` triggers the workflow.
2. GitHub Actions runner SSHes into the EC2 instance using the stored private key.
3. The remote script pulls the latest code, updates dependencies, runs migrations, collects static files, and restarts Gunicorn — all in one atomic sequence.
4. If any step fails, the script exits immediately (`set -e`) and the deployment is marked failed in GitHub.

---

## Monitoring Setup

### Connect Node Exporter → Prometheus

Node Exporter is already configured as a scrape target in `monitoring/prometheus.yml` at `localhost:9100`. After both services are running, verify in the Prometheus UI:

```
http://<EC2_PUBLIC_IP>:9090/targets
```

Both `prometheus` and `node_exporter` targets should show **State: UP**.

### Add Prometheus as a Grafana Data Source

1. Open Grafana at `http://<EC2_PUBLIC_IP>:3000` and log in.
2. Go to **Connections → Data Sources → Add data source**.
3. Select **Prometheus**.
4. Set the URL to `http://localhost:9090`.
5. Click **Save & Test** — you should see "Data source is working".

### Import the Linux System Dashboard

1. In Grafana, go to **Dashboards → Import**.
2. Enter dashboard ID **`1860`** (Node Exporter Full — the most popular community dashboard).
3. Click **Load**, select your Prometheus data source, then click **Import**.

The dashboard will immediately show live graphs for:
- **CPU** usage per core and overall
- **RAM** used / available / cached
- **Disk** I/O and space utilisation
- **Network** traffic (bytes in/out)
- **System load** and uptime

### Verify Alertmanager

```bash
# Check Alertmanager is reachable
curl http://localhost:9093/-/healthy

# View active alerts
curl http://localhost:9093/api/v2/alerts
```

Open the Alertmanager UI at `http://<EC2_PUBLIC_IP>:9093` to see alert status and silences.

---

## Port Reference

| Service        | Port  | Notes                                  |
|----------------|-------|----------------------------------------|
| Nginx (HTTP)   | 80    | Reverse proxy to Gunicorn              |
| Nginx (HTTPS)  | 443   | After Certbot SSL setup                |
| Gunicorn       | sock  | Unix socket at `/run/gunicorn.sock`    |
| Prometheus     | 9090  | Metrics UI & API                       |
| Alertmanager   | 9093  | Alert routing UI                       |
| Node Exporter  | 9100  | Raw system metrics endpoint            |
| Grafana        | 3000  | Dashboard UI                           |
| PostgreSQL     | 5432  | Internal only — do not expose publicly |
