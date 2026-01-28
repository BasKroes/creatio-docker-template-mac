# Creatio Docker Development Environment

Local development setup for Creatio using Docker with Redis and PostgreSQL.

## Prerequisites

1. Download and Install Docker Desktop: https://www.docker.com/products/docker-desktop/
2. Download Creatio Distribution Files for LINUX!!: https://architechts.sharepoint.com/:f:/s/Creatio/IgAQtnGXQsXUTa1DkcG4BZNTAWNWeiMYd9hW9gykC0FNgXM?e=NMHtfs 

## Installation

### 1. Copy this template folder
```bash
cp -r creatio-docker-template-mac creatio-docker
cd creatio-docker
```

#### 2. Extract Creatio distribution files into creatio-app/
```bash
unzip /path/to/Creatio_8.3.2_Linux_PostgreSQL_*.zip -d creatio-app/
```

### 3. Apply required config changes (IMPORTANT!)
#### a. Change cookie SameSite mode from "None" to "Lax" for HTTP development:
```bash
sed -i '' 's/CookiesSameSiteMode" value="None"/CookiesSameSiteMode" value="Lax"/' creatio-app/Terrasoft.WebHost.dll.config
```
##### b. Cookie SameSite Mode (Required for HTTP)
In `creatio-app/Terrasoft.WebHost.dll.config`, change:
```xml
<add key="CookiesSameSiteMode" value="None" />
```
To:
```xml
<add key="CookiesSameSiteMode" value="Lax" />
```
This is required because `SameSite=None` requires HTTPS. Without this change, you'll be able to log in but immediately redirected back to the login page.
#### c. ConnectionStrings.config (Already configured)
The template includes a pre-configured `ConnectionStrings.config` that uses Docker service names for PostgreSQL and Redis connections.
### 4. Make scripts executable
```bash
chmod +x setup.sh restore-db.sh
```
### 5. Start PostgreSQL and Redis first
```bash
docker compose up -d postgres redis
```
#### 6. Wait for services to be healthy, then restore database
```bash
./restore-db.sh creatio-app/db/*.backup
```
#### 7. Start Creatio
```bash
docker compose up -d creatio
```

## Folder Structure

```
creatio-docker/
├── docker-compose.yml      # Docker orchestration
├── init-db.sql             # PostgreSQL initialization
├── setup.sh                # Main setup script
├── restore-db.sh           # Database restore script
└── creatio-app/            # <- Extract Creatio files here
    ├── Dockerfile          # (from template)
    ├── ConnectionStrings.config  # (from template)
    ├── Terrasoft.WebHost.dll     # (from Creatio)
    ├── Terrasoft.WebHost.dll.config  # (from Creatio - needs editing)
    ├── appsettings.json          # (from Creatio)
    ├── db/                       # Database backup files
    └── ...                       # Other Creatio files
```

## Services & Ports

| Service    | Internal Port | External Port | Description                |
|------------|---------------|---------------|----------------------------|
| Creatio    | 5000          | 8080          | HTTP application server    |
| Creatio    | 5002          | 8443          | HTTPS (if configured)      |
| PostgreSQL | 5432          | 5432          | Database                   |
| Redis      | 6379          | 6379          | Caching                    |

## Default Credentials

### Creatio Application
- **URL**: http://localhost:8080
- **Username**: Supervisor
- **Password**: Supervisor

### PostgreSQL
- **Superuser**: `postgres` / `postgres`
- **Admin**: `creatio_admin` / `SysAdmin123!`
- **Application**: `creatio_user` / `CreatioUser123!`
- **Database**: `creatio_db`

## Common Commands

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# View logs
docker compose logs -f              # All services
docker compose logs -f creatio      # Creatio only
docker compose logs -f postgres     # PostgreSQL only

# Restart Creatio after config changes
docker compose restart creatio

# Access PostgreSQL CLI
docker compose exec postgres psql -U creatio_user -d creatio_db

# Access Redis CLI
docker compose exec redis redis-cli

# Rebuild Creatio container (after Dockerfile changes)
docker compose build --no-cache creatio
docker compose up -d creatio

# Create images out of current running containers (including DATA!)
docker commit creatio-postgres ghcr.io/baskroes/creatio-postgres:8.3.2
docker commit creatio-redis ghcr.io/baskroes/creatio-redis:8.3.2
docker commit creatio-app ghcr.io/baskroes/creatio:8.3.2

