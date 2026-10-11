# Hosted CI on the final source

Source: `bd815213f32bb7d8750c1a0a0f69b17a8eba8874`. All nine pull-request workflows completed successfully. These results supplement the [local correctness and performance report](ARCHITECTURE.md).

| Workflow | Result | Run |
|---|---|---|
| Config Tests | Passed | [GitHub Actions](https://github.com/eugeneware/ducklake/actions/runs/38115315800) |
| DBMS Catalog Tests | Passed | [GitHub Actions](https://github.com/eugeneware/ducklake/actions/runs/38115315783) |
| Deletion Vector Tests | Passed | [GitHub Actions](https://github.com/eugeneware/ducklake/actions/runs/38115315839) |
| DuckLake Backwards Compatibility Tests | Passed | [GitHub Actions](https://github.com/eugeneware/ducklake/actions/runs/38115315820) |
| Format Check | Passed | [GitHub Actions](https://github.com/eugeneware/ducklake/actions/runs/38115315790) |
| Main Extension Distribution Pipeline | Passed | [GitHub Actions](https://github.com/eugeneware/ducklake/actions/runs/38115316144) |
| No Inline Tests | Passed | [GitHub Actions](https://github.com/eugeneware/ducklake/actions/runs/38115315786) |
| Regression | Passed | [GitHub Actions](https://github.com/eugeneware/ducklake/actions/runs/38115315785) |
| SeaweedFS Tests | Passed | [GitHub Actions](https://github.com/eugeneware/ducklake/actions/runs/38115315865) |

## Platform and storage coverage

The distribution pipeline passed GCC 12 compilation, all four Linux architecture/libc combinations, both macOS architectures, Windows MSVC and MinGW, three WebAssembly variants, and the relassert job with ASan, UBSan, leak checking and forced assertions. Catalog CI passed native DuckDB, Quack, SQLite and PostgreSQL. The no-inline, deletion-vector, backwards-compatibility and SeaweedFS workflows also passed.

These are configured CI results, with job and step statuses retained in the `results/ci-*-jobs.json` API snapshots. They do not imply that every platform runs every backend fixture. Separate push and pull-request workflows repeat configurations; their job counts are not distinct test coverage.

## Full benchmark CI

Both benchmark jobs actually concluded **success**, including the PostgreSQL job whose workflow configuration is informational. This conclusion is based on each job result, rather than only the overall workflow status.

Each catalog ran 84 unique benchmark cases from the full `micro.csv` suite with its configured fixtures. Both reported no query regressions under the existing harness. These are wall-time measurements, separate from the fixed-sample local Release CPU measurements.

| Catalog | Cases | Reported base → head geometric mean | Change | Raw benchmark output |
|---|---:|---:|---:|---|
| Native DuckDB | 84 | 203.0 → 169.2 ms | -16.6% | [Log](results/ci-native-benchmark.log) |
| PostgreSQL | 84 | 343.3 → 247.5 ms | -27.9% | [Log](results/ci-postgres-benchmark.log) |

The CI harness uses adaptive sampling; its reported geometric mean uses the initial ten samples. The retained logs include individual timings and subsequent confirmations. These overall gains do not remove the individual costs in the local reports, and do not measure PostgreSQL server CPU or production ingestion performance.

## Independent review

The [follow-up review](https://github.com/eugeneware/ducklake/pull/1#pullrequestreview-5482149337) confirmed that R1/R2/R3, AD-04/05/06 and the portability documentation requests were addressed. It reports an independent rerun of seven targeted invocations (188 assertions), source/binary hash checks and reconciliation of the raw performance samples. Its remaining R4 condition was completion of the relevant CI, whose results are recorded above.

## Snapshot scope

The duplicate push workflows also completed successfully on the same source. Their outcomes are retained in the workflow snapshot and the separate push-platform job snapshot; repeated jobs are not counted as additional configurations.

[Workflow API snapshot](results/ci-workflows-bd815213.json). Raw benchmark segments were downloaded through the completed job-log API; build and cache setup output was omitted from these benchmark-only log files.
