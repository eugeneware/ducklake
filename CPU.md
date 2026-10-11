# Client CPU: feature-off base → corrected head

These results apply to **c970d6284e7d79e0ea4b451d48d30b2281ee3261**. See [the architecture follow-up](ARCHITECTURE.md) for the current revision.

Clang 20.1.8, matching MinSizeRel `-O1 -DNDEBUG` C++ builds. 100,000 rows; two threads; 3 GB memory. Twenty CLI timer samples per binary and query. These are **not Release measurements**.

CPU is DuckDB client user + system time; PostgreSQL server CPU is unmeasured. Wall times here come from the same CLI runs, separately from the regression runner’s latency matrix.

| Query | Base CPU ms | Fixed CPU ms | CPU change | Base wall ms | Fixed wall ms | Wall change |
|---|---:|---:|---:|---:|---:|---:|
| integer_wide | 321.83 | 23.85 | -92.6% | 339.50 | 39.00 | -88.5% |
| float | 97.17 | 14.28 | -85.3% | 156.00 | 30.00 | -80.8% |
| varchar | 102.43 | 15.21 | -85.2% | 161.50 | 32.50 | -79.9% |
| timestamp | 108.85 | 19.33 | -82.2% | 161.00 | 101.50 | -37.0% |
| source_timestamp_count | 99.54 | 50.14 | -49.6% | 115.50 | 71.50 | -38.1% |
| date_broad | 110.94 | 106.93 | -3.6% | 167.00 | 169.50 | +1.5% |
| timestamptz_broad | 119.56 | 104.29 | -12.8% | 167.50 | 172.00 | +2.7% |
| full_scan | 111.39 | 88.42 | -20.6% | 161.50 | 142.00 | -12.1% |

Selective CPU falls substantially. The broad date and timestamp-with-time-zone controls have small wall-time increases even though client CPU falls. This is consistent with remote predicate work and is not a universal speedup claim.

Both binaries passed the existing result oracle for all eight queries before timing. See [raw samples](results/review-cpu-off-on/samples.json), [commands and binary hashes](results/review-cpu-off-on/invocation.json), and the saved per-block SQL/plan/timer and per-binary verification logs in that directory.

The historical integer-prototype → reviewed-head wide-ID CPU increase (+17.9%, +3.66 ms) and source/time COUNT latency increase (+7.4%) remain recorded in [the historical report](historical-73dde9/CPU.md) and the main README. The full feature-off comparison above does not remove those incremental tradeoffs.

## Normal Release confirmation

Fresh matching Clang 20.1.8 Release (`-O3 -DNDEBUG`) builds of the same feature-off base and corrected head. The same eight cases, native result oracles, threads, memory, ABBA order and 20 samples per binary/case are used. This is a separate measurement, not an extrapolation from `-O1`.

| Query | Base CPU ms | Fixed CPU ms | CPU change | Base wall ms | Fixed wall ms | Wall change |
|---|---:|---:|---:|---:|---:|---:|
| integer_wide | 311.08 | 24.22 | -92.2% | 329.00 | 37.00 | -88.8% |
| float | 100.24 | 14.66 | -85.4% | 153.00 | 31.00 | -79.7% |
| varchar | 97.18 | 15.29 | -84.3% | 155.50 | 34.00 | -78.1% |
| timestamp | 101.40 | 18.40 | -81.9% | 159.50 | 103.00 | -35.4% |
| source_timestamp_count | 89.83 | 51.97 | -42.2% | 113.00 | 71.00 | -37.2% |
| date_broad | 109.68 | 106.54 | -2.9% | 163.50 | 164.50 | +0.6% |
| timestamptz_broad | 113.06 | 109.76 | -2.9% | 162.00 | 173.00 | +6.8% |
| full_scan | 105.08 | 94.05 | -10.5% | 156.00 | 142.00 | -9.0% |

The broad timestamp-with-time-zone control shows a **+6.8% CLI wall-time cost** in this Release run, despite about 2.9% lower client CPU. PostgreSQL server CPU remains unmeasured. See the separate latency harness confirmation, raw samples and logs; these results do not imply that every query benefits.

Release [samples](results/review-release-cpu-off-on/samples.json), [invocation](results/review-release-cpu-off-on/invocation.json), and [source/build/binary manifest](results/review-release-build-manifest.json) are retained. The Release fixture/oracle checks passed for both binaries on every case.
