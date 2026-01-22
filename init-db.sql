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

-- Grant default privileges for objects created by creatio_admin to creatio_user
-- This ensures that when creatio_admin restores a backup, creatio_user can access all objects
ALTER DEFAULT PRIVILEGES FOR ROLE creatio_admin IN SCHEMA public GRANT ALL ON TABLES TO creatio_user;
ALTER DEFAULT PRIVILEGES FOR ROLE creatio_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO creatio_user;
ALTER DEFAULT PRIVILEGES FOR ROLE creatio_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO creatio_user;

-- Create a helper function to fix ownership of all objects to creatio_user
-- Run this after restoring a backup: SELECT fix_creatio_ownership();
CREATE OR REPLACE FUNCTION fix_creatio_ownership()
RETURNS void AS $$
DECLARE
    r RECORD;
BEGIN
    -- Change owner of all tables
    FOR r IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' LOOP
        EXECUTE 'ALTER TABLE public.' || quote_ident(r.tablename) || ' OWNER TO creatio_user';
    END LOOP;

    -- Change owner of all materialized views
    FOR r IN SELECT matviewname FROM pg_matviews WHERE schemaname = 'public' LOOP
        EXECUTE 'ALTER MATERIALIZED VIEW public.' || quote_ident(r.matviewname) || ' OWNER TO creatio_user';
    END LOOP;

    -- Change owner of all views
    FOR r IN SELECT viewname FROM pg_views WHERE schemaname = 'public' LOOP
        EXECUTE 'ALTER VIEW public.' || quote_ident(r.viewname) || ' OWNER TO creatio_user';
    END LOOP;

    -- Change owner of all sequences
    FOR r IN SELECT sequencename FROM pg_sequences WHERE schemaname = 'public' LOOP
        EXECUTE 'ALTER SEQUENCE public.' || quote_ident(r.sequencename) || ' OWNER TO creatio_user';
    END LOOP;

    -- Change owner of all functions
    FOR r IN SELECT p.proname, pg_get_function_identity_arguments(p.oid) as args
             FROM pg_proc p
             JOIN pg_namespace n ON p.pronamespace = n.oid
             WHERE n.nspname = 'public' AND p.proname != 'fix_creatio_ownership' LOOP
        EXECUTE 'ALTER FUNCTION public.' || quote_ident(r.proname) || '(' || r.args || ') OWNER TO creatio_user';
    END LOOP;

    RAISE NOTICE 'Ownership of all objects in public schema transferred to creatio_user';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Allow creatio_user to execute the fix function
ALTER FUNCTION fix_creatio_ownership() OWNER TO creatio_admin;
GRANT EXECUTE ON FUNCTION fix_creatio_ownership() TO creatio_user;

-- Output confirmation
\echo 'Creatio database initialized successfully!'
\echo 'Database: creatio_db'
\echo 'Sysadmin user: creatio_admin'
\echo 'Application user: creatio_user'
\echo ''
\echo 'After restoring a backup, run: SELECT fix_creatio_ownership();'