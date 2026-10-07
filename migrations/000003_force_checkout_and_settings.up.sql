ALTER TABLE attendance_sessions
ADD COLUMN IF NOT EXISTS checkout_reason VARCHAR(50) NOT NULL DEFAULT 'MANUAL';

ALTER TABLE attendance_sessions
ADD COLUMN IF NOT EXISTS initial_out_of_radius_at TIMESTAMPTZ;

CREATE TABLE IF NOT EXISTS system_settings (
    id SERIAL PRIMARY KEY,
    retry_interval_minutes INT NOT NULL DEFAULT 2,
    max_retries INT NOT NULL DEFAULT 1,
    telegram_alerts_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    force_checkout_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    telegram_bot_token VARCHAR(255) NULL,
    telegram_chat_id VARCHAR(100) NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO system_settings (id, retry_interval_minutes, max_retries, telegram_alerts_enabled, force_checkout_enabled)
VALUES (1, 2, 1, TRUE, TRUE)
ON CONFLICT (id) DO NOTHING;
