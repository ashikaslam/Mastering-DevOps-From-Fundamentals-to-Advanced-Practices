"""Basic smoke tests for the app module."""

from django.test import TestCase, Client
from django.urls import reverse


class HealthCheckTestCase(TestCase):
    def setUp(self):
        self.client = Client()

    def test_health_check_returns_200(self):
        response = self.client.get(reverse("health-check"))
        self.assertEqual(response.status_code, 200)

    def test_health_check_returns_ok(self):
        response = self.client.get(reverse("health-check"))
        data = response.json()
        self.assertEqual(data["status"], "ok")

    def test_home_returns_200(self):
        response = self.client.get(reverse("home"))
        self.assertEqual(response.status_code, 200)

    def test_home_returns_message(self):
        response = self.client.get(reverse("home"))
        data = response.json()
        self.assertIn("message", data)
