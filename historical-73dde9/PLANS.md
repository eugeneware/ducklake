Execution plans captured separately from the latency and CPU runs.

The `expanded` filename label denotes the final refined binary in this run.

| Query / binary | Remote output rows | Plan nodes | Server execution ms |
|---|---:|---|---:|
| source_timestamp_count-expanded | 20 | Gather, Seq Scan | 21.987 |
| source_timestamp_count-integer | 1000 | Sort, Seq Scan | 26.131 |
| timestamp-expanded | 2160 | Seq Scan | 101.578 |
| timestamptz_broad-expanded | 90000 | Seq Scan | 71.104 |

The final ordinary remote reads have no sort node. Their filters contain the snapshot CASE and directly typed timestamp bounds. The source/time COUNT transfers 20 rows instead of 1,000 with the integer-only prototype; aggregation remains local. PostgreSQL still uses a sequential scan, not a newly added index.

The integer-only build cannot push a standalone temporal predicate, so those cases have no postgres_query statement for this helper to EXPLAIN. That is why their integer-plan files are absent. The complete generated catalog queries are retained in the matching *-queries.json files.

These one-shot server EXPLAIN times exclude the rest of the DuckDB query and transport path; use TIMINGS.md for paired end-to-end medians.
