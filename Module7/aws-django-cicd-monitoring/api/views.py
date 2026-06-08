from django.http import JsonResponse
from django.views import View
from django.shortcuts import render


class HealthCheckView(View):
    """
    GET /api/health/
    Returns a simple JSON payload confirming the app is alive.
    Used by load balancers and uptime monitors.
    """

    def get(self, request):
        return JsonResponse({"status": "ok", "message": "Django is running."})


class HomeView(View):
    """
    GET /
    Renders the project home page with tech stack and pipeline info.
    """

    def get(self, request):
        context = {
            # ----------------------------------------------------------------
            # Tech stack badges
            # ----------------------------------------------------------------
            "stack": [
                {"icon": "🐍", "name": "Python 3.13"},
                {"icon": "🎸", "name": "Django 4.2"},
                {"icon": "🦄", "name": "Gunicorn"},
                {"icon": "🌐", "name": "Nginx"},
                {"icon": "☁️",  "name": "AWS EC2"},
                {"icon": "⚙️",  "name": "GitHub Actions"},
            ],

            # ----------------------------------------------------------------
            # CI/CD pipeline steps
            # ----------------------------------------------------------------
            "pipeline_steps": [
                {
                    "icon": "📝",
                    "title": "Code Push",
                    "desc": "Developer pushes to main branch",
                    "gradient": "from-gray-700 to-gray-800",
                },
                {
                    "icon": "🔄",
                    "title": "Trigger",
                    "desc": "GitHub Actions workflow starts automatically",
                    "gradient": "from-blue-900 to-blue-800",
                },
                {
                    "icon": "🔐",
                    "title": "SSH Connect",
                    "desc": "Secure connection to EC2 via stored secrets",
                    "gradient": "from-yellow-900 to-amber-800",
                },
                {
                    "icon": "📦",
                    "title": "Deploy",
                    "desc": "Pull, install deps, migrate, collectstatic",
                    "gradient": "from-emerald-900 to-green-800",
                },
                {
                    "icon": "🚀",
                    "title": "Restart",
                    "desc": "Gunicorn reloads with zero downtime",
                    "gradient": "from-orange-900 to-red-800",
                },
            ],

            # ----------------------------------------------------------------
            # Infrastructure cards
            # ----------------------------------------------------------------
            "infra_cards": [
                {
                    "icon": "🌐",
                    "title": "Web Layer",
                    "desc": "Nginx acts as a reverse proxy, serving static files directly and forwarding dynamic requests to Gunicorn over a Unix socket.",
                    "accent": "blue",
                    "tags": ["Nginx", "Gunicorn", "Unix Socket", "Static Files"],
                },
                {
                    "icon": "🗄️",
                    "title": "Data Layer",
                    "desc": "PostgreSQL database with Django ORM. Migrations are applied automatically on every deployment via the CI/CD pipeline.",
                    "accent": "emerald",
                    "tags": ["PostgreSQL", "Django ORM", "Auto Migrate", "psycopg2"],
                },
                {
                    "icon": "🔒",
                    "title": "Security Layer",
                    "desc": "Environment variables for all secrets, security middleware enabled in production, CSRF protection, and XSS filtering.",
                    "accent": "purple",
                    "tags": ["python-dotenv", "CSRF", "XSS Filter", "Secure Cookies"],
                },
            ],

            # ----------------------------------------------------------------
            # Monitoring metrics (illustrative values)
            # ----------------------------------------------------------------
            "metrics": [
                {"icon": "🖥️", "value": "< 5%",  "label": "Avg CPU Usage"},
                {"icon": "💾", "value": "~512MB", "label": "Memory Footprint"},
                {"icon": "⚡", "value": "< 50ms", "label": "Avg Response Time"},
                {"icon": "📈", "value": "15d",    "label": "Metrics Retention"},
            ],

            # ----------------------------------------------------------------
            # Monitoring tools
            # ----------------------------------------------------------------
            "monitoring_tools": [
                {"icon": "🔥", "name": "Prometheus",    "desc": "Metrics scraping & alerting rules", "port": "9090", "status": "Active"},
                {"icon": "📊", "name": "Grafana",        "desc": "Dashboards & visualisation",        "port": "3000", "status": "Active"},
                {"icon": "📡", "name": "Node Exporter",  "desc": "System-level metrics (CPU/RAM/Disk)","port": "9100", "status": "Active"},
                {"icon": "🔔", "name": "Alertmanager",   "desc": "SMTP email alert routing",           "port": "9093", "status": "Active"},
            ],

            # ----------------------------------------------------------------
            # API endpoints table
            # ----------------------------------------------------------------
            "endpoints": [
                {"method": "GET",  "url": "/",            "desc": "Project home page (this page)"},
                {"method": "GET",  "url": "/api/health/", "desc": "JSON health check — returns {status: ok}"},
                {"method": "GET",  "url": "/admin/",      "desc": "Django admin panel"},
            ],
        }
        return render(request, "home.html", context)
