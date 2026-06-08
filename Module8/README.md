# Module 8 — Automated Deployment & Infrastructure Monitoring

> A production-grade Django application deployed to AWS EC2 via a GitHub Actions CI/CD pipeline, with a full observability stack powered by Prometheus, Grafana, Loki, and Promtail.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Repository Structure](#repository-structure)
3. [Prerequisites](#prerequisites)
4. [Part 1 — Infrastructure Provisioning with Terraform](#part-1--infrastructure-provisioning-with-terraform)
5. [Part 2 — CI/CD Pipeline with GitHub Actions](#part-2--cicd-pipeline-with-github-actions)
6. [Part 3 — Monitoring Stack Setup](#part-3--monitoring-stack-setup)
   - [Prometheus & Node Exporter](#prometheus--node-exporter)
   - [Loki & Promtail](#loki--promtail)
   - [Grafana](#grafana)
7. [Screenshots](#screenshots)
8. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        GitHub Repository                        │
│                                                                 │
│  ┌──────────┐  git push   ┌──────────────────────────────────┐  │
│  │Developer │ ──────────► │  GitHub Actions CI/CD Pipeline   │  │
│  └──────────┘             │  1. Run Django tests             │  │
│                           │  2. SSH deploy to EC2            │  │
│                           │  3. Verify HTTP 200              │  │
│                           └──────────────┬───────────────────┘  │
└──────────────────────────────────────────┼──────────────────────┘
                                           │ SSH Deploy
                                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                     AWS EC2 (Ubuntu 22.04)                      │
│                                                                 │
│  ┌──────────────────┐   ┌────────────────────────────────────┐  │
│  │  Django App      │   │         Monitoring Stack           │  │
│  │  (Gunicorn :3000)│   │                                    │  │
│  │  /metrics ──────────►│  Prometheus (:9090)                │  │
│  └──────────────────┘   │  Node Exporter (:9100)             │  │
│                         │  Loki (:3100)                      │  │
│  ┌──────────────────┐   │  Promtail (log shipper)            │  │
│  │  App Logs        │──►│  Grafana (:3001)                   │  │
│  └──────────────────┘   └────────────────────────────────────┘  │
│                                                                 │
│  Security Group: 22, 80, 3000, 3001, 9090, 9100, 3100          │
└─────────────────────────────────────────────────────────────────┘
```

**Data flow:**
- **Metrics**: Django `/metrics` + Node Exporter → scraped by Prometheus → visualised in Grafana
- **Logs**: App logs + system logs → collected by Promtail → pushed to Loki → visualised in Grafana

---

## Repository Structure

```
Module8/
├── .github/
│   └── workflows/
│       └── deploy.yml          # GitHub Actions CI/CD pipeline
├── terraform/
│   ├── main.tf                 # EC2 instance + security group
│   ├── variables.tf            # Input variables
│   ├── outputs.tf              # Public IP, URLs, SSH command
│   └── terraform.tfvars.example
├── monitoring/
│   ├── docker-compose.monitoring.yml   # Full monitoring stack
│   ├── prometheus/
│   │   └── prometheus.yml      # Scrape config
│   ├── loki/
│   │   └── loki-config.yml     # Loki storage config
│   └── promtail/
│       └── promtail-config.yml # Log scrape & pipeline config
├── grafana/
│   ├── dashboards/
│   │   └── README.md           # Dashboard export guide
│   └── provisioning/
│       └── datasources/
│           └── datasources.yml # Auto-provision Prometheus & Loki
├── core/                       # Django project package
│   ├── __init__.py
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
├── app/                        # Django application
│   ├── __init__.py
│   ├── views.py
│   ├── urls.py
│   └── tests.py
├── manage.py
├── requirements.txt
├── .env.example
├── .gitignore
└── README.md
```

---

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Terraform | >= 1.5.0 | Infrastructure provisioning |
| AWS CLI | >= 2.x | AWS authentication |
| Python | >= 3.11 | Django runtime |
| Docker & Docker Compose | Latest stable | Running the monitoring stack |
| An AWS account | — | Hosting the EC2 instance |
| An EC2 Key Pair | — | SSH access to the server |

---

## Part 1 — Infrastructure Provisioning with Terraform

### 1.1 Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, region (e.g. us-east-1), and output format (json)
```

### 1.2 Set Terraform Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
aws_region    = "us-east-1"
instance_type = "t2.micro"
ami_id        = "ami-0c7217cdde317cfec"   # Ubuntu 22.04 LTS
key_name      = "your-keypair-name"       # Must already exist in AWS
project_name  = "module8-monitoring"
```

### 1.3 Initialise and Apply

```bash
terraform init
terraform plan    # Review the execution plan
terraform apply   # Type 'yes' to confirm
```

### 1.4 Capture Outputs

After a successful apply, Terraform prints the instance details:

```
Outputs:

instance_id    = "i-0abc123def456"
public_ip      = "54.123.45.67"
ssh_command    = "ssh -i ~/.ssh/your-keypair.pem ubuntu@54.123.45.67"
grafana_url    = "http://54.123.45.67:3001"
prometheus_url = "http://54.123.45.67:9090"
django_app_url = "http://54.123.45.67:3000"
```

Save the **public IP** — you'll need it for GitHub Secrets.

### Screenshot — Terraform Deployment

> Replace the placeholder below with your actual screenshot.

![Terraform Apply Output](docs/screenshots/terraform-deployment.png)

---

## Part 2 — CI/CD Pipeline with GitHub Actions

### 2.1 Configure GitHub Secrets

In your repository go to **Settings → Secrets and variables → Actions → New repository secret** and add the following:

| Secret Name | Value |
|-------------|-------|
| `EC2_SSH_KEY` | Full contents of your `.pem` private key file |
| `EC2_HOST` | Public IP of your EC2 instance (from Terraform output) |
| `REPO_URL` | Your repository's HTTPS clone URL |
| `DJANGO_SECRET_KEY` | A strong random string for Django |

### 2.2 How the Pipeline Works

The workflow in `.github/workflows/deploy.yml` triggers on every push to `main` and runs two sequential jobs:

**Job 1 — `test`**
1. Checks out the repository.
2. Sets up Python 3.11 and installs `requirements.txt`.
3. Runs `python manage.py test`.

**Job 2 — `deploy`** _(only runs if tests pass)_
1. Writes the SSH private key from secrets to `~/.ssh/deploy_key.pem`.
2. SSHs into the EC2 instance.
3. Pulls the latest code (or clones on first run).
4. Installs dependencies, runs migrations, collects static files.
5. Restarts the Gunicorn process.
6. Verifies the deployment by checking for HTTP 200 on port 3000.

### 2.3 Trigger a Deployment

```bash
git add .
git commit -m "feat: initial deployment"
git push origin main
```

Monitor the run under the **Actions** tab of your repository.

### Screenshot — Successful CI/CD Execution

> Replace the placeholder below with your actual screenshot.

![GitHub Actions Success](docs/screenshots/cicd-pipeline-success.png)

---

## Part 3 — Monitoring Stack Setup

SSH into your EC2 instance:

```bash
ssh -i ~/.ssh/your-keypair.pem ubuntu@<EC2_PUBLIC_IP>
```

Clone your repository (if not already done by the pipeline):

```bash
cd /home/ubuntu
git clone <REPO_URL> app
cd app
```

### Launch the Monitoring Stack

```bash
cd monitoring
docker-compose -f docker-compose.monitoring.yml up -d
```

Verify all containers are running:

```bash
docker-compose -f docker-compose.monitoring.yml ps
```

Expected output:

```
NAME             STATUS
prometheus       Up
node_exporter    Up
loki             Up
promtail         Up
grafana          Up
```

---

### Prometheus & Node Exporter

**Prometheus** scrapes metrics from three targets defined in `monitoring/prometheus/prometheus.yml`:

| Job | Target | What it collects |
|-----|--------|-----------------|
| `prometheus` | `localhost:9090` | Prometheus self-metrics |
| `node_exporter` | `localhost:9100` | CPU, RAM, disk, network I/O |
| `django_app` | `localhost:3000/metrics` | HTTP request counts, latency, DB queries |

**Verify Prometheus is up:**

Open `http://<EC2_PUBLIC_IP>:9090` in your browser. Navigate to **Status → Targets** — all three targets should show **State: UP**.

**Useful PromQL queries:**

```promql
# CPU usage percentage
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Available memory (bytes)
node_memory_MemAvailable_bytes

# Total Django HTTP requests
sum(django_http_requests_total_by_method_total)

# Request rate per second (last 5 min)
rate(django_http_requests_total_by_method_total[5m])
```

---

### Loki & Promtail

**Loki** is a log aggregation system. **Promtail** is its agent, which tails log files and ships them to Loki.

The Promtail configuration in `monitoring/promtail/promtail-config.yml` ships:

| Job | Source | Labels |
|-----|--------|--------|
| `system_auth` | `/var/log/auth.log` | `job=auth` |
| `syslog` | `/var/log/syslog` | `job=syslog` |
| `django_app` | `/home/ubuntu/app/logs/*.log` | `job=django`, `level`, `logger` |

**Make sure your Django application writes logs to the expected path:**

```bash
mkdir -p /home/ubuntu/app/logs
# Gunicorn will capture stdout/stderr; configure the app to log to a file:
gunicorn core.wsgi:application \
  --bind 0.0.0.0:3000 \
  --workers 3 \
  --access-logfile /home/ubuntu/app/logs/access.log \
  --error-logfile /home/ubuntu/app/logs/error.log \
  --daemon
```

**Verify Loki is receiving logs:**

```bash
curl http://localhost:3100/ready
# Expected: ready
```

---

### Grafana

Grafana is available at `http://<EC2_PUBLIC_IP>:3001`.

- **Default credentials:** `admin` / `admin` (change immediately via **Profile → Change Password**)
- Data sources (Prometheus and Loki) are **automatically provisioned** from `grafana/provisioning/datasources/datasources.yml` on startup.

#### Import the Node Exporter Dashboard

1. In Grafana, click **Dashboards → Import**.
2. Enter dashboard ID **`1860`** and click **Load**.
3. Select **Prometheus** as the data source.
4. Click **Import**.

You should immediately see host metrics panels for CPU, memory, disk, and network.

#### Import the Loki Logs Dashboard

1. Click **Dashboards → Import**.
2. Enter dashboard ID **`13639`** and click **Load**.
3. Select **Loki** as the data source.
4. Click **Import**.

#### Screenshot — Grafana Host Metrics Dashboard

> Replace the placeholder below with your actual screenshot.

![Grafana Node Exporter Dashboard](docs/screenshots/grafana-host-metrics.png)

#### Screenshot — Loki Log Visualisation

> Replace the placeholder below with your actual screenshot.

![Loki Log Visualisation in Grafana](docs/screenshots/loki-log-visualization.png)

---

## Screenshots

| # | Description | File |
|---|-------------|------|
| 1 | Successful CI/CD pipeline execution | `docs/screenshots/cicd-pipeline-success.png` |
| 2 | Terraform apply output | `docs/screenshots/terraform-deployment.png` |
| 3 | Grafana host metrics dashboard | `docs/screenshots/grafana-host-metrics.png` |
| 4 | Loki log visualisation | `docs/screenshots/loki-log-visualization.png` |

> Create the `docs/screenshots/` directory and add your PNG files before submission.

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| GitHub Actions job fails at SSH step | Wrong `EC2_SSH_KEY` or `EC2_HOST` secret | Re-check secrets; ensure the key has no trailing newline |
| Terraform fails: `InvalidKeyPair.NotFound` | Key pair name doesn't match AWS | Check key pair name in the EC2 console |
| Prometheus targets show `DOWN` | Port not open or service not running | Check security group inbound rules; run `docker ps` |
| Grafana shows "No data" | Wrong data source URL | Ensure Grafana container can reach `prometheus:9090` — both must be on the same Docker network |
| Loki returns 502 | Promtail path mismatch | Verify log file paths in `promtail-config.yml` exist on the host |
| Django 500 error after deploy | Missing migration or bad env var | SSH in and run `python manage.py migrate`; check `.env` |

---

## Clean Up

To avoid ongoing AWS charges, destroy resources when finished:

```bash
cd terraform
terraform destroy
# Type 'yes' to confirm
```

---

*Module 8 Assignment — Automated Deployment & Infrastructure Monitoring*
