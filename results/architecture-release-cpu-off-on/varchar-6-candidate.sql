.bail on
.mode trash
LOAD ducklake;
LOAD '/job/architecture-release-fixed/repository/v2.0.0-dev0/linux_amd64/postgres_scanner.duckdb_extension';
SET threads=2;
SET memory_limit='3GB';
SET TimeZone='UTC';
ATTACH 'ducklake:postgres:dbname=inline_cpu_0e95ba84b9184b008947fd9e94f0a31e' AS lake (METADATA_SCHEMA 'inlined_filters_100000', READ_ONLY);
.mode json
EXPLAIN (FORMAT JSON) SELECT id, payload FROM lake.events WHERE label = 'key73';
.mode trash
SELECT id, payload FROM lake.events WHERE label = 'key73';
.timer on
SELECT id, payload FROM lake.events WHERE label = 'key73';
SELECT id, payload FROM lake.events WHERE label = 'key73';
SELECT id, payload FROM lake.events WHERE label = 'key73';
SELECT id, payload FROM lake.events WHERE label = 'key73';
SELECT id, payload FROM lake.events WHERE label = 'key73';
.timer off
