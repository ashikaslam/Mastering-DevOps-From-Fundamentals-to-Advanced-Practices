from django.db import models


class HealthCheck(models.Model):
    """Simple model to verify DB connectivity."""
    status = models.CharField(max_length=50, default="ok")
    checked_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"HealthCheck [{self.status}] @ {self.checked_at}"
