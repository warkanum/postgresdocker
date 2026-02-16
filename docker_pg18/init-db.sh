#!/bin/bash
set -e

# Perform any actions needed on the initialized database

# Variables
POSTGRES_USER=${POSTGRES_USER:-postgres}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-password}
POSTGRES_DB=${POSTGRES_DB:-postgres}

cat /etc/postgresql/postgresql.conf >> /var/lib/postgresql/data/postgresql.conf
cat /etc/postgresql/pg_hba.conf > /var/lib/postgresql/data/pg_hba.conf

# Perform initialization
psql -v --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create a user
    CREATE USER "$POSTGRES_USER" WITH PASSWORD '$POSTGRES_PASSWORD';

    -- Create a database
    CREATE DATABASE "$POSTGRES_DB" ENCODING 'UTF-8' LC_COLLATE='en_US.utf8' LC_CTYPE='en_US.utf8' TEMPLATE=template0;

    -- Grant necessary privileges to the user
    ALTER USER "$POSTGRES_USER" CREATEDB SUPERUSER;

    -- Connect to the new database
    \c "$POSTGRES_DB"
    ;
    -- Perform additional initialization steps if needed

    \q
EOSQL

psql -v ON_ERROR_STOP --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f /opt/BITECHCORE.upg
