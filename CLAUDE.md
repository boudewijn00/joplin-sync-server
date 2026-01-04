# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository contains a Docker Compose setup for running a Joplin sync server with PostgreSQL 17 as the database backend. The setup is designed to run the official Joplin server image (`joplin/server:latest`) with a PostgreSQL database for synchronization across Joplin clients.

## Architecture

- **Database Service (`db`)**: PostgreSQL 17 container with persistent data storage
  - Data persisted in `./data/postgres`
  - Initialization scripts in `./init` directory run on first startup
  - Exposed on port 5432

- **Application Service (`app`)**: Joplin sync server
  - Runs the official `joplin/server:latest` image
  - Exposed on port 22300
  - Configured to use PostgreSQL as the database client (`DB_CLIENT=pg`)
  - Depends on the `db` service

- **Networks**:
  - `app-network`: Internal network connecting the database and application
  - `shared-network`: External network for the application (e.g., for reverse proxy access)

- **Profiles**:
  - `full`: Runs only the database service
  - `server`: Runs both database and Joplin server

## Common Commands

### Starting Services

```bash
# Start both database and Joplin server
docker compose --profile server up -d

# Start only the database
docker compose --profile full up -d

# Start with logs visible
docker compose --profile server up
```

### Stopping Services

```bash
# Stop all services
docker compose down

# Stop and remove volumes (WARNING: deletes data)
docker compose down -v
```

### Viewing Logs

```bash
# View logs for all services
docker compose logs -f

# View logs for specific service
docker compose logs -f app
docker compose logs -f db
```

### Database Access

```bash
# Connect to PostgreSQL
docker compose exec db psql -U joplin -d joplin

# Run SQL scripts
docker compose exec -T db psql -U joplin -d joplin < script.sql
```

## Configuration

All configuration is managed through environment variables in `.env`:

- `POSTGRES_PASSWORD`: Database password
- `POSTGRES_USER`: Database username
- `POSTGRES_DATABASE`: Database name
- `POSTGRES_PORT`: Database port (5432)
- `APP_BASE_URL`: Public URL where Joplin server is accessible

The `.env` file is gitignored for security. Default values are provided in the example above.

## Database Initialization

SQL scripts placed in the `./init` directory are automatically executed when the PostgreSQL container is first created. The existing `init.sql` creates the Joplin user and database with appropriate privileges.

### Change Notification Trigger

The setup includes a PostgreSQL trigger function (`notify_items_changes()`) that sends real-time notifications via PostgreSQL's LISTEN/NOTIFY mechanism whenever items are inserted, updated, or deleted in the Joplin database.

**How it works:**
1. The function is automatically created during database initialization (`init/02_notify_trigger.sql`)
2. The trigger script (`init/03_apply_trigger.sql`) runs during init but only creates the trigger if the `items` table exists
3. After Joplin starts and creates its tables, manually apply the trigger with:
   ```bash
   docker compose exec -T db psql -U joplin -d joplin < init/03_apply_trigger.sql
   ```
4. The trigger broadcasts JSON payloads to the `items_changes` channel containing:
   - Operation type (INSERT, UPDATE, DELETE)
   - Item ID
   - Full row data (old and new values for updates)

**Listening for notifications:**
```bash
# In a psql session
docker compose exec db psql -U joplin -d joplin
LISTEN items_changes;
-- Now any changes to items will appear as notifications
```

**Use cases:**
- Real-time synchronization monitoring
- Audit logging
- Cache invalidation
- External integrations that need to react to data changes

## Data Persistence

PostgreSQL data is persisted in `./data/postgres`. This directory is gitignored to prevent committing database files. The data survives container restarts but will be lost if you run `docker compose down -v`.
