# Architecture follow-up: bd815213

Source: `bd815213f32bb7d8750c1a0a0f69b17a8eba8874`. This follows the first review corrections at `c970d628`; those earlier measurements remain separately labelled.

## Changes

- AD-04: explicit storage-column / logical-output contracts and a matching-vector assertion, preserving the existing query and decoding boundaries.
- AD-05: one internal snapshot-visibility expression serves both the row query and temporal CASE; the CASE evaluation barrier remains.
- AD-06: the existing temporal fixture now verifies a physically retained expired BC timestamp, narrow current bounds, visible results and the selected snapshot CASE. Deleting an outlier is not assumed to narrow statistics.
- Portability: the benchmark guide documents both correctness obligations, execution placement for all four metadata backends, and the connector reuse boundary and maintainer-guided follow-up.

## Local correctness

| Scope | Passed | SQL assertions | Skips |
|---|---:|---:|---|
| Seven focused fixtures × six configurations | 42 invocations | 2,940 | 0 |
| Expanded legacy FLOAT fixture, PostgreSQL | 1 test | 26 | 0 |
| stats-native | 51 tests | 1263 | 0 dependency skips; 0 skipped statements |
| stats-postgres | 50 tests | 1199 | 0 dependency skips; 0 skipped statements |
| related-native | 216 tests | 4413 | 7 dependency skips; 4 skipped statements |
| related-postgres | 214 tests | 4393 | 7 dependency skips; 4 skipped statements |

Configurations are native DuckDB, SQLite, PostgreSQL, native/PostgreSQL DuckLake 1.0 compatibility, and deletion vectors. The literal-placeholder fixture deliberately uses native metadata in every configuration. Counts describe executions and overlap; they are not unique test totals.

Each related suite skips six httpfs cases and one spatial case because those extensions are absent locally. PostgreSQL statistics excludes one native-only case through its standard configuration. Full hosted CI remains separate from these selected local runs.

The expanded AD-06 fixture also passes all 27 assertions on the preceding c970d628 PostgreSQL binary, before the visibility helper extraction. It closes a validation gap rather than demonstrating a new bug fix. The R1 baseline-pass / reviewed-head-fail / fixed-head-pass evidence remains in [the first review report](CORRECTNESS.md).

Formatting and `git diff --check` passed. All 47 files changed against the base match the tested source hashes in the [build manifest](results/architecture-build-manifest.json). Raw SQLLogicTest logs and event summaries use the `architecture-` prefix in `results/`.

## Final-head Release measurements

Feature-off base `b6f14fe6` versus `bd815213`, matching Clang 20.1.8 Release builds (`-O3 -DNDEBUG`), PostgreSQL 17.11, 100,000 fully inlined rows, two client threads and a 3 GB limit. Twenty samples per binary/case. Setup, native result-oracle checks and warmup are outside CPU timing. The existing regression harness also verifies query results outside its timer. No builds or correctness suites ran alongside these measurements.

CPU is client user + system time, excluding PostgreSQL server CPU. Latency and CPU columns are separate matching runs; the CLI wall column comes from the CPU run.

| Query | Base → head latency ms | Change | Base → head client CPU ms | Change | CLI wall change |
|---|---:|---:|---:|---:|---:|
| integer_wide | 358.21 → 41.12 | -88.5% | 310.30 → 24.07 | -92.2% | -88.7% |
| float | 173.78 → 33.97 | -80.5% | 98.56 → 13.86 | -85.9% | -81.1% |
| varchar | 178.69 → 36.52 | -79.6% | 115.44 → 13.08 | -88.7% | -80.6% |
| timestamp | 177.01 → 101.65 | -42.6% | 98.04 → 18.75 | -80.9% | -36.9% |
| source_timestamp_count | 115.90 → 75.99 | -34.4% | 92.74 → 51.15 | -44.8% | -38.6% |
| date_broad | 191.75 → 191.45 | -0.2% | 113.61 → 93.02 | -18.1% | -2.4% |
| timestamptz_broad | 192.21 → 197.30 | +2.6% | 120.28 → 110.24 | -8.3% | +0.0% |
| full_scan | 182.05 → 165.84 | -8.9% | 108.73 → 91.21 | -16.1% | -8.2% |

