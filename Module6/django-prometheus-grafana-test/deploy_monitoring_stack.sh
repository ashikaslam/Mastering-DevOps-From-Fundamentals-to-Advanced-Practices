#!/usr/bin/env bash
# ==============================================================================
# Script Name:    deploy_monitoring_stack.sh
# Description:    Automated configuration engine for Prometheus & Grafana.
# Platform:       Ubuntu 22.04 LTS / 24.04 LTS (AMD64)
# Execution:      chmod +x deploy_monitoring_stack.sh && sudo ./deploy_monitoring_stack.sh
# ==============================================================================

set -euo pipefail

# টার্মিনাল কালার কোড
printf_cyan()   { printf "\\e[36m%b\\e[0m\\n" "$1"; }
printf_green()  { printf "\\e[32m%b\\e[0m\\n" "$1"; }
printf_yellow() { printf "\\e[33m%b\\e[0m\\n" "$1"; }

# রুট ইউজার চেক
if [[ "$EUID" -ne 0 ]]; then
    printf_yellow "Error: এই স্ক্রিপ্টটি রান করতে sudo প্রিভিলেজ লাগবে।"
    exit 1
fi

printf_cyan "================================================================"
printf_cyan "   অটোমেটেড প্রমিথিউস এবং গ্রাফানা ইনস্টলেশন শুরু হচ্ছে...   "
printf_cyan "================================================================"

# স্টেপ ১: সিস্টেম আপডেট ও প্রয়োজনীয় টুলস ইনস্টল
printf_yellow "\\n[Step 1]: সিস্টেম প্যাকেজ আপডেট ও ডিপেন্ডেন্সি ইনস্টল করা হচ্ছে..."
apt-get update -y
apt-get install -y wget curl tar adduser libfontconfig1 musl gpg

# স্টেপ ২: প্রমিথিউস ডাউনলোড ও সেটআপ
printf_yellow "\\n[Step 2]: প্রমিথিউস বাইনারি ডাউনলোড ও কনফিগার করা হচ্ছে..."
PROM_VERSION="2.51.1"
cd /tmp

wget -q --show-progress https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/prometheus-${PROM_VERSION}.linux-amd64.tar.gz
tar -xf prometheus-${PROM_VERSION}.linux-amd64.tar.gz
cd prometheus-${PROM_VERSION}.linux-amd64

mkdir -p /etc/prometheus
mkdir -p /var/lib/prometheus

cp prometheus promtool /usr/local/bin/
cp -r consoles console_libraries /etc/prometheus/

# ডিফল্ট ক্লিন কনফিগারেশন ফাইল তৈরি
cat << EOF > /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
EOF

# SystemD সার্ভিস তৈরি
cat << EOF > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus System Monitoring Engine
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/prometheus \\
    --config.file=/etc/prometheus/prometheus.yml \\
    --storage.tsdb.path=/var/lib/prometheus/ \\
    --web.console.templates=/etc/prometheus/consoles \\
    --web.console.libraries=/etc/prometheus/console_libraries \\
    --web.listen-address=0.0.0.0:9090

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now prometheus
printf_green "Prometheus সফলভাবে ইনস্টল এবং চালু হয়েছে!"

# স্টেপ ৩: গ্রাফানা ড্যাশবোর্ড ইনস্টল
printf_yellow "\\n[Step 3]: গ্রাফানা রিপোজিটরি অ্যাড এবং ইনস্টল করা হচ্ছে..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://apt.grafana.com/gpg.key | gpg --dearmor --yes -o /etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list

apt-get update -y
apt-get install -y grafana

systemctl daemon-reload
systemctl enable --now grafana-server
printf_green "Grafana সফলভাবে ইনস্টল এবং ব্যাকগ্রাউন্ডে চালু হয়েছে!"

# ইনস্টলেশন সামারি
printf_cyan "\\n================================================================"
printf_green "          অভিনন্দন! ইনস্টলেশন সফলভাবে সম্পন্ন হয়েছে।          "
printf_cyan "================================================================"
printf_cyan "পোর্টস এবং ইউআরএল সামারি:"
printf_cyan " -> Prometheus URL : http://localhost:9090"
printf_cyan " -> Grafana UI URL : http://localhost:3000 (ডিফল্ট ইউজার: admin / পাসওয়ার্ড: admin)"
printf_cyan "================================================================"