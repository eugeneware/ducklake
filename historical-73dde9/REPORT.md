The refined scalar inline-predicate candidate passes the correctness and performance gates used here, including the broad temporal cases that regressed in the preceding candidate. The complete 27-case matrix passed for native integer-only → final, PostgreSQL integer-only → final, and PostgreSQL feature-off → final. These are isolated, pinned-build measurements, not a production rollout or a guarantee for all workloads.

Commit: `73dde9e279a56cdb7034fb82c0cef023f5689446` on `perf/inline-integer-filter-pushdown`. The complete four-commit series is now pushed to `eugeneware/ducklake` and published as [fork-local draft PR #1](https://github.com/eugeneware/ducklake/pull/1) for independent review. Its base branch, `review/inline-pushdown-base`, is the exact tested base revision. The PR is linked to this T3 thread. Production has not been modified.

The implementation reuses DuckDB expression/comparison helpers and DuckLake's existing metadata-manager boundary, backend encoders, typed constant conversion, statistics cache and transaction-preserving query execution. The reader contains no PostgreSQL type rules. No catalog migration, index, new library or runtime setting is introduced. See [the reuse review](../expanded/REUSE-REVIEW.md).

The refinement removes two avoidable costs: temporal constants cast through VARCHAR at execution time, and unconditional row-ID sorting. Pending-deletion merges still request sorted row IDs. PostgreSQL can also replace per-row string range checks with a snapshot-visibility CASE when existing statistics prove the visible values fit its temporal range. Historical snapshots, transaction-local changes, unknown bounds and unsupported types retain conservative evaluation. Expired physical rows are explicitly protected from unsafe casts; an outer WHERE clause alone is not relied on for evaluation order.

The complete DuckDB predicate remains as a residual. PostgreSQL nanosecond timestamps, collations, aliases, nested paths, schema-evolution casts and arbitrary functions retain local evaluation. This is predicate pushdown, not aggregate pushdown, runtime join-filter pushdown or indexed point reads. PostgreSQL may still scan its inline relation sequentially.

## Correctness and contributor conventions

- All 42 focused invocations passed: 2,916 assertions across native DuckDB, SQLite, native catalog v1.0, deletion vectors, PostgreSQL v1.1 and PostgreSQL v1.0. The literal-placeholder fixture intentionally uses native metadata and repeats that path across configurations.
- Selected related suites passed 216 native tests / 4,413 assertions and 214 PostgreSQL tests / 4,393 assertions. Each suite skipped seven httpfs/spatial-dependent tests and four statements. This is not the entire repository suite; Quack and other build configurations were not exercised.
- Tests cover scalar boundaries, NULLs, NaN/infinities, wide integers, binary strings, time zones, fallback conjunctions, snapshots, pending updates/deletes, rollback and flushing. Result multisets are compared with native reference tables. New mechanism checks fail on earlier binaries for the old temporal cast, unnecessary sort, missing statistics optimization and missing visibility CASE.
- The repository's `make format-fix` ran with clang-format 11 and `git diff --check` passed. Code follows the existing optional_ptr, metadata-manager and SQL-test conventions. [Validation details](validation.json), [review notes](REVIEW.md) and [decision log](DECISIONS.md) preserve scope and rejected approaches.

## Performance

Fixture: 100,000 entirely inlined rows, 15 columns, 256-byte payload, no added indexes; two DuckDB threads and a 3 GB query limit. Baseline and candidate use the same pinned compiler, DuckDB and extensions. Builds use Clang 20, MinSizeRel `-O1 -DNDEBUG`; these are not claimed to be `-O3` release measurements. The regression harness alternates five-run blocks, uses 20 samples per binary per case, checks result equality outside timing, and repeats apparent regressions without changing its 10% gate.

Representative PostgreSQL feature-off → final medians:

| Query | Before | After | Change |
|---|---:|---:|---:|
| integer_wide | 354.28 ms | 40.81 ms | -88.5% |
| decimal | 173.56 ms | 35.84 ms | -79.4% |
| varchar | 176.91 ms | 39.08 ms | -77.9% |
| date | 177.64 ms | 75.59 ms | -57.4% |
| timestamp | 178.52 ms | 104.22 ms | -41.6% |
| timestamptz | 179.15 ms | 111.43 ms | -37.8% |
| source_timestamp_count | 120.77 ms | 74.00 ms | -38.7% |
| date_broad | 189.48 ms | 191.20 ms | +0.9% |
| timestamptz_broad | 191.06 ms | 198.40 ms | +3.8% |
| full_scan | 186.29 ms | 164.56 ms | -11.7% |

For the incremental scalar comparison, broad DATE changed +1.1% and broad TIMESTAMPTZ +1.5%. The previous ~16% broad timestamp regression was not reproduced by the refined candidate.

Source-and-time COUNT remains a limit: integer-only → final measured 69.47 → 74.58 ms (+7.4%). Fewer transferred rows do not guarantee lower total latency when binding/catalog work dominates. Its feature-off improvement must not all be credited to the scalar expansion. The full [timing table](TIMINGS.md) and [all samples and confirmation rounds](timings.json) retain this result.

A repeated CPU check also found a small incremental cost in the already-optimized wide-ID lookup: 20.39 → 24.05 ms of client CPU (+17.9%, +3.66 ms). Its main latency comparison was +6.7%, within the unchanged latency gate. This cost is retained as a review tradeoff, not hidden by the large feature-off benefit. No claim is made that every query or CPU metric improves.

The separate [CPU measurements](CPU.md) use ten samples per variant and report DuckDB client user+system CPU only. They exclude PostgreSQL server CPU and are not an HN collector measurement. Execution plans and exact generated SQL are retained under `results/refinement-final-plan-*`; plan observations are recorded in [PLANS.md](PLANS.md).

## Reproduction and artifacts

[manifest.json](manifest.json) records commits and source hashes; [the environment file](results/refinement-final-environment.txt) records binary hashes and flags. [complete-series.patch](complete-series.patch) contains the complete change from the pinned DuckLake main base; [refinement.patch](refinement.patch) contains this refinement alone.

The source-control regression list and fixture are sufficient to run the normal upstream benchmark commands in `benchmark/micro/read/inlined_filters/README.md`. The retained build environment and service setup are in the parent evidence directories. [final-run.sh](final-run.sh), [qualification-final.sh](qualification-final.sh), [matrix.sh](matrix.sh), [cpu.py](cpu.py) and [final-plans.py](final-plans.py) record the exact qualification sequence with `/src` and `/job` mounts. Fixture loading and result verification are outside query timing. Temporary catalogs are unique and removed afterward.

Rejected experiments, expected red-test failures and superseded runs remain in `results/`; only filenames prefixed `refinement-final-`, the final matrix logs, v5 broad results and completed CPU results support the final conclusions. The pre-existing writer placeholder-substitution issue documented in the preceding report is outside this read-side change.

Cleanup completed: the test worker, PostgreSQL container, anonymous database volume and task network were removed after all test/benchmark processes exited. Before removal, PostgreSQL listed only its base `ducklakedb` and `postgres` databases. Source, binaries, scripts and evidence remain available; production services and data were not changed.
