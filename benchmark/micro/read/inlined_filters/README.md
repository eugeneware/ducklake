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
DuckDB filter remains in the reader in every case. The reader requests row-id
ordering only when merging pending deletions. Other reads avoid that internal
sort; callers still use SQL `ORDER BY` when they need ordered results.

The default metadata path evaluates typed expressions through DuckDB. PostgreSQL
uses its existing transaction-preserving remote-query path and inline value
encoding. Temporal bounds use the metadata manager's directly typed comparison
literals, so PostgreSQL can parse them once instead of casting text for every row.
This supports booleans, signed and unsigned
integers, wide integers, decimals, floats, doubles, strings, blobs, dates and
microsecond-or-coarser timestamps, including timestamps with time zones. String
and blob comparisons use their binary storage; floating constants retain their
precision and infinity sign.

PostgreSQL stores temporal values as text because DuckDB's date and timestamp
ranges are wider. When the scan's table statistics prove both bounds fit the
backend range, a `CASE` only checks snapshot visibility before casting: expired
rows need not fit current bounds. Otherwise a guarded `CASE` casts only finite AD values with four-digit years, retaining other values
for DuckDB's residual evaluation. The reader uses DuckLake's existing snapshot
and transaction-local statistics checks; current bounds cannot certify an older
snapshot or a differently typed column. This uses the
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
PostgreSQL comparison type mapping and `CastValueToTarget` used for statistics. PostgreSQL SQL
executes through `postgres_query`, leaving its execution to that storage engine.

Every backend translation has two correctness obligations. A visible row that
matches the original predicate after decoding must pass the pushed predicate;
returning extra rows is safe because DuckDB retains the complete local filter.
Casts must also be safe on physically retained, invisible rows: SQL does not
guarantee `WHERE` evaluation order. The temporal `CASE` supplies that safety
boundary using the same visibility expression as the inline read.

## Execution placement and reuse

Correct results across catalog backends do not establish equivalent pushdown or
performance. The execution paths are:

| Catalog | Predicate execution | Evidence required for backend performance claims |
| --- | --- | --- |
| Native DuckDB | Typed predicate in the DuckDB metadata query. | Profile the metadata scan and compare selective and broad cases. |
| PostgreSQL | Storage-aware remote predicate through `postgres_query`, using the existing transaction. | Inspect the remote SQL and measure rows transferred, decoding and query time. |
| SQLite | Typed expression through DuckDB's attached-table scan. The pinned SQLite scanner supports projection pushdown, but does not enable engine filter pushdown. | Passing result tests does not demonstrate SQLite-engine filtering; a native optimization would need a mechanism check and measurements. |
| Quack | The metadata manager sends DuckDB SQL to remote DuckDB through `quack_query_by_name`. | Catalog correctness coverage does not establish performance; no Quack speedup is claimed here. |

Additional backend optimizations should reuse the correctness fixtures and
include a mechanism check showing where filtering occurs. Measure rows fetched
or materialized and broad controls as well as latency. Each backend must
establish comparison equivalence for its storage encoding: SQLite, for example,
stores floats as text to preserve NaN, so PostgreSQL's casts cannot be reused
without that analysis.

DuckDB's `database-connector` provides a shared `FilterPushdown` implementation,
but at revision `73d27b75117ca9f3134a7c9badd6c8a97998f2bd` its configuration lacks
arbitrary constant encoding and storage-aware leaf translation. DuckLake needs
binary string encoding, logical FLOAT normalization and guarded text-to-temporal
comparisons. That revision also omits unsupported `OR` children and loses the
sign of negative DOUBLE infinity; a local residual cannot recover discarded
rows. The scanner's private connector object target is not a public DuckLake API.

The current small formatter stays within the existing metadata-manager boundary.
A shared follow-up can start from the connector's `TransformFilterExpression`
entry point, add caller-supplied constant encoding and only the leaf hook these
cases require, and validate conservative composition and non-finite values
through an existing scanner and DuckLake. Storage casts and temporal guards
remain with the backend caller. This follows the maintainer's preference for
[caller-side configuration](https://github.com/duckdb/database-connector/issues/23#issuecomment-4994310521)
instead of a dialect hierarchy. A direct source dependency needs a separate
build decision; this cross-repository work is not required by the current patch.

DuckDB's `RemotePushdownOptimizer` and catalog capability interfaces are a future
direction for broader remote subqueries or aggregates. They do not supply
DuckLake's storage decoding or snapshot semantics. The pinned bound-expression
SQL exporter also rejects ordinary physical scan references and reconstructs
DuckDB expressions, so it is not a replacement for storage-aware translation.
