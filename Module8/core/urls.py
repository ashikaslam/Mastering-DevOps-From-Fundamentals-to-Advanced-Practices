"""URL configuration for Module 8 project."""

from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path("admin/", admin.site.urls),
    # Application routes
    path("", include("app.urls")),
    # Prometheus metrics endpoint — scraped by Prometheus at /metrics
    path("", include("django_prometheus.urls")),
]
