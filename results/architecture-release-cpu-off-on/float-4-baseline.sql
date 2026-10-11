.bail on
.mode trash
LOAD ducklake;
LOAD '/job/review-release-baseline/repository/v2.0.0-dev0/linux_amd64/postgres_scanner.duckdb_extension';
SET threads=2;
SET memory_limit='3GB';
SET TimeZone='UTC';
ATTACH 'ducklake:postgres:dbname=inline_cpu_0e95ba84b9184b008947fd9e94f0a31e' AS lake (METADATA_SCHEMA 'inlined_filters_100000', READ_ONLY);
.mode json
EXPLAIN (FORMAT JSON) SELECT id, payload FROM lake.events WHERE single_value = 73.25::FLOAT;
.mode trash
SELECT id, payload FROM lake.events WHERE single_value = 73.25::FLOAT;
.timer on
SELECT id, payload FROM lake.events WHERE single_value = 73.25::FLOAT;
SELECT id, payload FROM lake.events WHERE single_value = 73.25::FLOAT;
SELECT id, payload FROM lake.events WHERE single_value = 73.25::FLOAT;
SELECT id, payload FROM lake.events WHERE single_value = 73.25::FLOAT;
SELECT id, payload FROM lake.events WHERE single_value = 73.25::FLOAT;
.timer off
