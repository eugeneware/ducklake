.bail on
.mode trash
LOAD ducklake;
LOAD postgres;
SET threads=2;
SET memory_limit='3GB';
SET TimeZone='UTC';
ATTACH 'ducklake:postgres:dbname=ducklake_inline_cpu_cef1d5408dc9451e93ba5cf304cf63e9' AS lake (METADATA_SCHEMA 'inlined_filters_100000', READ_ONLY);
.mode json
EXPLAIN (FORMAT JSON) SELECT count(*) AS count FROM lake.events
WHERE source_id = 23 AND tz >= TIMESTAMPTZ '2026-05-05 00:00:00+00'
AND tz < TIMESTAMPTZ '2026-05-06 12:00:00+02';
.mode trash
SELECT count(*) AS count FROM lake.events
WHERE source_id = 23 AND tz >= TIMESTAMPTZ '2026-05-05 00:00:00+00'
AND tz < TIMESTAMPTZ '2026-05-06 12:00:00+02';
.timer on
SELECT count(*) AS count FROM lake.events
WHERE source_id = 23 AND tz >= TIMESTAMPTZ '2026-05-05 00:00:00+00'
AND tz < TIMESTAMPTZ '2026-05-06 12:00:00+02';
SELECT count(*) AS count FROM lake.events
WHERE source_id = 23 AND tz >= TIMESTAMPTZ '2026-05-05 00:00:00+00'
AND tz < TIMESTAMPTZ '2026-05-06 12:00:00+02';
SELECT count(*) AS count FROM lake.events
WHERE source_id = 23 AND tz >= TIMESTAMPTZ '2026-05-05 00:00:00+00'
AND tz < TIMESTAMPTZ '2026-05-06 12:00:00+02';
SELECT count(*) AS count FROM lake.events
WHERE source_id = 23 AND tz >= TIMESTAMPTZ '2026-05-05 00:00:00+00'
AND tz < TIMESTAMPTZ '2026-05-06 12:00:00+02';
SELECT count(*) AS count FROM lake.events
WHERE source_id = 23 AND tz >= TIMESTAMPTZ '2026-05-05 00:00:00+00'
AND tz < TIMESTAMPTZ '2026-05-06 12:00:00+02';
.timer off
