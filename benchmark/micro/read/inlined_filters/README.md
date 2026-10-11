# Inlined filter benchmarks

These benchmarks measure reads from a partitioned DuckLake table with all rows
inlined in the metadata catalog. The shared fixture creates 100,000 rows by
default, including a 256-byte payload, and checks that no Parquet files were
written. Fixture construction and result verification are outside the timed
query. Every result is checked against a native DuckDB reference table, including
duplicate multiplicities.

The cases cover point lookups, ranges, `IN`, nulls, broad predicates, narrow and
wide projections, mixed supported and residual predicates, a runtime join, and
an unfiltered scan. Scalar and nested types provide controls for predicates
that cannot be pushed down. `source_timestamp_count` follows the query and
partitioning in [discussion #1134](https://github.com/duckdb/ducklake/discussions/1134).
No indexes are added to the internal catalog tables.

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
