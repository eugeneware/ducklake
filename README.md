# DuckLake inline-filter PR 1: review evidence

Evidence for [eugeneware/ducklake#1](https://github.com/eugeneware/ducklake/pull/1),
current source `bd815213f32bb7d8750c1a0a0f69b17a8eba8874`. The first review-pass results for `c970d628` are retained with their original source labels.
This branch contains reproducibility artifacts, separate from the implementation series.

## Results

- [Current architecture follow-up](ARCHITECTURE.md): contracts, expired-row regression, exact-head correctness and performance evidence.

- [First review correctness, c970d628](CORRECTNESS.md): the legacy regression's baseline-pass/old-head-fail/fixed-head-pass sequence, 42 focused invocations, and the native/PostgreSQL statistics and related suites.
- [First review CPU, c970d628](CPU.md): feature-off versus corrected head, 20 samples per binary/case, with separate `-O1` and normal Release `-O3` measurements and raw logs.
- [First review latency, c970d628](LATENCY.md): both complete 27-case `-O1` comparisons passed the unchanged gate, as did the eight-case Release confirmation. Costs, including the broad timestamp regression, remain visible.
- [MinSizeRel manifest](results/review-build-manifest.json) and [Release manifest](results/review-release-build-manifest.json): source pins, exact flags, source/binary hashes and measurement settings.

Full GitHub Actions status is tracked on the PR. These local results do not waive
the catalog, sanitizer or platform jobs that are still running.

## Source and measurement boundaries

- Feature-off DuckLake base: `b6f14fe678b80905e1ab86d3df26e4a5fe2f15b1`.
- Reviewed head before these fixes: `73dde9e279a56cdb7034fb82c0cef023f5689446`.
- First review corrections: `c970d6284e7d79e0ea4b451d48d30b2281ee3261`.
- Current architecture follow-up: `bd815213f32bb7d8750c1a0a0f69b17a8eba8874`.
- Historical integer-only prototype: `7d1d8df7175421bec7893a9d919027accab8b851`.
- DuckDB: `5070de3585e846718fac121b5b149f4236e6a58a` (`v2.0.0-dev0`).
- PostgreSQL 17.11; scanner pins and binary/source hashes are in the build manifests.

The retained experimental build trees contain base/placeholder embedded version
strings. Source pins and verified file/binary hashes identify the tested code;
the embedded extension version alone does not. All 47 changed candidate files
match the committed head, and all 134 baseline `src/` files were checked against
the archived base before Release comparison.

The synthetic fixture has 100,000 inline rows, 15 columns and a 256-byte payload,
with no added indexes. DuckDB uses two threads and a 3 GB query memory limit.
The existing fixture verifies that no Parquet files were created. Fixture
construction, result verification, plans, connection setup and warmup are outside
the CPU timer. The latency harness likewise excludes fixture construction and
checks its result against a native DuckDB reference using both directions of
`EXCEPT ALL`.

CPU means the DuckDB CLI process's user plus system time, including its threads.
It excludes PostgreSQL server CPU. Wall time includes the query's remote work.
These are synthetic client measurements; no production collector measurements
or claims are made. PostgreSQL can still perform sequential scans.

## Reproduce client CPU

Build both revisions with the same DuckDB revision, compiler, optimization flags
and extensions. The candidate checkout supplies the shared fixtures and existing
regression helpers. The implementation has no feature switch: the base binary is
the feature-off control.

The committed benchmark guide describes building the runners with
`BUILD_BENCHMARK=1 ENABLE_POSTGRES_SCANNER=1 make release`. For the measured
MinSizeRel builds, the manifests and saved CMake cache/compile commands specify
Clang 20.1.8 and `-O1 -DNDEBUG` for C++. These results must not be presented as
normal Release results. The separate Release measurements use `-O3 -DNDEBUG`;
their build commands and hashes are recorded separately.

Install PostgreSQL's client tools and set the standard `PGHOST`, `PGPORT`,
`PGUSER`, and `PGPASSWORD` variables for a disposable server with permission to
create databases. Keep other benchmarks and builds off the measurement machine.
Run from any directory:

```sh
python3 cpu.py \
  --source /path/to/corrected/ducklake \
  --old /path/to/base/build/release \
  --new /path/to/corrected/build/release \
  --output /path/to/new-results-directory \
  --threads 2 --memory 3GB --rows 100000
```

The output directory must not already exist. Each build directory must contain
`duckdb`, `src/libduckdb.so`, `benchmark/benchmark_runner`, and its matching
`repository/<DuckDB version>/<platform>/postgres_scanner.duckdb_extension`, as
used by the existing regression harness. The build commands must produce the CLI
as well as the runner. The captured builds statically link DuckLake.

`cpu.py` reuses `.github/regression/catalog.py` and `run.py` for fixture rendering,
database lifetime and extension discovery. For each of eight representative
cases, **both** binaries first run the existing benchmark and result oracle.
It then uses the CLI's `.timer` counters, with one warmup per process and two
ABBA blocks of five queries each: 20 measured samples per binary and case.
Saved SQL, plans, verification logs, raw counters, medians, binary hashes and
commands make the measurement auditable. It drops only its uniquely named
temporary database. No benchmark framework or runtime configuration is added
to DuckLake.

## Reproduce latency

Use the existing candidate checkout and harness:

```sh
python3 .github/regression/run.py \
  --catalog postgres \
  --old /path/to/base/build/release/benchmark/benchmark_runner \
  --new /path/to/corrected/build/release/benchmark/benchmark_runner \
  --benchmarks .github/regression/inlined_filters.csv \
  --threads 2 --samples 20 --memory-limit 3GB
```

The same invocation with the reviewed head as `--old` isolates the two review
fixes. The standard harness's 10% threshold and confirmation rerun are unchanged.
Retained runner binaries have statically linked implementations: pointing an old
runner at a new `libduckdb.so` does not update its DuckLake implementation.

## Historical tradeoffs remain relevant

`historical-73dde9/` preserves the previously reported measurements and raw
samples. These compare the integer prototype with the **old reviewed head**,
not the corrected head. The wide-ID CPU confirmation was **20.39 → 24.05 ms
(+17.9%, +3.66 ms)**. The paired latency change was +6.7%. The source/time COUNT
latency matrix measured **69.47 → 74.58 ms (+7.4%)** against the integer
prototype, despite fewer remotely returned rows. Its separate CPU confirmation
was 50.00 → 51.34 ms (+2.7%). These incremental tradeoffs must not be hidden by
the larger improvement against the entirely feature-off base.

## Correctness and CI

The expanded existing legacy PostgreSQL FLOAT fixture passes 26 assertions on
the feature-off base, fails at equality on the reviewed head, and passes all 26
on the corrected head. The correction compares the physical column in its
logical type before applying a predicate. Separate shared conjunction formatting
retains conservative AND/OR behavior without combining row and statistics leaf
semantics.

Test logs and summaries distinguish executed tests from dependency skips. Local
selected suites supplement the existing GitHub Actions platform and catalog
checks; they do not replace them. CI run links and their observed status are
recorded with the final evidence summary.
