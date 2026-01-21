# Creatio Docker Installation Guide for Mac

Step-by-step instructions to get Creatio running on your Mac from scratch.

## Step 1: Install Docker Desktop

1. **Download Docker Desktop for Mac**:
   - Go to: https://www.docker.com/products/docker-desktop/
   - Click **"Download for Mac"**
   - Choose the correct version:
     - **Apple Silicon** (M1/M2/M3 chips) - most newer Macs
     - **Intel chip** - older Macs

2. **Install Docker Desktop**:
   - Open the downloaded `.dmg` file
   - Drag Docker to your Applications folder
   - Open Docker from Applications
   - Accept the terms and complete the setup wizard

3. **Configure Docker Resources**:
   - Click the Docker icon in the menu bar → **Settings**
   - Go to **Resources**
   - Set **Memory** to at least **8GB** (16GB recommended)
   - Set **CPU** to at least **4 cores**
   - Click **Apply & Restart**

4. **Verify Docker is running**:
   ```bash
   docker --version
   docker compose version
   ```
   Both commands should show version numbers.

## Step 2: Set Up the Project Folder

1. **Create a folder for Docker projects**:
   ```bash
   mkdir -p ~/Docker
   cd ~/Docker
   ```

2. **Get the template files** from the team shared drive or repository:
   ```bash
   # Option A: Clone from git (if available)
   git clone <repository-url> creatio-docker

   # Option B: Copy from shared location
   cp -r /path/to/creatio-docker-template-mac creatio-docker
   ```

3. **Navigate to the project folder**:
   ```bash
   cd ~/Docker/creatio-docker
   ```

## Step 3: Pull the Creatio Image

```bash
docker pull ghcr.io/baskroes/creatio:8.3.2
```

This downloads the pre-built Creatio container (~3GB, may take a few minutes).

## Step 4: Update docker-compose.yml to Use the Image

Edit `docker-compose.yml` and change the creatio service to use the pulled image:

```yaml
  # Creatio Application Server
  creatio:
    image: ghcr.io/baskroes/creatio:8.3.2
    # Comment out or remove these lines:
    # build:
    #   context: ./creatio-app
    #   dockerfile: Dockerfile
    container_name: creatio-app
    ports:
      - "8080:5000"
      - "8443:5002"
    # ... rest stays the same
```

## Step 5: Get the Database Backup

You need the Creatio database backup file. Get it from:
- Team shared drive, OR
- Extract from Creatio distribution ZIP (in the `db/` folder)

Place the `.backup` file somewhere accessible, e.g.:
```bash
mkdir -p ~/Docker/creatio-docker/db-backup
cp /path/to/creatio.backup ~/Docker/creatio-docker/db-backup/
```

## Step 6: Start the Services

```bash
cd ~/Docker/creatio-docker

# Make scripts executable
chmod +x restore-db.sh

# Start PostgreSQL and Redis first
docker compose up -d postgres redis

# Wait for them to be ready (about 10 seconds)
sleep 10

# Verify they're running
docker compose ps
```

You should see `creatio-postgres` and `creatio-redis` with status `running (healthy)`.

## Step 7: Restore the Database

```bash
./restore-db.sh ~/Docker/creatio-docker/db-backup/creatio.backup
```

This takes 2-5 minutes. You'll see progress messages and finally:
```
=========================================
✅ Database restored successfully!
=========================================
```

## Step 8: Start Creatio

```bash
docker compose up -d creatio
```

Wait about 30-60 seconds for Creatio to fully start. Check the logs:
```bash
docker compose logs -f creatio
```

Look for: `Application started`

Press `Ctrl+C` to exit the logs.

## Step 9: Access Creatio

Open your browser and go to:

**http://localhost:8080**

Login credentials:
- **Username**: `Supervisor`
- **Password**: `Supervisor`

## Quick Reference Commands

```bash
# Start everything
docker compose up -d

# Stop everything
docker compose down

# View Creatio logs
docker compose logs -f creatio

# Restart Creatio
docker compose restart creatio

# Check status
docker compose ps

# Stop everything and remove data (fresh start)
docker compose down -v
```

## Troubleshooting

### "Cannot connect to Docker daemon"
- Make sure Docker Desktop is running (check for the whale icon in the menu bar)

### Login page keeps redirecting back
- Clear browser cookies for localhost
- Try an incognito/private window

### "Connection refused" or can't reach localhost:8080
- Check if Creatio is running: `docker compose ps`
- Check logs for errors: `docker compose logs creatio`

### Database errors
- Make sure you restored the database before starting Creatio
- Check PostgreSQL is healthy: `docker compose ps postgres`

## Getting Help

If you're stuck:
1. Check the logs: `docker compose logs`
2. Ask in the team Slack/Teams channel
3. Contact: Bas Kroes

---
Architechts.nl - Creatio Implementation Partner