All eight latency cases passed the unchanged 10% regression gate. Both binaries passed the native result oracle for every CPU case. Raw [CPU samples](results/architecture-release-cpu-off-on/samples.json), [CPU commands and binary hashes](results/architecture-release-cpu-off-on/invocation.json), [latency samples](results/architecture-release-latency-off-on.json) and [verbose latency log](results/architecture-release-latency-off-on.log) are retained.

Run-to-run variation is visible in broad queries. The earlier c970d628 Release run showed +4.8% broad TIMESTAMPTZ harness latency and +6.8% CLI wall time; those results remain in [the prior report](CPU.md). The historical integer-prototype → 73dde9 wide-ID CPU cost (+17.9%, +3.66 ms) and source/time COUNT latency cost (+7.4%) also remain visible. These measurements do not claim universal gains, metadata-server CPU savings or production collector performance.

## Effect of the architecture follow-up alone

`c970d628` → `bd815213`, matching Clang 20.1.8 MinSizeRel C++ `-O1 -DNDEBUG` builds. These are not Release measurements. The full 27-case comparison passed the unchanged regression gate, with 20 samples per binary/case.

| Query | c970d628 ms | bd815213 ms | Change |
|---|---:|---:|---:|
| integer_point | 30.01 | 30.50 | +1.6% |
| integer_wide | 40.21 | 40.64 | +1.1% |
| integer_range | 30.65 | 33.50 | +9.3% |
| integer_in | 35.25 | 35.48 | +0.6% |
| integer_missing | 2.59 | 2.56 | -1.3% |
| integer_null | 33.54 | 35.11 | +4.7% |
| integer_broad | 143.37 | 140.47 | -2.0% |
| integer_source | 36.14 | 37.07 | +2.6% |
| boolean | 34.77 | 37.55 | +8.0% |
| decimal | 39.45 | 39.04 | -1.0% |
| float | 35.66 | 35.68 | +0.1% |
| double | 34.56 | 35.92 | +3.9% |
| varchar | 42.20 | 38.51 | -8.7% |
| varchar_broad | 159.75 | 160.26 | +0.3% |
| blob | 35.90 | 38.09 | +6.1% |
| date | 73.66 | 75.03 | +1.9% |
| date_broad | 183.89 | 191.01 | +3.9% |
| timestamp | 107.24 | 102.53 | -4.4% |
| timestamptz | 111.89 | 107.97 | -3.5% |
| timestamptz_broad | 195.32 | 195.46 | +0.1% |
| source_timestamp | 37.16 | 39.50 | +6.3% |
| residual_and | 31.75 | 31.80 | +0.2% |
| residual_or | 151.06 | 151.24 | +0.1% |
| nested | 178.95 | 179.48 | +0.3% |
| runtime_join | 153.43 | 150.86 | -1.7% |
| full_scan | 164.65 | 165.34 | +0.4% |
| source_timestamp_count | 72.45 | 71.60 | -1.2% |

Geometric mean change: **+0.9%**. Small individual changes remain visible rather than being described as universal improvements. See [all samples](results/architecture-latency-incremental.json) and the [raw runner output](results/architecture-latency-incremental.log).

## Reproduce

Use the portable `cpu.py` instructions in [README.md](README.md), substituting the current head and the feature-off base. `architecture-performance.sh` records the exact three invocations used here; its `/job` paths name retained build roots, not required installation locations. The scripts reuse the existing DuckLake/DuckDB benchmark harness and CLI timer. `architecture-summarize.py` only decodes the retained fixed-sample ABBA log blocks; it does not run benchmarks or decide pass/fail.

The [manifest](results/architecture-build-manifest.json), [source hashes](architecture-source-sha256.json), and `builds/architecture-*` CMake caches and compile commands identify both current builds. Earlier baseline build commands and source validation remain in the first-review evidence. PostgreSQL server CPU, production collector performance and Quack performance remain unmeasured.
