"""Application views."""

import logging
from django.http import JsonResponse
from django.views import View

logger = logging.getLogger(__name__)


class HealthCheckView(View):
    """
    GET /health/
    Returns HTTP 200 with a JSON payload.
    Used by the CI/CD pipeline verification step and load balancer health checks.
    """

    def get(self, request, *args, **kwargs):
        logger.info("Health check endpoint called")
        return JsonResponse({"status": "ok", "service": "module8-app"})


class HomeView(View):
    """
    GET /
    Simple landing page confirming the application is live.
    """

    def get(self, request, *args, **kwargs):
        logger.info("Home endpoint called", extra={"path": request.path})
        return JsonResponse(
            {
                "message": "Module 8 — Automated Deployment & Infrastructure Monitoring",
                "version": "1.0.0",
            }
        )
