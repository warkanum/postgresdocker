#!/bin/bash
set -e

echo "Setting up custom PostgreSQL configuration via include_dir..."

# Create config directory
mkdir -p "$PGDATA/conf.d"

# Copy custom config file
if [ -f /etc/postgresql/custom.conf ]; then
    cp /etc/postgresql/custom.conf "$PGDATA/conf.d/custom.conf"
    echo "Custom config copied to $PGDATA/conf.d/custom.conf"
else
    echo "ERROR: /etc/postgresql/custom.conf not found in image! Rebuild without cache."
    exit 1
fi

# Ensure SSL certificates exist in data directory
SSL_DIR="$PGDATA/ssl"
mkdir -p "$SSL_DIR"

# Copy SSL certificates from build-time location if they exist
if [ -f /etc/ssl/postgresql/server.crt ] && [ -f /etc/ssl/postgresql/server.key ]; then
    cp /etc/ssl/postgresql/server.crt "$SSL_DIR/server.crt"
    cp /etc/ssl/postgresql/server.key "$SSL_DIR/server.key"
    chmod 600 "$SSL_DIR/server.key"
    chmod 644 "$SSL_DIR/server.crt"
    # Ensure the runtime postgres user owns the auto-generated certificates.
    # The build-time certs are copied (preserving the build uid) and chmod'd,
    # but never chown'd. When the mounted data volume is owned by a different
    # uid, postgres cannot read server.key and exits with:
    #   FATAL: private key file "server.key" has group or world access
    #   FATAL: could not load server certificate file "server.crt"
    # Fix ownership explicitly so SSL loads reliably regardless of volume owner.
    chown -R postgres:postgres "$SSL_DIR" 2>/dev/null || true
    echo "SSL certificates copied to data directory"
else
    echo "Warning: SSL certificates not found at build-time location"
fi

# Update SSL paths in config to use data directory
if [ -f "$PGDATA/conf.d/custom.conf" ]; then
    sed -i "s|/var/lib/postgresql/ssl|$PGDATA/ssl|g" "$PGDATA/conf.d/custom.conf"
else
    echo "Warning: $PGDATA/conf.d/custom.conf not found, skipping SSL path update"
fi

# Keep pg_cron aligned with the database created by the official entrypoint.
if [ -f "$PGDATA/conf.d/custom.conf" ]; then
    if grep -Eq "^[[:space:]]*cron\\.database_name[[:space:]]*=" "$PGDATA/conf.d/custom.conf"; then
        sed -i "s|^[[:space:]]*cron\\.database_name[[:space:]]*=.*|cron.database_name = '${POSTGRES_DB}'|" "$PGDATA/conf.d/custom.conf"
    else
        printf "\ncron.database_name = '%s'\n" "$POSTGRES_DB" >> "$PGDATA/conf.d/custom.conf"
    fi
    echo "Configured pg_cron metadata database: ${POSTGRES_DB}"
fi

# Add include_dir directive to postgresql.conf once, with valid quoting.
if grep -Eq "^[[:space:]]*include_dir[[:space:]]*=[[:space:]]*'conf\\.d'[[:space:]]*$" "$PGDATA/postgresql.conf"; then
    echo "include_dir directive already present in postgresql.conf"
else
    printf "\ninclude_dir = 'conf.d'\n" >> "$PGDATA/postgresql.conf"
    echo "Added include_dir directive to postgresql.conf"
fi

# Apply pg_hba.conf
if [ -f /etc/postgresql/pg_hba.conf ]; then
    cp /etc/postgresql/pg_hba.conf "$PGDATA/pg_hba.conf"
    echo "Custom pg_hba.conf applied"
fi

echo "Configuration setup complete"
# Restart to apply shared_preload_libraries (required before extension creation)
pg_ctl -D "$PGDATA" -m fast -w restart
