.bail on
.mode trash
LOAD ducklake;
LOAD '/job/baseline/repository/v2.0.0-dev0/linux_amd64/postgres_scanner.duckdb_extension';
SET threads=2;
SET memory_limit='3GB';
SET TimeZone='UTC';
ATTACH 'ducklake:postgres:dbname=inline_cpu_94df8c82225d48578046490d9ae66330' AS lake (METADATA_SCHEMA 'inlined_filters_100000', READ_ONLY);
.mode json
EXPLAIN (FORMAT JSON) SELECT * FROM lake.events WHERE id = 73;
.mode trash
SELECT * FROM lake.events WHERE id = 73;
.timer on
SELECT * FROM lake.events WHERE id = 73;
SELECT * FROM lake.events WHERE id = 73;
SELECT * FROM lake.events WHERE id = 73;
SELECT * FROM lake.events WHERE id = 73;
SELECT * FROM lake.events WHERE id = 73;
.timer off
