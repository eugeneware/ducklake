.bail on
.mode trash
LOAD ducklake;
LOAD '/job/review-release-fixed/repository/v2.0.0-dev0/linux_amd64/postgres_scanner.duckdb_extension';
SET threads=2;
SET memory_limit='3GB';
SET TimeZone='UTC';
ATTACH 'ducklake:postgres:dbname=inline_cpu_f8814e86d154474a8f2f9aa18041c211' AS lake (METADATA_SCHEMA 'inlined_filters_100000', READ_ONLY);
.mode json
EXPLAIN (FORMAT JSON) SELECT id, payload FROM lake.events WHERE tz < TIMESTAMPTZ '2026-05-01 00:00:00+00' + (100000 * 9 // 10) * INTERVAL 1 MINUTE;
.mode trash
SELECT id, payload FROM lake.events WHERE tz < TIMESTAMPTZ '2026-05-01 00:00:00+00' + (100000 * 9 // 10) * INTERVAL 1 MINUTE;
.timer on
SELECT id, payload FROM lake.events WHERE tz < TIMESTAMPTZ '2026-05-01 00:00:00+00' + (100000 * 9 // 10) * INTERVAL 1 MINUTE;
SELECT id, payload FROM lake.events WHERE tz < TIMESTAMPTZ '2026-05-01 00:00:00+00' + (100000 * 9 // 10) * INTERVAL 1 MINUTE;
SELECT id, payload FROM lake.events WHERE tz < TIMESTAMPTZ '2026-05-01 00:00:00+00' + (100000 * 9 // 10) * INTERVAL 1 MINUTE;
SELECT id, payload FROM lake.events WHERE tz < TIMESTAMPTZ '2026-05-01 00:00:00+00' + (100000 * 9 // 10) * INTERVAL 1 MINUTE;
SELECT id, payload FROM lake.events WHERE tz < TIMESTAMPTZ '2026-05-01 00:00:00+00' + (100000 * 9 // 10) * INTERVAL 1 MINUTE;
.timer off
