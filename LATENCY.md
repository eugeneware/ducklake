# MinSizeRel latency matrix: feature-off base → corrected head

100,000 rows, 20 samples per binary/case, matching Clang 20 `-O1 -DNDEBUG` builds. The unchanged harness passed all 27 cases. Raw runner samples and verdicts are retained in the adjacent JSON and log files.

| Query | Base ms | Corrected ms | Change in medians |
|---|---:|---:|---:|
| integer_point | 74.09 | 29.97 | -59.5% |
| integer_wide | 361.86 | 42.89 | -88.1% |
| integer_range | 168.38 | 30.95 | -81.6% |
| integer_in | 171.09 | 34.37 | -79.9% |
| integer_missing | 2.60 | 2.61 | +0.3% |
| integer_null | 175.69 | 35.40 | -79.9% |
| integer_broad | 180.60 | 140.11 | -22.4% |
| integer_source | 180.71 | 36.77 | -79.7% |
| boolean | 178.49 | 38.41 | -78.5% |
| decimal | 170.64 | 38.19 | -77.6% |
| float | 168.59 | 36.22 | -78.5% |
| double | 176.58 | 34.28 | -80.6% |
| varchar | 173.80 | 38.94 | -77.6% |
| varchar_broad | 194.29 | 159.29 | -18.0% |
| blob | 176.25 | 42.29 | -76.0% |
| date | 180.32 | 75.11 | -58.3% |
| date_broad | 193.93 | 196.23 | +1.2% |
| timestamp | 180.91 | 105.13 | -41.9% |
| timestamptz | 181.77 | 111.01 | -38.9% |
| timestamptz_broad | 191.35 | 203.45 | +6.3% |
| source_timestamp | 186.74 | 39.45 | -78.9% |
| residual_and | 171.13 | 32.52 | -81.0% |
| residual_or | 166.28 | 152.70 | -8.2% |
| nested | 198.64 | 187.59 | -5.6% |
| runtime_join | 167.04 | 146.97 | -12.0% |
| full_scan | 183.87 | 166.80 | -9.3% |
| source_timestamp_count | 115.60 | 72.63 | -37.2% |

## Effect of the review fixes alone

Reviewed head `73dde9e2` → corrected head `c970d628`, same `-O1` build settings and 20 samples per binary/case. The unchanged harness passed all 27 cases; geometric-mean latency changed +0.2%. Small-query costs remain visible below.

| Query | Reviewed ms | Corrected ms | Change in medians |
|---|---:|---:|---:|
| integer_point | 30.97 | 30.72 | -0.8% |
| integer_wide | 39.65 | 40.16 | +1.3% |
| integer_range | 30.70 | 31.45 | +2.4% |
| integer_in | 33.26 | 32.71 | -1.6% |
| integer_missing | 2.64 | 2.59 | -1.8% |
| integer_null | 34.76 | 35.32 | +1.6% |
| integer_broad | 138.61 | 142.76 | +3.0% |
| integer_source | 36.28 | 37.49 | +3.3% |
| boolean | 37.12 | 37.47 | +0.9% |
| decimal | 38.45 | 40.00 | +4.0% |
| float | 35.80 | 38.34 | +7.1% |
| double | 34.85 | 35.39 | +1.5% |
| varchar | 42.16 | 38.59 | -8.5% |
| varchar_broad | 160.50 | 163.05 | +1.6% |
| blob | 38.95 | 39.01 | +0.1% |
| date | 77.10 | 78.18 | +1.4% |
| date_broad | 191.31 | 193.61 | +1.2% |
| timestamp | 109.70 | 106.90 | -2.6% |
| timestamptz | 116.99 | 112.96 | -3.4% |
| timestamptz_broad | 197.11 | 193.86 | -1.7% |
| source_timestamp | 39.63 | 38.66 | -2.5% |
| residual_and | 32.38 | 31.86 | -1.6% |
| residual_or | 151.83 | 152.33 | +0.3% |
| nested | 181.02 | 178.96 | -1.1% |
| runtime_join | 149.30 | 152.11 | +1.9% |
| full_scan | 167.17 | 167.26 | +0.1% |
| source_timestamp_count | 73.07 | 72.51 | -0.8% |

## Normal Release confirmation

Same source pins and fixture, fresh matching Clang 20 Release `-O3 -DNDEBUG` builds, 20 samples per binary/case. All eight representative cases passed the unchanged gate. Broad timestamp latency increased 4.8%; this cost remains part of the evidence.

| Query | Feature-off ms | Corrected ms | Change in medians |
|---|---:|---:|---:|
| integer_wide | 368.50 | 40.99 | -88.9% |
| float | 172.68 | 38.35 | -77.8% |
| varchar | 181.62 | 39.93 | -78.0% |
| timestamp | 177.94 | 103.64 | -41.8% |
| source_timestamp_count | 113.01 | 76.64 | -32.2% |
| date_broad | 196.18 | 192.83 | -1.7% |
| timestamptz_broad | 195.45 | 204.82 | +4.8% |
| full_scan | 182.84 | 163.05 | -10.8% |
