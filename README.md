# Vunoh Global AI Assistant - Diaspora Service (Ref: #279)

An AI-powered web application designed to help Kenyans living abroad manage essential tasks back home through a structured, reliable, and auditable platform.

## 📌 Project Overview
Kenyans in the diaspora often rely on informal, slow, and unreliable channels (like WhatsApp or word-of-mouth) to manage affairs in Kenya. This project replaces those fragmented methods with an intelligent assistant that:
- **Extracts User Intent:** Automatically identifies the service required from plain English.
- **Assesses Risk:** Calculates a risk score based on real-world Kenyan contexts.
- **Automates Communication:** Generates tailored messages for WhatsApp, Email, and SMS.
- **Tracks Progress:** Provides a dashboard to manage tasks from initiation to completion.

## 🛠 Tech Stack (Day 1 Selection)
- **Backend:** Django (Python) - Chosen for its robust ORM, security features, and alignment with Vunoh’s internal stack.
- **Frontend:** Vanilla JavaScript, HTML5, CSS3 - Built without frameworks to demonstrate core web engineering skills.
- **Database:** SQLite (Development) / PostgreSQL (Production) - Ensuring full persistence of tasks and AI outputs.
- **AI Integration:** [Gemini / OpenAI] API - Leveraged for structured JSON extraction and natural language generation.

## ⚖️ Risk Scoring Philosophy
To ensure safety and reliability, the system evaluates every request using a weighted scoring model grounded in the Kenyan context:
1. **Financial Velocity:** High-value transfers combined with "Urgent" status trigger higher risk alerts.
2. **Real Estate Integrity:** Document verification, particularly land titles, is weighted heavily due to the complexity and fraud risks in the local property market.
3. **Audit Trail:** By moving requests from informal messages to a structured database, we create a verifiable history for both the customer and the operations team.

## 📂 Project Structure
```text
vunoh-ai-internship-279/
├── core/               # Project configuration and settings
├── assistant/          # Main application logic (Intent, Risk, Task management)
├── static/             # Vanilla CSS and JavaScript
├── templates/          # HTML structures
├── requirements.txt    # Project dependencies
└── README.md           # Documentation
