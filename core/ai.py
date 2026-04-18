import os
import json
import re
from pathlib import Path
import google.generativeai as genai
from dotenv import load_dotenv

# --- 1. SETUP & SECURITY (The "Top 1%" Way) ---
# This logic finds your .env file even if Django is started from different folders.
# It looks one level up from this file (core/) to find the project root.
BASE_DIR = Path(__file__).resolve().parent.parent
ENV_PATH = BASE_DIR / '.env'

# Specifically load the file from that absolute path
load_dotenv(dotenv_path=ENV_PATH)

# Retrieve the key from environment variables
API_KEY = os.getenv("GEMINI_API_KEY")

if not API_KEY:
    # This helps you debug in the terminal if the file is missing
    print(f"\n[CRITICAL ERROR] AI Engine could not find .env file at: {ENV_PATH}")
    raise ValueError("GEMINI_API_KEY not found. Ensure it is set in your .env file.")

genai.configure(api_key=API_KEY)

def process_diaspora_request(user_input):
    """
    Vunoh Global AI Logic Engine.
    Requirement #2: Intent & Entity Extraction.
    Requirement #3: Risk Scoring (Kenyan Context).
    Requirement #5: Step Generation.
    Requirement #6: Three-Format Messaging.
    """
    
    # Using gemini-1.5-flash for high-speed processing
    model = genai.GenerativeModel('gemini-1.5-flash')

    system_instruction = """
    You are the Intelligence Engine for Vunoh Global, helping the Kenyan Diaspora manage tasks back home.
    Analyze the user request and return ONLY a strictly structured JSON object.

    INTENTS: [send_money, get_airport_transfer, hire_service, verify_document, check_status]
    
    RISK GUIDELINES:
    - 0.8 to 1.0: Land titles (Title deeds/Shambas), large money transfers, urgent high-value tasks.
    - 0.4 to 0.7: Document verification (ID/Certificates), airport logistics.
    - 0.1 to 0.3: General errands, cleaning, routine pickups.

    JSON STRUCTURE:
    {
      "intent": "string (must be one of the five listed)",
      "entities": {
        "amount": "string or null",
        "location": "string or null",
        "recipient": "string or null",
        "type": "string (e.g., land, lawyer, cleaner)"
      },
      "risk_score": float (0.0 to 1.0),
      "steps": ["Step 1", "Step 2", "Step 3"],
      "messages": {
        "whatsapp": "Informal, uses emojis (e.g., 🇰🇪, ✅), conversational.",
        "email": "Formal and professional, structured with task code placeholder [TASK_CODE].",
        "sms": "Strictly under 160 characters, concise."
      }
    }
    
    Return ONLY valid JSON. No conversational text or markdown blocks.
    """

    full_query = f"{system_instruction}\n\nUSER REQUEST: '{user_input}'"

    try:
        response = model.generate_content(full_query)
        raw_text = response.text
        
        # Cleanup: AI often wraps JSON in ```json blocks; this removes them.
        clean_json = re.sub(r'```json|```', '', raw_text).strip()
        
        # Parse into a Python dictionary
        ai_output = json.loads(clean_json)
        return ai_output

    except Exception as e:
        print(f"AI ENGINE ERROR: {e}")
        # REQUIREMENT #2 FALLBACK: Ensures the application doesn't crash if the API fails
        return {
            "intent": "hire_service",
            "entities": {"type": "manual_review"},
            "risk_score": 0.5,
            "steps": ["Task queued for manual review by Vunoh Ops"],
            "messages": {
                "whatsapp": "We've received your request! 🇰🇪 Our team is reviewing it now.",
                "email": "Your request has been received and is currently under manual review by our team.",
                "sms": "Vunoh Global: Request received and under review."
            }
        }

# --- STANDALONE TEST BLOCK ---
if __name__ == "__main__":
    test_query = "I need to verify my title deed for my plot in Syokimau urgently."
    print(f"Testing AI Engine with: '{test_query}'\n")
    
    result = process_diaspora_request(test_query)
    
    import pprint
    pprint.pprint(result)