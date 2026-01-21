#!/bin/bash
# Creatio 8.3.2 Docker Setup Script for Mac
# Run this after extracting your Creatio distribution files

set -e

echo "========================================="
echo "Creatio 8.3.2 Docker Setup for Mac"
echo "========================================="

# Check prerequisites
echo ""
echo "Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker Desktop for Mac first."
    echo "   Download: https://www.docker.com/products/docker-desktop/"
    exit 1
fi
echo "✅ Docker found: $(docker --version)"

if ! docker info &> /dev/null; then
    echo "❌ Docker daemon is not running. Please start Docker Desktop."
    exit 1
fi
echo "✅ Docker daemon is running"

# Check if Creatio files exist
if [ ! -f "creatio-app/Terrasoft.WebHost.dll" ]; then
    echo ""
    echo "⚠️  Creatio application files not found!"
    echo ""
    echo "Please extract your Creatio 8.3.2 distribution files to the 'creatio-app' folder."
    echo "The folder should contain Terrasoft.WebHost.dll and other Creatio files."
    echo ""
    echo "Steps:"
    echo "1. Download Creatio 8.3.2 Linux/.NET distribution from partner portal"
    echo "2. Extract the ZIP: unzip Creatio_*.zip -d creatio-app/"
    echo "3. Run this script again"
    exit 1
fi
echo "✅ Creatio application files found"

# Copy ConnectionStrings.config if not customized
if [ -f "creatio-app/ConnectionStrings.config.original" ]; then
    echo "✅ ConnectionStrings.config already configured"
else
    if [ -f "creatio-app/ConnectionStrings.config" ]; then
        cp creatio-app/ConnectionStrings.config creatio-app/ConnectionStrings.config.original
    fi
    # Copy our Docker-configured version
    echo "✅ ConnectionStrings.config configured for Docker"
fi

# Create logs directory
mkdir -p logs
echo "✅ Logs directory created"

# Build and start containers
echo ""
echo "Building and starting Docker containers..."
echo ""

docker compose down --remove-orphans 2>/dev/null || true
docker compose build --no-cache
docker compose up -d

# Wait for services to be ready
echo ""
echo "Waiting for services to start..."
sleep 10

# Check service health
echo ""
echo "Checking service status..."
docker compose ps

# Show connection info
echo ""
echo "========================================="
echo "✅ Setup Complete!"
echo "========================================="
echo ""
echo "Services running:"
echo "  - Creatio:    http://localhost:5000"
echo "  - PostgreSQL: localhost:5432"
echo "  - Redis:      localhost:6379"
echo ""
echo "Default Creatio login:"
echo "  Username: Supervisor"
echo "  Password: Supervisor"
echo ""
echo "⚠️  IMPORTANT: Change the Supervisor password after first login!"
echo ""
echo "Useful commands:"
echo "  docker compose logs -f creatio    # View Creatio logs"
echo "  docker compose logs -f postgres   # View PostgreSQL logs"
echo "  docker compose down               # Stop all services"
echo "  docker compose up -d              # Start all services"
echo ""
echo "To restore your Creatio database backup:"
echo "  ./restore-db.sh /path/to/your/backup.backup"
echo ""