# Push containers to registry
docker push ghcr.io/baskroes/creatio-postgres:8.3.2
docker push ghcr.io/baskroes/creatio-redis:8.3.2
docker push ghcr.io/baskroes/creatio:8.3.2
```

## Troubleshooting

### Login redirects back to login page
This is caused by cookie issues. Ensure you've changed `CookiesSameSiteMode` from `None` to `Lax` in `Terrasoft.WebHost.dll.config`.

### .NET version mismatch error
If you see errors about .NET 6.0 vs 8.0:
- The Dockerfile removes bundled .NET runtime (`/app/dotnet`, `/app/shared`)
- Ensure you're using `mcr.microsoft.com/dotnet/aspnet:8.0` base image

### Database "relation does not exist" error
The database backup hasn't been restored. Run:
```bash
./restore-db.sh creatio-app/db/*.backup
```

### Permission denied for table
Database permissions weren't set correctly. Run:
```bash
docker compose exec postgres psql -U postgres -d creatio_db -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO creatio_user;"
docker compose exec postgres psql -U postgres -d creatio_db -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO creatio_user;"
docker compose exec postgres psql -U postgres -d creatio_db -c "GRANT ALL PRIVILEGES ON SCHEMA public TO creatio_user;"
```

### Out of shared memory during restore
PostgreSQL ran out of lock memory. The docker-compose.yml includes `max_locks_per_transaction=256` to prevent this. If still happening, increase this value.

### Container name conflicts
Remove old containers:
```bash
docker rm -f creatio-postgres creatio-redis creatio-app
docker compose up -d
```

## Setting Up a New Creatio Version

1. **Create a new working folder**:
   ```bash
   cp -r creatio-docker-template-mac creatio-docker-new
   cd creatio-docker-new
   ```

2. **Extract the new Creatio distribution**:
   ```bash
   unzip /path/to/Creatio_X.X.X_Linux_PostgreSQL_*.zip -d creatio-app/
   ```

3. **Apply required config changes**:
   ```bash
   # Cookie fix for HTTP development
   sed -i '' 's/CookiesSameSiteMode" value="None"/CookiesSameSiteMode" value="Lax"/' creatio-app/Terrasoft.WebHost.dll.config
   ```

4. **Keep template files** (ConnectionStrings.config and Dockerfile are already in creatio-app/ from the template)

5. **Start services**:
   ```bash
   docker compose up -d postgres redis
   sleep 10
   ./restore-db.sh creatio-app/db/*.backup
   docker compose up -d creatio
   ```

## Network Configuration

All services communicate via Docker network `creatio-network`. Service names resolve automatically:
- `postgres` → PostgreSQL container
- `redis` → Redis container
- `creatio` → Creatio app container

## Development with Clio and VS Code

### Install Clio (Creatio CLI)

```bash
# Install .NET SDK (if not installed)
brew install dotnet

# Install Clio globally
dotnet tool install clio -g

# Add to PATH (add to ~/.zshrc for persistence)
export PATH="$PATH:$HOME/.dotnet/tools"
```

### Register Your Creatio Instance

```bash
# Register local environment
clio reg-web-app dev -u http://localhost:8080 -l Supervisor -p Supervisor

# Set as default
clio set-webservice dev

# Test connection
clio ping
```

### Development Workflow

```bash
# List all packages
clio packages

# Pull a package to edit locally
clio pull-pkg UsrMyPackage -d ./src/UsrMyPackage

# After making changes, push back to Creatio
clio push-pkg ./src/UsrMyPackage

# Compile (required for C# changes)
clio compile

# Restart Creatio (if needed)
clio restart

# Flush Redis cache
clio flushdb
```

### VS Code Integration

This template includes VS Code configuration files:

- **`.vscode/settings.json`** - Editor settings for Creatio development
- **`.vscode/extensions.json`** - Recommended extensions (C#, Docker, Git, etc.)
- **`.vscode/tasks.json`** - Quick tasks for Clio commands
- **`.vscode/launch.json`** - Debug configurations

**To use VS Code tasks:**
1. Open the project folder in VS Code
2. Press `Cmd+Shift+P` → "Tasks: Run Task"
3. Select a task (e.g., "Clio: Pull Package", "Clio: Push Package")

### Folder Structure for Development

```
creatio-docker/
├── src/                    # Your packages (pulled via Clio)
│   ├── UsrMyPackage/
│   └── UsrAnotherPackage/
├── logs/                   # Creatio logs (mounted from container)
├── .vscode/                # VS Code configuration
└── ...
```

## Production Notes

This setup is for **development only**. For production:
- Use proper SSL certificates
- Configure stronger passwords
- Set up proper backup strategies
- Consider managed PostgreSQL (AWS RDS, Azure, etc.)
- Use Kubernetes or proper orchestration

## Sharing with Team via GitHub Container Registry

### Initial Setup (One-time, by admin)

1. **Create a GitHub Personal Access Token**:
   - Go to https://github.com/settings/tokens
   - Click **"Generate new token (classic)"**
   - Name: "Docker Registry"
   - Select scopes: `write:packages`, `read:packages`, `delete:packages`
   - Click **Generate token** and copy it

2. **Login to GitHub Container Registry**:
   ```bash
   echo "YOUR_TOKEN" | docker login ghcr.io -u baskroes --password-stdin
   ```

3. **Tag and push the image**:
   ```bash
   # Tag the image
   docker tag creatio-docker-creatio:latest ghcr.io/baskroes/creatio:8.3.2

   # Push to registry
   docker push ghcr.io/baskroes/creatio:8.3.2
   ```

4. **Set package visibility** (after first push):
   - Go to https://github.com/baskroes?tab=packages
   - Click on the `creatio` package
   - Go to **Package settings** → Add collaborators or change visibility

### For Team Members (Pulling the image)

1. **Create a GitHub Personal Access Token** with `read:packages` scope

2. **Login to registry**:
   ```bash
   echo "YOUR_TOKEN" | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
   ```

3. **Pull the image**:
   ```bash
   docker pull ghcr.io/baskroes/creatio:8.3.2
   ```

4. **Use the pre-built image** - update `docker-compose.yml`:
   ```yaml
   creatio:
     image: ghcr.io/baskroes/creatio:8.3.2
     # Comment out or remove the build section:
     # build:
     #   context: ./creatio-app
     #   dockerfile: Dockerfile
   ```

5. **Start services**:
   ```bash
   docker compose up -d postgres redis
   ./restore-db.sh creatio-app/db/*.backup
   docker compose up -d creatio
   ```

## Support

- Creatio Academy: https://academy.creatio.com
- Creatio Community: https://community.creatio.com
- Partner Portal: https://partners.creatio.com

---
Created for Architechts.nl - Creatio Implementation Partner
