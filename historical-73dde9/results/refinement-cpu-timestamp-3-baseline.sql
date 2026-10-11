.bail on
.mode trash
LOAD ducklake;
LOAD postgres;
SET threads=2;
SET memory_limit='3GB';
SET TimeZone='UTC';
ATTACH 'ducklake:postgres:dbname=ducklake_inline_cpu_cef1d5408dc9451e93ba5cf304cf63e9' AS lake (METADATA_SCHEMA 'inlined_filters_100000', READ_ONLY);
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
