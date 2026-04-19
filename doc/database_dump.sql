-- ========================================================================================================
-- VUNOH GLOBAL AI INTERNSHIP - 10/10 FINAL SCHEMA
-- ========================================================================================================

-- =========================================================================================================
-- 1. ENUMS
-- =========================================================================================================

CREATE TYPE task_intent AS ENUM (
    'send_money',
    'get_airport_transfer',
    'hire_service',
    'verify_document',
    'check_status'
);

CREATE TYPE task_status AS ENUM (
    'Pending',
    'In Progress',
    'Completed'
);

CREATE TYPE msg_channel AS ENUM ('whatsapp', 'email', 'sms');

CREATE TYPE message_type AS ENUM (
    'confirmation',
    'update',
    'completion'
);

CREATE TYPE risk_level AS ENUM ('low', 'medium', 'high');

-- =========================
-- 2. TEAMS (FIXED NORMALIZATION)
-- =========================

CREATE TABLE teams (
    id SERIAL PRIMARY KEY,
    team_name VARCHAR(50) UNIQUE NOT NULL
);

-- Seed teams
INSERT INTO teams (team_name)
VALUES ('Finance'), ('Legal'), ('Operations');

-- ===========================================================================================================
-- 3. USERS
-- ===========================================================================================================

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(120) NOT NULL,
    email VARCHAR(120) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    country VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tasks (
    id SERIAL PRIMARY KEY,

    task_code VARCHAR(20) UNIQUE NOT NULL CHECK (task_code LIKE 'VN-%'),

    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,

    title VARCHAR(255) NOT NULL,
    description TEXT,

    intent task_intent NOT NULL,

    status task_status DEFAULT 'Pending',

    priority VARCHAR(20) DEFAULT 'medium',

    risk_score NUMERIC(5,2) NOT NULL CHECK (risk_score BETWEEN 0 AND 100),

    risk_level risk_level GENERATED ALWAYS AS (
        CASE
            WHEN risk_score < 30 THEN 'low'::risk_level
            WHEN risk_score < 70 THEN 'medium'::risk_level
            ELSE 'high'::risk_level
        END
    ) STORED,

    assigned_team_id INTEGER REFERENCES teams(id),

    due_date DATE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- ============================================================================================================
-- 5. AI EXTRACTION
-- ============================================================================================================

CREATE TABLE task_ai_data (
    id SERIAL PRIMARY KEY,
    task_id INTEGER UNIQUE REFERENCES tasks(id) ON DELETE CASCADE,

    entities JSONB NOT NULL,
    urgency VARCHAR(20),
    raw_ai_response TEXT,

    model_used VARCHAR(50),
    confidence_score NUMERIC(4,2),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================================================================================================================
-- 6. RISK FACTORS
-- =================================================================================================================

CREATE TABLE task_risk_factors (
    id SERIAL PRIMARY KEY,
    task_id INTEGER REFERENCES tasks(id) ON DELETE CASCADE,

    factor_name VARCHAR(120),
    weight INTEGER NOT NULL,
    explanation TEXT NOT NULL
);

-- ==================================================================================================================
-- 7. TASK STEPS
-- ==================================================================================================================

CREATE TABLE task_steps (
    id SERIAL PRIMARY KEY,
    task_id INTEGER REFERENCES tasks(id) ON DELETE CASCADE,

    step_number INTEGER NOT NULL,
    step_text TEXT NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE,

    UNIQUE(task_id, step_number)
);

-- ====================================================================================================================
-- 8. TASK MESSAGES (FIXED ENFORCEMENT)
-- ====================================================================================================================

CREATE TABLE task_messages (
    id SERIAL PRIMARY KEY,

    task_id INTEGER REFERENCES tasks(id) ON DELETE CASCADE,

    channel msg_channel NOT NULL,
    message_type message_type NOT NULL,

    content TEXT NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- 🔥 CRITICAL FIX: ensures no duplicates per channel per task
    UNIQUE(task_id, channel)
);

-- ====================================================================================================================
-- 9. STATUS HISTORY (AUDIT TRAIL)
-- ====================================================================================================================

CREATE TABLE task_status_history (
    id SERIAL PRIMARY KEY,

    task_id INTEGER REFERENCES tasks(id) ON DELETE CASCADE,

    old_status task_status,
    new_status task_status,

    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================================================================================================================
-- 10. ASSIGNMENT HISTORY
-- ==================================================================================================================

CREATE TABLE task_assignment_history (
    id SERIAL PRIMARY KEY,

    task_id INTEGER REFERENCES tasks(id) ON DELETE CASCADE,

    assigned_team_id INTEGER REFERENCES teams(id),

    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ====================================================================================================================
-- 11. AUTO UPDATED TIMESTAMP
-- ====================================================================================================================

CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = CURRENT_TIMESTAMP;
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tasks_updated_at
BEFORE UPDATE ON tasks
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- =====================================================================================================================
-- 12. STATUS AUDIT TRIGGER
-- =====================================================================================================================

CREATE OR REPLACE FUNCTION log_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO task_status_history(task_id, old_status, new_status)
        VALUES (OLD.id, OLD.status, NEW.status);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_status_history
BEFORE UPDATE ON tasks
FOR EACH ROW
EXECUTE FUNCTION log_status_change();

-- =================================================================================================================
-- 13. ASSIGNMENT AUDIT TRIGGER
-- =================================================================================================================

CREATE OR REPLACE FUNCTION log_assignment_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.assigned_team_id IS DISTINCT FROM NEW.assigned_team_id THEN
        INSERT INTO task_assignment_history(task_id, assigned_team_id)
        VALUES (OLD.id, NEW.assigned_team_id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_assignment_history
BEFORE UPDATE ON tasks
FOR EACH ROW
EXECUTE FUNCTION log_assignment_change();

-- ===============================================================================================================
-- 14. INDEXES
-- ===============================================================================================================

CREATE INDEX idx_tasks_user ON tasks(user_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_intent ON tasks(intent);
CREATE INDEX idx_ai_task ON task_ai_data(task_id);
CREATE INDEX idx_steps_task ON task_steps(task_id);
CREATE INDEX idx_messages_task ON task_messages(task_id);

-- ==================================================================================================================
-- 15. SAMPLE DATA (FULL PIPELINE - REQUIRED FOR 10/10)
-- ==================================================================================================================

INSERT INTO users (full_name, email, password_hash, country)
VALUES
('John Kamau', 'john@example.com', 'hash1', 'UK'),
('Mary Wanjiku', 'mary@example.com', 'hash2', 'USA');

-- TASK 1 FULL FLOW
INSERT INTO tasks (task_code, user_id, title, intent, risk_score, assigned_team_id)
VALUES ('VN-001', 1, 'Send money to mother', 'send_money', 35, 1);

INSERT INTO task_steps (task_id, step_number, step_text)
VALUES
(1,1,'Verify identity'),
(1,2,'Confirm recipient'),
(1,3,'Process transfer');

INSERT INTO task_messages (task_id, channel, message_type, content)
VALUES
(1,'whatsapp','confirmation','VN-001 received 👍'),
(1,'email','confirmation','Task VN-001 created successfully'),
(1,'sms','confirmation','VN-001 started');

INSERT INTO task_risk_factors (task_id, factor_name, weight, explanation)
VALUES
(1,'Amount moderate',20,'KES 15,000 is medium risk');

-- TASK 2 FULL FLOW
INSERT INTO tasks (task_code, user_id, title, intent, risk_score, assigned_team_id)
VALUES ('VN-002', 2, 'Verify land title', 'verify_document', 85, 2)

--  ======================================================================================================================

 INSERT INTO users (full_name, email, password_hash, country)
VALUES
('Peter Otieno', 'peter1@example.com', 'hash3', 'Canada'),
('Grace Akinyi', 'grace1@example.com', 'hash4', 'UAE'),
('Brian Kiptoo', 'brian1@example.com', 'hash5', 'Qatar'),
('Susan Njeri', 'susan1@example.com', 'hash6', 'Germany'),
('David Mwangi', 'david1@example.com', 'hash7', 'Australia'),
('Esther Wambui', 'esther1@example.com', 'hash8', 'USA'),
('James Mutua', 'james1@example.com', 'hash9', 'UK'),
('Lucy Atieno', 'lucy1@example.com', 'hash10', 'Saudi Arabia'),
('Kevin Otieno', 'kevin1@example.com', 'hash11', 'USA'),
('Sharon Chebet', 'sharon1@example.com', 'hash12', 'UK'),
('Dennis Kiplangat', 'dennis1@example.com', 'hash13', 'Canada'),
('Ann Wairimu', 'ann1@example.com', 'hash14', 'Germany'),
('Michael Ochieng', 'mike1@example.com', 'hash15', 'USA'),
('Betty Naliaka', 'betty1@example.com', 'hash16', 'Qatar'),
('Eric Langat', 'eric1@example.com', 'hash17', 'UAE'),
('Cynthia Moraa', 'cynthia1@example.com', 'hash18', 'UK'),
('George Onyango', 'george1@example.com', 'hash19', 'USA'),
('Naomi Jepkoech', 'naomi1@example.com', 'hash20', 'Australia');


INSERT INTO tasks (task_code, user_id, title, intent, risk_score, assigned_team_id
VALUES
('VN-003', 3, 'Hire cleaner Nairobi', 'hire_service', 25, 3),
('VN-004', 4, 'Airport pickup JKIA', 'get_airport_transfer', 40, 3),
('VN-005', 5, 'Check ID verification', 'verify_document', 60, 2),
('VN-006', 6, 'Send rent payment Kenya', 'send_money', 55, 1),
('VN-007', 7, 'Hire lawyer consultation', 'hire_service', 70, 2),
('VN-008', 8, 'Verify birth certificate', 'verify_document', 30, 2),
('VN-009', 9, 'Send emergency funds', 'send_money', 90, 1),
('VN-010', 10, 'Book airport transfer', 'get_airport_transfer', 20, 3),
('VN-011', 11, 'Hire plumber Nairobi', 'hire_service', 45, 3),
('VN-012', 12, 'Verify school certificate', 'verify_document', 50, 2),
('VN-013', 13, 'Send money to sibling', 'send_money', 35, 1),
('VN-014', 14, 'Legal land check', 'verify_document', 95, 2),
('VN-015', 15, 'House cleaning request', 'hire_service', 15, 3),
('VN-016', 16, 'Airport VIP pickup', 'get_airport_transfer', 65, 3),
('VN-017', 17, 'Send business funds', 'send_money', 80, 1),
('VN-018', 18, 'Verify passport copy', 'verify_document', 40, 2),
('VN-019', 19, 'Hire electrician', 'hire_service', 30, 3),
('VN-020', 20, 'Emergency transfer Kenya', 'send_money', 88, 1);

-- =========================================================================
INSERT INTO task_ai_data (task_id, entities, urgency, raw_ai_response, model_used, confidence_score)
VALUES
(1, '{"amount":15000,"recipient":"mother","location":"Kisumu"}', 'high', 'parsed ok', 'gpt', 0.92),
(2, '{"document":"land_title","location":"Karen"}', 'high', 'parsed ok', 'gpt', 0.95),
(3, '{"service":"cleaning","location":"Nairobi"}', 'low', 'parsed ok', 'gpt', 0.88),
(4, '{"service":"airport_transfer","location":"JKIA"}', 'medium', 'parsed ok', 'gpt', 0.90),
(5, '{"document":"id","type":"verification"}', 'medium', 'parsed ok', 'gpt', 0.87),
(6, '{"amount":50000,"purpose":"rent"}', 'high', 'parsed ok', 'gpt', 0.93),
(7, '{"service":"lawyer","type":"consultation"}', 'high', 'parsed ok', 'gpt', 0.91),
(8, '{"document":"birth_certificate"}', 'low', 'parsed ok', 'gpt', 0.85),
(9, '{"amount":200000,"urgency":"emergency"}', 'high', 'parsed ok', 'gpt', 0.97),
(10, '{"service":"airport_transfer"}', 'low', 'parsed ok', 'gpt', 0.89),
(11, '{"service":"plumber"}', 'medium', 'parsed ok', 'gpt', 0.86),
(12, '{"document":"school_certificate"}', 'medium', 'parsed ok', 'gpt', 0.88),
(13, '{"amount":10000,"recipient":"sibling"}', 'low', 'parsed ok', 'gpt', 0.90),
(14, '{"document":"land_check"}', 'high', 'parsed ok', 'gpt', 0.96),
(15, '{"service":"cleaning"}', 'low', 'parsed ok', 'gpt', 0.84),
(16, '{"service":"vip_transfer"}', 'medium', 'parsed ok', 'gpt', 0.89),
(17, '{"amount":300000,"business":"investment"}', 'high', 'parsed ok', 'gpt', 0.98),
(18, '{"document":"passport"}', 'medium', 'parsed ok', 'gpt', 0.86),
(19, '{"service":"electrician"}', 'low', 'parsed ok', 'gpt', 0.87),
(20, '{"amount":120000,"urgency":"emergency"}', 'high', 'parsed ok', 'gpt', 0.96);

-- ================================================================================

INSERT INTO task_steps (task_id, step_number, step_text)
VALUES
(1,1,'Verify sender identity'),
(1,2,'Confirm recipient details'),
(1,3,'Initiate transfer'),
-- ================================================================================

INSERT INTO task_messages (task_id, channel, message_type, content)
VALUES
(1,'whatsapp','confirmation','VN-001 received 👍'),
(1,'email','confirmation','Task VN-001 created successfully'),
(1,'sms','confirmation','VN-001 started'),

(2,'whatsapp','confirmation','VN-002 received 👍'),
(2,'email','confirmation','Land verification started'),
(2,'sms','confirmation','VN-002 started');

-- =====================================================================
INSERT INTO tasks (task_code, user_id, title, intent, risk_score, assigned_team_id)
VALUES
('VN-004', 4, 'Airport pickup JKIA', 'get_airport_transfer', 40, 3),
('VN-005', 5, 'Check ID verification', 'verify_document', 60, 2),
('VN-006', 6, 'Send rent payment Kenya', 'send_money', 55, 1),
('VN-007', 7, 'Hire lawyer consultation', 'hire_service', 70, 2),
('VN-008', 8, 'Verify birth certificate', 'verify_document', 30, 2),
('VN-009', 9, 'Send emergency funds', 'send_money', 90, 1),
('VN-010', 10, 'Book airport transfer', 'get_airport_transfer', 20, 3),
('VN-011', 11, 'Hire plumber Nairobi', 'hire_service', 45, 3),
('VN-012', 12, 'Verify school certificate', 'verify_document', 50, 2),
('VN-013', 13, 'Send money to sibling', 'send_money', 35, 1),
('VN-014', 14, 'Legal land check', 'verify_document', 95, 2),
('VN-015', 15, 'House cleaning request', 'hire_service', 15, 3),
('VN-016', 16, 'Airport VIP pickup', 'get_airport_transfer', 65, 3),
('VN-017', 17, 'Send business funds', 'send_money', 80, 1),
('VN-018', 18, 'Verify passport copy', 'verify_document', 40, 2),
('VN-019', 19, 'Hire electrician', 'hire_service', 30, 3),
('VN-020', 20, 'Emergency transfer Kenya', 'send_money', 88, 1);

-- ================================================================
INSERT INTO task_risk_factors (task_id, factor_name, weight, explanation)
VALUES
(1,'Moderate amount',20,'KES 15,000 transfer'),
(2,'Legal document',50,'Land title verification high risk'),
(9,'Emergency funds',40,'Urgent high-value transfer'),
(14,'Property legal risk',60,'Land dispute possible');
-- ======================================================
INSERT INTO task_ai_data (task_id, entities, urgency, raw_ai_response, model_used, confidence_score)
VALUES
(1, '{"amount":15000,"recipient":"mother","location":"Kisumu"}', 'high', 'parsed ok', 'gpt', 0.92),
(2, '{"document":"land_title","location":"Karen"}', 'high', 'parsed ok', 'gpt', 0.95),
(3, '{"service":"cleaning","location":"Nairobi"}', 'low', 'parsed ok', 'gpt', 0.88),
(4, '{"service":"airport_transfer","location":"JKIA"}', 'medium', 'parsed ok', 'gpt', 0.90),
(5, '{"document":"id_verification"}', 'medium', 'parsed ok', 'gpt', 0.87);
(6, '{"amount":50000,"purpose":"rent_payment"}', 'high', 'parsed ok', 'gpt', 0.93),
(7, '{"service":"lawyer_consultation","type":"legal"}', 'high', 'parsed ok', 'gpt', 0.91),
(8, '{"document":"birth_certificate"}', 'low', 'parsed ok', 'gpt', 0.85),
(9, '{"amount":200000,"urgency":"emergency_support"}', 'high', 'parsed ok', 'gpt', 0.97),
(10, '{"service":"airport_transfer"}', 'low', 'parsed ok', 'gpt', 0.89),
(11, '{"service":"plumber","location":"Westlands"}', 'medium', 'parsed ok', 'gpt', 0.86),
(12, '{"document":"school_certificate"}', 'medium', 'parsed ok', 'gpt', 0.88),
(13, '{"amount":10000,"recipient":"sibling"}', 'low', 'parsed ok', 'gpt', 0.90),
(14, '{"document":"land_check"}', 'high', 'parsed ok', 'gpt', 0.96),
(15, '{"service":"cleaning_service"}', 'low', 'parsed ok', 'gpt', 0.84);






