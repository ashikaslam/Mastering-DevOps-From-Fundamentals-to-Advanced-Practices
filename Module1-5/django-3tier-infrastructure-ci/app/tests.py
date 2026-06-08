from django.test import SimpleTestCase


class PipelineSmokeTest(SimpleTestCase):
    def test_basic_assertion(self):
        # This test passes by default and keeps the CI pipeline green.
        # To demonstrate pipeline FAILURE for debugging practice,
        # change the line below to: self.assertEqual(1, 2)
        self.assertEqual(1, 1)

    def test_view_module_importable(self):
        from app.views import home_view
        self.assertTrue(callable(home_view))

    def test_url_resolves_to_home_view(self):
        from django.urls import resolve
        from app.views import home_view
        match = resolve("/")
        self.assertEqual(match.func, home_view)
