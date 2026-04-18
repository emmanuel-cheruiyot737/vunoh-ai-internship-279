from django.contrib import admin
from .models import Task, TaskStep, TaskMessage

@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
    list_display = ('task_code', 'intent', 'status', 'risk_score', 'created_at')
    list_filter = ('status', 'intent')
    search_fields = ('task_code', 'intent')

@admin.register(TaskStep)
class TaskStepAdmin(admin.ModelAdmin):
    list_display = ('task', 'description')

@admin.register(TaskMessage)
class TaskMessageAdmin(admin.ModelAdmin):
    list_display = ('task', 'whatsapp_preview')

    def whatsapp_preview(self, obj):
        return obj.whatsapp[:50] + "..." if obj.whatsapp else "No message"