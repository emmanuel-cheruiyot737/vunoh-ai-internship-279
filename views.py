from django.shortcuts import render, redirect, get_object_or_404
from .models import Task, TaskStep, TaskMessage
from .ai import process_diaspora_request  # We'll use the Gemini logic here
import uuid

def dashboard_view(request):
    """
    Renders the main dashboard. 
    This is what runs when you go to http://127.0.0.1:8000/
    """
    tasks = Task.objects.all().order_by('-created_at')
    return render(request, 'dashboard.html', {'tasks': tasks})

def create_task(request):
    """
    Handles the 'Process with AI' button.
    1. Extracts intent via Gemini
    2. Calculates Kenyan-specific risk
    3. Saves Task, Steps, and 3-Format Messages
    """
    if request.method == "POST":
        user_text = request.POST.get('user_request')
        
        if not user_text:
            return redirect('dashboard')

        # --- 1. AI EXTRACTION (Requirement #2) ---
        # Calling the function we built for the 'Gemini Brain'
        try:
            ai_data = process_diaspora_request(user_text)
        except Exception as e:
            # Fallback logic if AI fails
            ai_data = {
                "intent": "hire_service",
                "entities": {},
                "steps": ["Step 1: Contact support"],
                "messages": {"whatsapp": "Error", "email": "Error", "sms": "Error"}
            }

        # --- 2. RISK SCORING (Requirement #3) ---
        # Grounded in Kenyan Diaspora context
        risk = 0.2
        text_lower = user_text.lower()
        if 'land' in text_lower or 'title' in text_lower or 'deed' in text_lower:
            risk += 0.7  # High risk for property in Kenya
        if 'urgent' in text_lower or 'asap' in text_lower:
            risk += 0.1
        
        # --- 3. TEAM ASSIGNMENT (Requirement #7) ---
        team_map = {
            'send_money': 'Finance Team',
            'verify_document': 'Legal Team',
            'hire_service': 'Operations Team',
            'get_airport_transfer': 'Logistics Team'
        }
        assigned_team = team_map.get(ai_data.get('intent'), 'Support Team')

        # --- 4. DATA PERSISTENCE (Requirement #4 & #9) ---
        task = Task.objects.create(
            task_code=f"VUN-{uuid.uuid4().hex[:6].upper()}",
            intent=ai_data.get('intent'),
            risk_score=min(risk, 1.0),
            assigned_team=assigned_team,
            status="Pending"
        )

        # Save Steps (Requirement #5)
        for step_desc in ai_data.get('steps', []):
            TaskStep.objects.create(task=task, description=step_desc)

        # Save Three-Format Messages (Requirement #6)
        msgs = ai_data.get('messages', {})
        TaskMessage.objects.create(
            task=task,
            whatsapp=msgs.get('whatsapp', 'N/A'),
            email=msgs.get('email', 'N/A'),
            sms=msgs.get('sms', 'N/A')
        )

    return redirect('dashboard')

def update_status(request, task_id, new_status):
    """
    Updates status between Pending, In Progress, Completed (Requirement #8)
    """
    task = get_object_or_404(Task, id=task_id)
    if new_status in ['Pending', 'In Progress', 'Completed']:
        task.status = new_status
        task.save()
    return redirect('dashboard')