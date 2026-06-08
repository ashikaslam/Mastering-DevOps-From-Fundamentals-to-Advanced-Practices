# Grafana Dashboard Export

## How to Export Your Dashboard as JSON

Once your Grafana instance is running and you have configured your dashboards, follow these steps to export and save them to this directory for version control.

### Steps

1. Open Grafana in your browser: `http://<EC2_PUBLIC_IP>:3001`
2. Log in with your admin credentials.
3. Navigate to the dashboard you want to export (e.g., **Node Exporter Full** or **Loki Logs**).
4. Click the **Share** icon (top toolbar) → select the **Export** tab.
5. Toggle **Export for sharing externally** to `ON`.
6. Click **Save to file** — this downloads a `.json` file.
7. Rename the file descriptively (e.g., `host-metrics-dashboard.json`) and place it in this directory.

### Recommended Dashboards to Import

| Dashboard                  | Grafana ID | Purpose                          |
|----------------------------|------------|----------------------------------|
| Node Exporter Full         | 1860       | Host CPU, RAM, disk, network     |
| Django Prometheus          | 17658      | Django request/response metrics  |
| Loki & Promtail            | 13639      | Log volume & pipeline health     |

#### Importing a Community Dashboard
1. In Grafana, go to **Dashboards → Import**.
2. Enter the dashboard ID from the table above.
3. Select your Prometheus or Loki data source.
4. Click **Import**.

---

> **Tip:** After importing and customising, always re-export to this directory so your dashboards are tracked in Git.
