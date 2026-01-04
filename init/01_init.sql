-- Create joplin user and database (idempotent)

-- Create user if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'joplin') THEN
        CREATE USER joplin WITH PASSWORD 'joplin';
        RAISE NOTICE 'User "joplin" created';
    ELSE
        RAISE NOTICE 'User "joplin" already exists - skipping';
    END IF;
END $$;

-- Create database if it doesn't exist
SELECT 'CREATE DATABASE joplin OWNER joplin'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'joplin')\gexec

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE joplin TO joplin;
