import google.generativeai as genai
import json

# Get your key at: https://aistudio.google.com/app/apikey
genai.configure(api_key="YOUR_GEMINI_API_KEY")

def process_diaspora_request(user_input):
    model = genai.GenerativeModel('gemini-1.5-flash')
    
    system_prompt = """
    You are an AI for Vunoh Global, helping Kenyans abroad. 
    Analyze the user's request and return a JSON object.
    
    Rules:
    1. intent: must be one of [send_money, hire_service, verify_document, get_airport_transfer, check_status]
    2. entities: extract amount, recipient, location, or service type.
    3. steps: provide 3-4 logical steps to fulfill this in Kenya.
    4. messages: provide three versions:
       - whatsapp: friendly, uses emojis, mentions the task code.
       - email: formal, structured, professional.
       - sms: concise, under 160 chars.
    """

    response = model.generate_content(
        f"{system_prompt}\n\nUser request: {user_input}",
        generation_config={"response_mime_type": "application/json"}
    )
    return json.loads(response.text)