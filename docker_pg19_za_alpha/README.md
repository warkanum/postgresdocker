# PostgreSQL 19 Alpha Docker Image (ZA)

PostgreSQL 19 alpha on Alpine Linux with South African locale (`en_ZA.utf8`), timezone (`Africa/Johannesburg`), SSL, and pre-installed extensions. The Dockerfile uses `postgres:19-alpine`, so rebuilds will track newer PostgreSQL 19 patch releases as they become available.

## Defaults

| Setting | Value |
|---------|-------|
| **User** | `admin` |
| **Password** | `admin` |
| **Database** | `root` |
| **Port** | `5432` |
| **Locale** | `en_ZA.utf8` |
| **Timezone** | `Africa/Johannesburg` |

Override via `.env` file or `--env-file`.

## Quick Start

```bash
# Build and run
make build
make run

# Or with docker_build.sh
./docker_build.sh pgsql19alpha

# Connect
psql -h localhost -p 5432 -U admin -d root
```

## Make Targets

| Target | Description |
|--------|-------------|
| `make build` | Build image |
| `make run` | Run container (stops existing first) |
| `make stop` | Stop and remove container |
| `make restart` | Stop + run |
| `make logs` | Tail container logs |
| `make shell` | Shell into container |
| `make push` | Push to DockerHub |
| `make all` | Build, tag, push |
| `make status` | Show images/containers |
| `make clean` | Remove container and image |

## Configuration

Edit `.env` to override defaults:

```env
POSTGRES_USER=admin
POSTGRES_PASSWORD=admin
POSTGRES_DB=root
PORT=5432
DOCKER_UID=70
DOCKER_GID=70
```

Runtime settings in `Makefile`:

| Variable | Default |
|----------|---------|
| `HOST_PORT` | `5432` |
| `DATA_DIR` | `/tmp/postgresql19_za_alpha_data` |
| `SHM_SIZE` | `4g` |
| `MEMORY_LIMIT` | `4G` |
| `CPU_LIMIT` | `4` |

## Pre-installed Extensions

| Extension | Purpose |
|-----------|---------|
| pgvector | Vector similarity search |
| PostGIS + pgrouting | Geospatial + routing |
| TimescaleDB | Time-series data |
| pg_search | ParadeDB BM25 search |
| pg_textsearch | BM25 full-text search |
| pg_jsonschema | JSON Schema validation for json/jsonb |
| pg_stat_statements | Query statistics |
| pg_cron | In-database job scheduler |
| pg_qualstats | Predicate statistics for index tuning |
| pgaudit | Audit logging |
| pg_partman | Partition management |
| pg_background | Run SQL in background workers |
| pg_repack | Online table repacking |
| pgsql-http | HTTP client |
| plpython3u | Python 3 stored procedures |
| pgcrypto | Cryptographic functions |
| uuid-ossp | UUID generation |
| pg_trgm | Trigram matching |
| hstore | Key-value store |
| fuzzystrmatch | Fuzzy string matching |
| citext | Case-insensitive text |
| btree_gist / btree_gin | Additional index types |
| amcheck | Index and heap consistency checks |
| pgstattuple | Table and index bloat statistics |
| postgres_fdw | Foreign data wrapper |
| unaccent | Accent removal |

See [Extentions.md](/home/warkanum/dev/postgresdocker/docker_pg19_za_alpha/Extentions.md) for a fuller description of every installed extension and when to use it.
`plv8` remains commented out in the Dockerfile and is not currently built into the image.

## SSL

Self-signed certificates are generated at build time. See `SSL_README.md` for details.

## Data Persistence

Data is stored at `DATA_DIR` (default `/tmp/postgresql19_za_alpha_data`) mounted to `/var/lib/postgresql`. PostgreSQL 19 uses versioned subdirectory `/var/lib/postgresql/19/docker`.

## Docker Hub

```bash
docker pull warkanum/postgresql19_za_alpha:alpha
docker run -d -p 5432:5432 --env-file .env --name pg19zaalpha warkanum/postgresql19_za_alpha:alpha
```
