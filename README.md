# Creatio 8.3.2 Docker Development Environment

Local development setup for Creatio 8.3.2 on Mac (Intel) using Docker with PostgreSQL and Redis.

## Prerequisites

1. **Docker Desktop for Mac**
   - Download: https://www.docker.com/products/docker-desktop/
   - Allocate at least 8GB RAM to Docker (16GB recommended)
   - Settings → Resources → Memory: 8GB+

2. **Creatio 8.3.2 Distribution Files**
   - Log into Creatio Partner Portal
   - Download the Linux/.NET version (NOT Windows/IIS)
   - File pattern: `Creatio_*_Linux_PostgreSQL_*.zip`

3. **Creatio License** (obtain from partner portal)

## Quick Start

```bash
# 1. Clone/copy this folder to your dev machine
cd creatio-docker

# 2. Extract Creatio distribution files
unzip /path/to/Creatio_8.3.2_Linux_PostgreSQL_*.zip -d creatio-app/

# 3. Make scripts executable
chmod +x setup.sh restore-db.sh

# 4. Run setup
./setup.sh

# 5. Restore the database (from your Creatio distribution)
./restore-db.sh creatio-app/db/*.backup
```

## Folder Structure

```
creatio-docker/
├── docker-compose.yml      # Docker orchestration
├── init-db.sql             # PostgreSQL initialization
├── setup.sh                # Main setup script
├── restore-db.sh           # Database restore script
├── logs/                   # Creatio application logs
└── creatio-app/            # <- Extract Creatio files here
    ├── Dockerfile
    ├── ConnectionStrings.config
    ├── Terrasoft.WebHost.dll
    ├── appsettings.json
    ├── db/                 # Database backup files
    └── ...                 # Other Creatio files
```

## Services & Ports

| Service    | Port  | Description                |
|------------|-------|----------------------------|
| Creatio    | 5000  | HTTP application server    |
| Creatio    | 5002  | HTTPS (if configured)      |
| PostgreSQL | 5432  | Database                   |
| Redis      | 6379  | Caching                    |

## Default Credentials

### Creatio Application
- **URL**: http://localhost:5000
- **Username**: Supervisor
- **Password**: Supervisor
- ⚠️ **Change immediately after first login!**

### PostgreSQL
- **Sysadmin**: `pg_sysadmin` / `SysAdmin123!`
- **Application**: `pg_user` / `CreatioUser123!`
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

# Restart Creatio after code changes
docker compose restart creatio

# Access PostgreSQL CLI
docker compose exec postgres psql -U pg_user -d creatio_db

# Access Redis CLI
docker compose exec redis redis-cli

# Rebuild Creatio container (after Dockerfile changes)
docker compose build --no-cache creatio
docker compose up -d creatio
```

## Development Workflow

### Using Clio (Recommended)

Install Clio for package development:

```bash
# Install Clio globally
dotnet tool install clio -g

# Register your local environment
clio reg-web-app local -u http://localhost:5000 -l Supervisor -p Supervisor

# Set as default
clio set local

# Common Clio commands
clio packages                    # List packages
clio pull-pkg MyPackage          # Download package for editing
clio push-pkg MyPackage          # Push changes
clio restart                     # Restart Creatio app
clio compile                     # Compile all
```

### Hot Reload for Frontend

For frontend (JavaScript/CSS) changes, you can mount the package folder:

1. Pull your package locally: `clio pull-pkg MyPackage`
2. Edit files in the mounted volume
3. Refresh browser to see changes (no compile needed for JS/CSS)

### Backend Development

For C# changes:
1. Make changes in your package
2. Push with Clio: `clio push-pkg MyPackage`
3. Compile: `clio compile`

## Troubleshooting

### Creatio won't start
```bash
# Check logs
docker compose logs creatio

# Common issues:
# - Database not ready: Wait for PostgreSQL to fully start
# - Connection string error: Verify ConnectionStrings.config
# - License issue: Ensure license is activated
```

### Database connection failed
```bash
# Verify PostgreSQL is running
docker compose ps postgres

# Test connection
docker compose exec postgres pg_isready

# Check PostgreSQL logs
docker compose logs postgres
```

### Redis connection failed
```bash
# Verify Redis is running
docker compose exec redis redis-cli ping
# Should return: PONG
```

### Permission errors on Mac
```bash
# Fix volume permissions
chmod -R 755 creatio-app/
chmod -R 777 logs/
```

### Out of memory
Increase Docker Desktop memory allocation:
- Docker Desktop → Settings → Resources → Memory → 8GB+

## Updating Creatio

⚠️ **Important**: Creatio updates in Docker require manual steps.

1. Backup your database:
   ```bash
   docker compose exec postgres pg_dump -U pg_sysadmin -Fc creatio_db > backup_$(date +%Y%m%d).backup
   ```

2. Download new Creatio version

3. Replace files in `creatio-app/` (keep ConnectionStrings.config)

4. Run the Creatio update utility (from Creatio distribution)

5. Restart:
   ```bash
   docker compose down
   docker compose build --no-cache creatio
   docker compose up -d
   ```

## Network Configuration

All services communicate via Docker network `creatio-network`. Service names resolve automatically:
- `postgres` → PostgreSQL container
- `redis` → Redis container
- `creatio` → Creatio app container

## Production Notes

This setup is for **development only**. For production:
- Use proper SSL certificates
- Configure stronger passwords
- Set up proper backup strategies
- Consider managed PostgreSQL (AWS RDS, Azure, etc.)
- Use Kubernetes or proper orchestration

## Support

- Creatio Academy: https://academy.creatio.com
- Creatio Community: https://community.creatio.com
- Partner Portal: https://partners.creatio.com

---
Created for Architechts.nl - Creatio Implementation Partner
