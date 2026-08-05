-- Create the users schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS users;

-- Create the device_tokens table
CREATE TABLE IF NOT EXISTS users.device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    app_id TEXT NOT NULL,
    token TEXT NOT NULL,
    platform TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Ensure unique token per app per user
    UNIQUE(user_id, app_id, token)
);

-- Enable Row Level Security
ALTER TABLE users.device_tokens ENABLE ROW LEVEL SECURITY;

-- Grant usage on schema
GRANT USAGE ON SCHEMA users TO authenticated, service_role;

-- Grant permissions on table
GRANT ALL ON users.device_tokens TO authenticated, service_role;

-- Create RLS Policies
CREATE POLICY "Users can manage their own device tokens"
ON users.device_tokens
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);
