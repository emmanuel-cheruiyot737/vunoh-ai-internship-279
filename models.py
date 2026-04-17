# core/models.py
from django.db import models

class Task(models.Model):
    task_code = models.CharField(max_length=50, unique=True)
    intent = models.CharField(max_length=255)
    status = models.CharField(max_length=50, default="Pending")
    risk_score = models.FloatField(default=0.0)
    created_at = models.DateTimeField(auto_now_add=True)

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