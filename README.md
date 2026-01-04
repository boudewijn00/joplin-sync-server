# Joplin Sync Server with PostgreSQL

Docker Compose setup for running a Joplin sync server with PostgreSQL 17 as the database backend.

## Quick Start

### 1. Start the Services

```bash
# Start both database and Joplin server
docker compose --profile server up -d

# View logs to confirm startup
docker compose logs -f
```

Wait for Joplin to initialize (watch the logs until you see the server is ready, usually ~30 seconds).

### 2. Apply the Change Notification Trigger

After Joplin has started and created its database tables, apply the notification trigger:

```bash
docker compose exec -T db psql -U joplin -d joplin < init/03_apply_trigger.sql
```

**Expected output:**
```
NOTICE:  Trigger "items_changes_trigger" created successfully on "items" table
NOTICE:  Trigger details:
```

If the items table doesn't exist yet, you'll see:
```
NOTICE:  Items table does not exist yet - skipping trigger creation
NOTICE:  Run this script again after Joplin server has initialized
```

### 3. Verify the Trigger

Check that the trigger is active:

```bash
docker compose exec db psql -U joplin -d joplin -c "
  SELECT trigger_name, event_manipulation, event_object_table
  FROM information_schema.triggers
  WHERE trigger_name = 'items_changes_trigger';
"
```

## Change Notifications

The setup includes a PostgreSQL trigger that broadcasts real-time notifications whenever items are inserted, updated, or deleted.

### Listen for Changes

Open a PostgreSQL session and listen for notifications:

```bash
docker compose exec db psql -U joplin -d joplin
```

In the psql session:
```sql
LISTEN items_changes;
-- You'll now see notifications as items change
-- Press Ctrl+C to stop listening
```

### Notification Format

Notifications are sent as JSON payloads on the `items_changes` channel:

```json
{
  "operation": "INSERT|UPDATE|DELETE",
  "id": "item_id",
  "data": { /* full row data */ }
}
```

## Common Commands

### Start Services

```bash
# Start both database and Joplin server
docker compose --profile server up -d

# Start only the database
docker compose --profile full up -d

# Start with logs visible (foreground)
docker compose --profile server up
```

### Stop Services

```bash
# Stop all services
docker compose down

# Stop and remove volumes (WARNING: deletes all data)
docker compose down -v
```

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f app
docker compose logs -f db
```

### Database Access

```bash
# Connect to PostgreSQL
docker compose exec db psql -U joplin -d joplin

# Run a SQL script
docker compose exec -T db psql -U joplin -d joplin < your_script.sql

# Backup database
docker compose exec -T db pg_dump -U joplin joplin > backup.sql

# Restore database
docker compose exec -T db psql -U joplin -d joplin < backup.sql
```

## Configuration

All configuration is managed through environment variables in the `.env` file.

**First time setup:**

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and update the values (especially the password):
   ```env
   POSTGRES_PASSWORD=your_secure_password
   POSTGRES_USER=joplin
   POSTGRES_DATABASE=joplin
   POSTGRES_PORT=5432
   APP_BASE_URL=http://localhost:22300
   ```

These environment variables are used by:
- PostgreSQL container to create the initial database and user
- Joplin server to connect to the database
- Init scripts (`01_init.sh`) to set up permissions

## Data Persistence

- PostgreSQL data is persisted in `./data/postgres`
- Data survives container restarts
- Data is lost if you run `docker compose down -v`

## Troubleshooting

### Trigger Not Created

If the trigger wasn't created, ensure the items table exists:

```bash
docker compose exec db psql -U joplin -d joplin -c "\dt"
```

If you see the `items` table, re-run the trigger script:

```bash
docker compose exec -T db psql -U joplin -d joplin < init/03_apply_trigger.sql
```

### Reset Everything

To start completely fresh:

```bash
docker compose down -v
rm -rf data/postgres
docker compose --profile server up -d
```

## Architecture

- **Database**: PostgreSQL 17 with persistent storage
- **Application**: Official Joplin server (`joplin/server:latest`)
- **Networks**:
  - `app-network`: Internal communication
  - `shared-network`: External access (e.g., reverse proxy)

## Ports

- Joplin Server: `22300`
- PostgreSQL: `5432`

## Automated Deployment

The project includes a GitHub Actions workflow that automatically deploys to your server.

### Setup GitHub Secrets

In your GitHub repository, go to **Settings → Secrets and variables → Actions** and add:

| Secret Name | Description | Example |
|------------|-------------|---------|
| `SSH_HOST` | Server IP or hostname | `example.com` or `192.168.1.100` |
| `SSH_USERNAME` | SSH username | `ubuntu` or `root` |
| `SSH_PRIVATE_KEY` | Private SSH key | Contents of `~/.ssh/id_rsa` |
| `SSH_PORT` | SSH port (optional) | `22` (default) |
| `DEPLOY_PATH` | Target directory on server | `/opt/joplin-sync` |

### Generate SSH Key (if needed)

On your local machine:

```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -C "github-actions"

# Copy public key to server
ssh-copy-id -i ~/.ssh/id_rsa.pub user@your-server

# Copy private key for GitHub secret
cat ~/.ssh/id_rsa
```

### Deployment Process

The workflow automatically:

1. ✅ Deploys on every push to `main` branch
2. ✅ Copies all necessary files to the server
3. ✅ Creates `.env` from `.env.example` if it doesn't exist
4. ✅ Makes init scripts executable
5. ✅ Pulls latest Docker images
6. ✅ Restarts containers with updated configuration

**Manual trigger**: Go to **Actions → Deploy to Server → Run workflow**

### First Deployment

After the first automated deployment:

1. SSH into your server:
   ```bash
   ssh user@your-server
   cd /opt/joplin-sync  # or your DEPLOY_PATH
   ```

2. Edit the `.env` file:
   ```bash
   nano .env
   # Update POSTGRES_PASSWORD and other settings
   ```

3. Restart containers:
   ```bash
   docker compose --profile server restart
   ```

4. Apply the notification trigger (after Joplin initializes):
   ```bash
   docker compose exec -T db psql -U joplin -d joplin < init/03_apply_trigger.sql
   ```
