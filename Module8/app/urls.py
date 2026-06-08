"""URL patterns for the app module."""

from django.urls import path
from .views import HealthCheckView, HomeView

urlpatterns = [
    path("", HomeView.as_view(), name="home"),
    path("health/", HealthCheckView.as_view(), name="health-check"),
]
