# PostgreSQL Extensions Reference

Basic PostgreSQL 19 image: contrib plus lightweight third-party extensions. Complex builds are left out.

## Installed Extensions

| Extension | Category | What it does |
|-----------|----------|--------------|
| `amcheck` | Integrity | Verifies B-tree and related structure consistency to help detect corruption. |
| `btree_gin` | Indexing | Adds GIN operator classes for common scalar data types. |
| `btree_gist` | Indexing | Adds GiST operator classes for common scalar data types and exclusion constraints. |
| `citext` | Text | Provides case-insensitive text columns and operators. |
| `fuzzystrmatch` | Text | Adds phonetic and fuzzy matching helpers like Soundex and Levenshtein. |
| `hstore` | Document | Adds a lightweight key/value data type for semi-structured attributes. |
| `http` | Integration | Lets SQL functions make outbound HTTP requests. |
| `pg_background` | Jobs | Runs SQL asynchronously in PostgreSQL background workers. |
| `pg_cron` | Scheduling | Schedules recurring SQL jobs inside PostgreSQL. |
| `pg_partman` | Partitioning | Automates time-based and serial-based partition management. |
| `pg_qualstats` | Observability | Tracks predicate usage in `WHERE` and `JOIN` clauses for tuning and index advice. |
| `pg_repack` | Maintenance | Rebuilds bloated tables and indexes online with minimal locking. |
| `pg_stat_statements` | Observability | Tracks normalized query execution statistics. |
| `pg_trgm` | Text | Adds trigram similarity search and fast fuzzy matching indexes. |
| `pgcrypto` | Security | Adds hashing, encryption, random bytes, and UUID helpers. |
| `pgstattuple` | Maintenance | Reports table and index tuple density and bloat information. |
| `plpython3u` | Procedural | Lets you write PostgreSQL functions in Python 3. |
| `postgres_fdw` | Federation | Connects PostgreSQL tables to other PostgreSQL servers. |
| `unaccent` | Text | Removes accents and diacritics for normalized text search. |
| `uuid-ossp` | Utility | Generates UUIDs using several algorithms. |
| `vector` | AI/Search | Adds vector data types and similarity search for embeddings. |

## Included via `postgresql-contrib`

The image installs `postgresql-contrib`, which provides many built-in PostgreSQL extension modules. Several are enabled automatically above, and others remain available to create later if needed, such as `auto_explain`, `dblink`, `pageinspect`, `tablefunc`, and `bloom`.

## Good Defaults By Use Case

- Search and AI: `vector`, `pg_trgm`, `unaccent`
- Partitioning: `pg_partman`
- Observability and tuning: `pg_stat_statements`, `pg_qualstats`, `pgstattuple`, `amcheck`
- Scheduling and async work: `pg_cron`, `pg_background`
- Security and utility: `pgcrypto`, `uuid-ossp`, `citext`
- Integration: `http`, `postgres_fdw`, `plpython3u`

## Notes

- `pg_cron` requires `shared_preload_libraries` and a configured `cron.database_name`; this image wires both during initialization.
- `pg_qualstats` requires `shared_preload_libraries`; it is preloaded in `custom.conf`.
- `pg_background` does not require preloading, but it is installed and ready to `CREATE EXTENSION`.
- Not included (use `docker_pg19_za` or `docker_pg18_za` instead):
  - `timescaledb`: upstream CMake rejects PostgreSQL > 18.
  - `pg_textsearch`: PG19 support is beta upstream.
  - `postgis`, `postgis_topology`, `pgrouting`: heavy GDAL/PROJ/GEOS/Boost builds.
- `pg_search`, `pg_jsonschema` and `vchord` are not built for PostgreSQL 19: upstream has no PG19 support yet (pgrx/feature flags stop at `pg18`).
