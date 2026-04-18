# core/models.py
from django.db import models
import uuid

class Task(models.Model):
    task_code = models.CharField(max_length=50, unique=True)
    intent = models.CharField(max_length=255)
    status = models.CharField(max_length=50, default="Pending")
    risk_score = models.FloatField(default=0.0)
    created_at = models.DateTimeField(auto_now_add=True)
    assigned_team = models.CharField(max_length=100, default='Operations Team')
    

    def __str__(self):
        return f"{self.task_code} - {self.intent}"

class TaskStep(models.Model):
    # CHANGED: on_child_deletion -> on_delete
    task = models.ForeignKey(Task, on_delete=models.CASCADE, related_name='steps')
    description = models.TextField()

class TaskMessage(models.Model):
    # CHANGED: on_child_deletion -> on_delete
    task = models.ForeignKey(Task, on_delete=models.CASCADE, related_name='messages')
    whatsapp = models.TextField(null=True, blank=True)
    email = models.TextField(null=True, blank=True)
    sms = models.TextField(null=True, blank=True) 
    
    # Inside your Task model save method or as a default
def generate_task_code():
    return f"VUN-{uuid.uuid4().hex[:6].upper()}"
    
