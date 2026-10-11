.bail on
.mode trash
LOAD ducklake;
LOAD '/job/review-fixed/repository/v2.0.0-dev0/linux_amd64/postgres_scanner.duckdb_extension';
SET threads=2;
SET memory_limit='3GB';
SET TimeZone='UTC';
ATTACH 'ducklake:postgres:dbname=inline_cpu_94df8c82225d48578046490d9ae66330' AS lake (METADATA_SCHEMA 'inlined_filters_100000', READ_ONLY);
.mode json
EXPLAIN (FORMAT JSON) SELECT id, payload FROM lake.events WHERE ts >= TIMESTAMP '2026-05-05' AND ts < TIMESTAMP '2026-05-06 12:00:00';
.mode trash
SELECT id, payload FROM lake.events WHERE ts >= TIMESTAMP '2026-05-05' AND ts < TIMESTAMP '2026-05-06 12:00:00';
.timer on
SELECT id, payload FROM lake.events WHERE ts >= TIMESTAMP '2026-05-05' AND ts < TIMESTAMP '2026-05-06 12:00:00';
SELECT id, payload FROM lake.events WHERE ts >= TIMESTAMP '2026-05-05' AND ts < TIMESTAMP '2026-05-06 12:00:00';
SELECT id, payload FROM lake.events WHERE ts >= TIMESTAMP '2026-05-05' AND ts < TIMESTAMP '2026-05-06 12:00:00';
SELECT id, payload FROM lake.events WHERE ts >= TIMESTAMP '2026-05-05' AND ts < TIMESTAMP '2026-05-06 12:00:00';
SELECT id, payload FROM lake.events WHERE ts >= TIMESTAMP '2026-05-05' AND ts < TIMESTAMP '2026-05-06 12:00:00';
.timer off
