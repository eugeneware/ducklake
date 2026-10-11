.bail on
.mode trash
LOAD ducklake;
LOAD postgres;
SET threads=2;
SET memory_limit='3GB';
SET TimeZone='UTC';
ATTACH 'ducklake:postgres:dbname=ducklake_inline_cpu_cef1d5408dc9451e93ba5cf304cf63e9' AS lake (METADATA_SCHEMA 'inlined_filters_100000', READ_ONLY);
.mode json
EXPLAIN (FORMAT JSON) SELECT id, payload FROM lake.events WHERE flag = true;
.mode trash
SELECT id, payload FROM lake.events WHERE flag = true;
.timer on
SELECT id, payload FROM lake.events WHERE flag = true;
SELECT id, payload FROM lake.events WHERE flag = true;
SELECT id, payload FROM lake.events WHERE flag = true;
SELECT id, payload FROM lake.events WHERE flag = true;
SELECT id, payload FROM lake.events WHERE flag = true;
.timer off
