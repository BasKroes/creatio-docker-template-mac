#!/bin/bash
# Restore Creatio PostgreSQL database backup
# Usage: ./restore-db.sh /path/to/backup.backup

set -e

BACKUP_FILE=$1

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: ./restore-db.sh /path/to/backup.backup"
    echo ""
    echo "This script restores a Creatio PostgreSQL database backup."
    echo "The backup file should be the .backup file from your Creatio distribution."
    exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "========================================="
echo "Restoring Creatio Database"
echo "========================================="
echo ""
echo "Backup file: $BACKUP_FILE"
echo ""

# Check if containers are running
if ! docker compose ps | grep -q "creatio-postgres.*running"; then
    echo "Starting PostgreSQL container..."
    docker compose up -d postgres
    sleep 5
fi

# Drop and recreate the database
echo "Recreating database..."
docker compose exec -T postgres psql -U postgres -c "DROP DATABASE IF EXISTS creatio_db;" || true
docker compose exec -T postgres psql -U postgres -c "CREATE DATABASE creatio_db WITH OWNER = pg_user ENCODING = 'UTF8' CONNECTION LIMIT = -1;"

# Restore the backup
echo ""
echo "Restoring backup (this may take a few minutes)..."
docker compose exec -T postgres pg_restore \
    -U pg_sysadmin \
    -d creatio_db \
    --no-owner \
    --no-privileges \
    --verbose \
    < "$BACKUP_FILE"

# Run the type casts SQL (required for Creatio)
echo ""
echo "Applying Creatio type casts..."

# Download CreateTypeCastsPostgreSql.sql if not exists
if [ ! -f "CreateTypeCastsPostgreSql.sql" ]; then
    echo "Downloading CreateTypeCastsPostgreSql.sql..."
    curl -sL "https://academy.creatio.com/sites/academy_en/files/sql/PostgreSQL/CreateTypeCastsPostgreSql.sql" -o CreateTypeCastsPostgreSql.sql
fi

docker compose exec -T postgres psql -U pg_sysadmin -d creatio_db < CreateTypeCastsPostgreSql.sql

# Fix ownership
echo ""
echo "Fixing database ownership..."
docker compose exec -T postgres psql -U pg_sysadmin -d creatio_db -c "
DO \$\$ 
DECLARE 
    r RECORD;
BEGIN
    FOR r IN SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP
        EXECUTE 'ALTER TABLE public.' || quote_ident(r.tablename) || ' OWNER TO pg_user';
    END LOOP;
END \$\$;
"

docker compose exec -T postgres psql -U pg_sysadmin -d creatio_db -c "
DO \$\$ 
DECLARE 
    r RECORD;
BEGIN
    FOR r IN SELECT sequence_name FROM information_schema.sequences WHERE sequence_schema = 'public'
    LOOP
        EXECUTE 'ALTER SEQUENCE public.' || quote_ident(r.sequence_name) || ' OWNER TO pg_user';
    END LOOP;
END \$\$;
"

echo ""
echo "========================================="
echo "✅ Database restored successfully!"
echo "========================================="
echo ""
echo "You can now start/restart Creatio:"
echo "  docker compose up -d"
echo ""
