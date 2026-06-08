from datetime import datetime
from django.shortcuts import render


def home_view(request):
    context = {
        "project_name": "Django 3-Tier Infrastructure CI",
        "developer_status": "Active",
        "current_time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "pipeline_status": "Passing ✅",
    }
    return render(request, "index.html", context)
