-- PostgreSQL initialization script for Creatio
-- This runs automatically when the postgres container starts for the first time
-- Note: PostgreSQL reserves role names starting with "pg_", so we use "creatio_" prefix

-- Create sysadmin user (for DB administration, backup/restore)
CREATE USER creatio_admin WITH SUPERUSER PASSWORD 'SysAdmin123!';

-- Create public user (for Creatio application connection)
CREATE USER creatio_user WITH PASSWORD 'CreatioUser123!';

-- Create the Creatio database
CREATE DATABASE creatio_db 
    WITH OWNER = creatio_user 
    ENCODING = 'UTF8' 
    LC_COLLATE = 'en_US.utf8' 
    LC_CTYPE = 'en_US.utf8'
    CONNECTION LIMIT = -1;

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE creatio_db TO creatio_admin;
GRANT ALL PRIVILEGES ON DATABASE creatio_db TO creatio_user;

-- Connect to creatio_db and set up extensions
\c creatio_db

-- Create UUID extension (used by Creatio)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Grant schema permissions to creatio_user
GRANT ALL ON SCHEMA public TO creatio_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO creatio_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO creatio_user;

-- Output confirmation
\echo 'Creatio database initialized successfully!'
\echo 'Database: creatio_db'
\echo 'Sysadmin user: creatio_admin'  
\echo 'Application user: creatio_user'