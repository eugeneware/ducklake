DuckDB client CPU only (user + system); excludes PostgreSQL server CPU.

Integer-only prototype → final candidate, 100,000 rows, 10 samples per variant.

| Query | Before CPU ms | After CPU ms | CPU change |
|---|---:|---:|---:|
| integer_wide | 20.82 | 23.21 | +11.5% |
| boolean | 101.85 | 16.00 | -84.3% |
| decimal | 134.31 | 15.61 | -88.4% |
| float | 93.14 | 14.25 | -84.7% |
| double | 103.41 | 13.80 | -86.7% |
| varchar | 110.81 | 11.30 | -89.8% |
| blob | 108.62 | 15.18 | -86.0% |
| date | 108.66 | 19.55 | -82.0% |
| timestamp | 99.90 | 19.54 | -80.4% |
| timestamptz | 103.38 | 20.50 | -80.2% |
| source_timestamp_count | 48.29 | 51.86 | +7.4% |
| date_broad | 112.49 | 109.20 | -2.9% |
| timestamptz_broad | 111.28 | 104.21 | -6.4% |
| full_scan | 105.35 | 101.75 | -3.4% |

A separate confirmation used 20 samples per variant for two small queries; both the initial and confirmation runs are retained.

| Query | Before CPU ms | After CPU ms | CPU change | Wall ms before → after |
|---|---:|---:|---:|---:|
| integer_wide | 20.39 | 24.05 | +17.9% | 35.50 → 37.50 |
| source_timestamp_count | 50.00 | 51.34 | +2.7% | 65.00 → 70.00 |
