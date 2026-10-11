# Inlined filter benchmarks

These benchmarks measure reads from a partitioned DuckLake table with all rows
inlined in the metadata catalog. The shared fixture creates 100,000 rows by
default, including a 256-byte payload, and checks that no Parquet files were
written. Fixture construction and result verification are outside the timed
query. Every result is checked against a native DuckDB reference table, including
duplicate multiplicities.

The cases cover point lookups, ranges, `IN`, nulls, broad predicates, narrow and
wide projections, mixed supported and residual predicates, a runtime join, and
an unfiltered scan. Broad string and temporal predicates also measure the cost
of remote evaluation when most rows still need to be returned. Scalar cases
exercise backend type conversions; nested predicates provide a control for local evaluation. `source_timestamp_count`
follows the query and partitioning in [discussion #1134](https://github.com/duckdb/ducklake/discussions/1134).
No indexes are added to the internal catalog tables. PostgreSQL can still scan
the underlying inline table; this optimization reduces the rows transferred and
decoded by DuckDB, rather than providing indexed point lookups.

Build a baseline and candidate benchmark runner with the same DuckDB revision,
compiler, build type and extensions. For PostgreSQL, enable its extension in
both builds:

```sh
BUILD_BENCHMARK=1 ENABLE_POSTGRES_SCANNER=1 make release
```

Run from the candidate checkout, using the existing regression harness:

```sh
python3 .github/regression/run.py \
    --catalog duckdb \
    --old /path/to/baseline/build/release/benchmark/benchmark_runner \
    --new /path/to/candidate/build/release/benchmark/benchmark_runner \
    --benchmarks .github/regression/inlined_filters.csv \
    --threads 2 --samples 10 --memory-limit 3GB
```

Use `--catalog postgres` with the standard `PGHOST`, `PGPORT`, `PGUSER` and
`PGPASSWORD` environment variables to measure PostgreSQL. The runner needs
`createdb` and `dropdb` and permission to create disposable databases. Each
binary uses its own catalog and extension build. The harness alternates runs
and repeats apparent regressions. These cases are also included in `micro.csv`.

To vary buffer size, pass `--benchmark-argument rows=1000000`. Keep at least
10,000 rows so the selective timestamp queries have matches. Comparing binaries
before and after a change measures the feature without a runtime setting or
disabling other optimizer rules.

The companion `test/sql/data_inlining/inlined_filter_semantics.test` checks
correctness on a small fixture, including nulls, infinities, NaN, embedded zero
bytes, Unicode and residual expressions. It uses the standard catalog test
configuration so it can run against DuckDB, PostgreSQL and SQLite. Timing
thresholds belong in the benchmark harness, not the SQL correctness tests.

## Predicate translation

The inlined reader supplies physical column names and filters to the metadata
manager. A shared validator accepts direct comparisons, `IN`, null checks and
conjunctions. It unwraps DuckDB's optional filters and uses its comparison
helpers, including reversed operands. An unsupported `AND` child may be omitted;
an unsupported `OR` child makes the whole disjunction ineligible. The complete
DuckDB filter remains in the reader in every case.

The default metadata path evaluates typed expressions through DuckDB. PostgreSQL
uses its existing transaction-preserving remote-query path, with the same value
encoding used for inline writes. This supports booleans, signed and unsigned
integers, wide integers, decimals, floats, doubles, strings, blobs, dates and
microsecond-or-coarser timestamps, including timestamps with time zones. String
and blob comparisons use their binary storage; floating constants retain their
precision and infinity sign.

PostgreSQL stores temporal values as text because DuckDB's date and timestamp
ranges are wider. A guarded `CASE` casts only finite AD values with four-digit
years, and retains other values for DuckDB's residual evaluation. This uses the
inline writer's canonical, already validated temporal encoding; it does not
re-validate the calendar of every row using the more expensive statistics
parser. Nanosecond temporal types remain local on PostgreSQL. Nested paths,
aliases, collated strings, schema-evolution casts and arbitrary functions retain local
evaluation. Adding another type must prove both correct backend encoding and
useful performance; accepting SQL syntax alone is insufficient.

Remote evaluation can cost more than it saves when most rows match. PostgreSQL
temporal predicates must parse stored text, so the broad controls should be
reviewed alongside the selective cases. An overall speedup does not establish
that every selectivity benefits.

There is no runtime feature setting, catalog schema change, new index, or change
to snapshot visibility. This does not enable the PostgreSQL scanner's experimental
filter pushdown. The saved pre-change binary is the benchmark control.

The metadata manager owns SQL generation because it also owns the physical type
mapping and inline value encoding. The reader has no PostgreSQL type rules.
The implementation reuses DuckDB's expression and comparison helpers,
`CastColumnToTarget`, the inline writer's `DuckLakeUtil::ValueToSQL`, and the
PostgreSQL comparison type mapping already used for statistics. PostgreSQL SQL
executes through `postgres_query`, leaving its execution to that storage engine.
