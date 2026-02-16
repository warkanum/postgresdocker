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
if [ ! -d "$SSL_DIR" ]; then
    echo "Creating SSL directory at $SSL_DIR..."
    mkdir -p "$SSL_DIR"
    
    # Copy SSL certificates from build-time location if they exist
    if [ -f /etc/ssl/postgresql/server.crt ] && [ -f /etc/ssl/postgresql/server.key ]; then
        cp /etc/ssl/postgresql/server.crt "$SSL_DIR/server.crt"
        cp /etc/ssl/postgresql/server.key "$SSL_DIR/server.key"
        chmod 600 "$SSL_DIR/server.key"
        chmod 644 "$SSL_DIR/server.crt"
        echo "SSL certificates copied to data directory"
    else
        echo "Warning: SSL certificates not found at build-time location"
    fi
fi

# Update SSL paths in config to use data directory
if [ -f "$PGDATA/conf.d/custom.conf" ]; then
    sed -i "s|/var/lib/postgresql/ssl|$PGDATA/ssl|g" "$PGDATA/conf.d/custom.conf"
else
    echo "Warning: $PGDATA/conf.d/custom.conf not found, skipping SSL path update"
fi

# Add include_dir directive to postgresql.conf
echo "include_dir = 'conf.d'" >> "$PGDATA/postgresql.conf"
echo "Added include_dir directive to postgresql.conf"

# Apply pg_hba.conf
if [ -f /etc/postgresql/pg_hba.conf ]; then
    cp /etc/postgresql/pg_hba.conf "$PGDATA/pg_hba.conf"
    echo "Custom pg_hba.conf applied"
fi

echo "Configuration setup complete"
# Restart to apply shared_preload_libraries (required before extension creation)
pg_ctl -D "$PGDATA" -m fast -w restart