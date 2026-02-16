# PostgreSQL SSL/TLS Configuration

This PostgreSQL Docker container is configured with SSL/TLS support using a self-signed certificate.

## SSL Certificate Details

- **Certificate Location**: `/var/lib/postgresql/data/ssl/server.crt`
- **Private Key Location**: `/var/lib/postgresql/data/ssl/server.key`
- **Certificate Validity**: 10 years
- **Certificate Subject**: `/C=ZA/ST=Gauteng/L=Johannesburg/O=PostgreSQL/OU=Database/CN=pgsql18.local`
- **Minimum TLS Version**: TLSv1.2

## Connecting with SSL

### Using psql

To connect with SSL required:

```bash
psql "host=localhost port=5432 dbname=postgres user=postgres sslmode=require"
```

To connect with SSL verification (requires the server certificate):

```bash
psql "host=localhost port=5432 dbname=postgres user=postgres sslmode=verify-ca sslrootcert=/path/to/server.crt"
```

### SSL Modes

PostgreSQL supports the following SSL modes:

- `disable` - Do not use SSL
- `allow` - Try non-SSL first, then SSL
- `prefer` - Try SSL first, then non-SSL (default)
- `require` - Require SSL connection
- `verify-ca` - Require SSL and verify server certificate
- `verify-full` - Require SSL, verify certificate and hostname

### Using Python (psycopg2)

```python
import psycopg2

conn = psycopg2.connect(
    host="localhost",
    port=5432,
    database="postgres",
    user="postgres",
    password="password",
    sslmode="require"
)
```

### Using JDBC

```java
String url = "jdbc:postgresql://localhost:5432/postgres?ssl=true&sslmode=require";
Connection conn = DriverManager.getConnection(url, "postgres", "password");
```

### Using connection strings

```
postgresql://postgres:password@localhost:5432/postgres?sslmode=require
```

## Regenerating Certificates

To regenerate the SSL certificates:

1. Connect to the running container:

   ```bash
   docker exec -it pgsql18 bash
   ```

2. Run the certificate generation script:

   ```bash
   /usr/local/bin/generate-ssl-certs.sh /var/lib/postgresql/data/ssl
   ```

3. Restart PostgreSQL:
   ```bash
   pg_ctl -D /var/lib/postgresql/data restart
   ```

## Checking SSL Status

To verify SSL is enabled:

```sql
SHOW ssl;
-- Should return: on

-- Check SSL cipher and version for current connection
SELECT * FROM pg_stat_ssl WHERE pid = pg_backend_pid();
```

To see all SSL-enabled connections:

```sql
SELECT pid, usename, application_name, client_addr, ssl, cipher, bits, compression
FROM pg_stat_ssl
JOIN pg_stat_activity USING (pid);
```

## Production Considerations

For production environments, you should:

1. **Replace the self-signed certificate** with a certificate from a trusted Certificate Authority (CA)
2. **Use `hostssl` entries** in `pg_hba.conf` to require SSL for specific users/databases
3. **Disable non-SSL connections** by using only `hostssl` (not `host`) entries
4. **Set `sslmode=verify-full`** on clients to prevent MITM attacks
5. **Regularly rotate certificates** before they expire

## Converting to CA-signed Certificate

To use a CA-signed certificate:

1. Obtain your certificate files:
   - `server.crt` - Server certificate
   - `server.key` - Private key
   - `root.crt` - CA certificate (optional, for client verification)

2. Copy them to the SSL directory in the container

3. Update file permissions:

   ```bash
   chmod 600 server.key
   chmod 644 server.crt
   chown postgres:postgres server.key server.crt
   ```

4. Restart PostgreSQL

## Troubleshooting

### Certificate permission errors

```
FATAL: could not load server certificate file "server.crt": Permission denied
```

Ensure the certificate has correct ownership and permissions (see above).

### Key file permission errors

```
FATAL: private key file "server.key" has group or world access
```

The key file must have `600` permissions: `chmod 600 server.key`

### SSL not working after rebuild

If you mounted `/var/lib/postgresql` as a volume, certificates persist across rebuilds. If you want fresh certificates, remove the old ones from the data directory before starting the container.
