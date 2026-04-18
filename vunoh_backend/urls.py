from django.contrib import admin
from django.urls import path
from core import views  # This looks into your 'core' folder for views.py

urlpatterns = [
    path('admin/', admin.site.urls),
    
    # FIX 1: This connects the main page to your dashboard_view
    path('', views.dashboard_view, name='dashboard'),
    
    # FIX 2: This connects the "Run Analysis" button to your create_task function
    path('create', views.create_task, name='create_task'),
    
    # FIX 3: This connects the "Play" and "Check" buttons in your table
    path('update-status/<int:task_id>/<str:new_status>/', views.update_status, name='update_status'),
]