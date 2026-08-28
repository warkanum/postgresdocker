# PostgreSQL Extensions Reference

This image ships with PostgreSQL 18 plus a broad set of contrib and third-party extensions for analytics, search, maintenance, geospatial work, and procedural logic.

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
| `pg_jsonschema` | Validation | Validates `json` and `jsonb` values against JSON Schema. |
| `pg_partman` | Partitioning | Automates time-based and serial-based partition management. |
| `pg_qualstats` | Observability | Tracks predicate usage in `WHERE` and `JOIN` clauses for tuning and index advice. |
| `pg_repack` | Maintenance | Rebuilds bloated tables and indexes online with minimal locking. |
| `pg_search` | Search | Provides ParadeDB full-text and relevance search features. |
| `pg_stat_statements` | Observability | Tracks normalized query execution statistics. |
| `pg_textsearch` | Search | Adds BM25-style text search support. |
| `pg_trgm` | Text | Adds trigram similarity search and fast fuzzy matching indexes. |
| `pgcrypto` | Security | Adds hashing, encryption, random bytes, and UUID helpers. |
| `pgrouting` | Geospatial | Adds routing and graph algorithms on top of PostGIS data. |
| `pgstattuple` | Maintenance | Reports table and index tuple density and bloat information. |
| `plpython3u` | Procedural | Lets you write PostgreSQL functions in Python 3. |
| `postgis` | Geospatial | Adds spatial data types, functions, and indexes. |
| `postgis_topology` | Geospatial | Adds topology-aware spatial models and validation tools. |
| `postgres_fdw` | Federation | Connects PostgreSQL tables to other PostgreSQL servers. |
| `timescaledb` | Time-series | Adds hypertables, compression, retention, and time-series optimizations. |
| `unaccent` | Text | Removes accents and diacritics for normalized text search. |
| `uuid-ossp` | Utility | Generates UUIDs using several algorithms. |
| `vector` | AI/Search | Adds vector data types and similarity search for embeddings. |
| `vchord` | AI/Search | Adds VectorChord scalable disk-friendly vector indexes compatible with pgvector data types. |

## Included via `postgresql-contrib`

The image installs `postgresql-contrib`, which provides many built-in PostgreSQL extension modules. Several are enabled automatically above, and others remain available to create later if needed, such as `auto_explain`, `dblink`, `pageinspect`, `tablefunc`, and `bloom`.

## Good Defaults By Use Case

- Search and AI: `vector`, `vchord`, `pg_search`, `pg_textsearch`, `pg_trgm`, `unaccent`
- Geospatial: `postgis`, `postgis_topology`, `pgrouting`
- Observability and tuning: `pg_stat_statements`, `pg_qualstats`, `pgstattuple`, `amcheck`
- Scheduling and async work: `pg_cron`, `pg_background`
- Partitioning and time-series: `timescaledb`, `pg_partman`
- Security and utility: `pgcrypto`, `uuid-ossp`, `citext`
- Integration: `http`, `postgres_fdw`, `plpython3u`

## Notes

- `pg_cron` requires `shared_preload_libraries` and a configured `cron.database_name`; this image wires both during initialization.
- `pg_qualstats` requires `shared_preload_libraries`; it is preloaded in `custom.conf`.
- `vchord` requires `shared_preload_libraries` and depends on `vector`; PostgreSQL 18 builds it from VectorChord `1.1.1` source because upstream release assets currently cover PostgreSQL 18 but not PostgreSQL 19 alpha.
- `pg_background` does not require preloading, but it is installed and ready to `CREATE EXTENSION`.
