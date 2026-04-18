from django.shortcuts import render, redirect, get_object_or_404
from .models import Task, TaskStep, TaskMessage
from .ai import process_diaspora_request 
import uuid

# --- Helper Function (Requirement #3) ---
def calculate_kenyan_risk(user_text, base_ai_risk=0.2):
    """
    Refines the risk score based on specific Kenyan Diaspora pain points.
    """
    risk = base_ai_risk
    text_lower = user_text.lower()
    
    # High-stakes property keywords
    if any(k in text_lower for k in ['land', 'title', 'deed', 'plot', 'shamba']):
        risk += 0.6 
    
    # Urgency multiplier
    if any(k in text_lower for k in ['urgent', 'asap', 'immediately', 'haraka']):
        risk += 0.1
        
    return min(risk, 1.0)

def dashboard_view(request):
    tasks = Task.objects.all().order_by('-created_at')
    return render(request, 'dashboard.html', {'tasks': tasks})

def create_task(request):
    if request.method == "POST":
        user_text = request.POST.get('user_request', '').strip()
        
        if not user_text:
            return redirect('dashboard')

        try:
            # 1. AI EXTRACTION
            ai_data = process_diaspora_request(user_text)
            
            # 2. ENHANCED RISK SCORING
            # We combine the AI's intuition with our hardcoded Kenyan rules
            final_risk = calculate_kenyan_risk(user_text, ai_data.get('risk_score', 0.2))

            # 3. TEAM ASSIGNMENT (Requirement #7)
            team_map = {
                'send_money': 'Finance Team',
                'verify_document': 'Legal Team',
                'hire_service': 'Operations Team',
                'get_airport_transfer': 'Logistics Team'
            }
            intent = ai_data.get('intent', 'hire_service')
            assigned_team = team_map.get(intent, 'Support Team')

            # 4. DATA PERSISTENCE (Requirement #9)
            task = Task.objects.create(
                task_code=f"VUN-{uuid.uuid4().hex[:6].upper()}",
                intent=intent,
                risk_score=final_risk,
                assigned_team=assigned_team,
                # Ensure your Task model has an 'entities' JSONField!
                entities=ai_data.get('entities', {}), 
                status="Pending"
            )

            # Save Steps (Requirement #5)
            for step_desc in ai_data.get('steps', []):
                TaskStep.objects.create(task=task, description=step_desc)

            # Save Messages (Requirement #6)
            msgs = ai_data.get('messages', {})
            TaskMessage.objects.create(
                task=task,
                whatsapp=msgs.get('whatsapp', 'N/A'),
                email=msgs.get('email', 'N/A'),
                sms=msgs.get('sms', 'N/A')
            )

        except Exception as e:
            # Senior Move: Log the actual error for debugging
            print(f"AI Processing Error: {e}")
            # Fallback or error message could go here

    return redirect('dashboard')

def update_status(request, task_id, new_status):
    task = get_object_or_404(Task, id=task_id)
    if new_status in ['Pending', 'In Progress', 'Completed']:
        task.status = new_status
        task.save()
    return redirect('dashboard')