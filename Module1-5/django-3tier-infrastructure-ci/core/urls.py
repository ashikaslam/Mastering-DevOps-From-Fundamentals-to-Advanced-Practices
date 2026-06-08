from django.urls import path
from app.views import home_view

urlpatterns = [
    path("", home_view, name="home"),
]

#  hello   ddddd