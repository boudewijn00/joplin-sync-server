#!/bin/bash
set -e

# This script grants privileges to the Joplin database user
# Note: The PostgreSQL Docker image automatically creates the user and database
# from POSTGRES_USER, POSTGRES_PASSWORD, and POSTGRES_DB environment variables
# before running init scripts, so we only need to grant additional privileges

echo "Setting up database permissions for user: $POSTGRES_USER"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Grant all privileges on the database
    GRANT ALL PRIVILEGES ON DATABASE "$POSTGRES_DB" TO "$POSTGRES_USER";

    -- Grant schema privileges (for tables created later by Joplin)
    GRANT ALL ON SCHEMA public TO "$POSTGRES_USER";

    \echo 'Database setup complete'
    \echo 'User: $POSTGRES_USER'
    \echo 'Database: $POSTGRES_DB'
EOSQL

echo "✓ Database initialization complete"
