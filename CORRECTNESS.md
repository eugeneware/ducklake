# Corrected-head local validation

These results apply to **c970d6284e7d79e0ea4b451d48d30b2281ee3261**. See [the architecture follow-up](ARCHITECTURE.md) for the current revision.

Source: `c970d6284e7d79e0ea4b451d48d30b2281ee3261`; Clang 20 MinSizeRel (`-O1 -DNDEBUG`).

| Scope | Passed | SQL assertions | Skips |
|---|---:|---:|---|
| Seven focused fixtures × six configurations | 42 invocations | 2,916 | 0 |
| Expanded legacy FLOAT fixture, PostgreSQL | 1 test | 26 | 0 |
| stats-native | 51 tests | 1263 | 0 dependency skips; 0 skipped statements |
| stats-postgres | 50 tests | 1199 | 0 dependency skips; 0 skipped statements |
| related-native | 216 tests | 4413 | 7 dependency skips; 4 skipped statements |
| related-postgres | 214 tests | 4393 | 7 dependency skips; 4 skipped statements |

The focused configurations are native DuckDB, SQLite, PostgreSQL, DuckLake 1.0 compatibility, deletion vectors, and PostgreSQL with DuckLake 1.0 compatibility. The literal-placeholder fixture explicitly uses native metadata in every configuration. Counts describe executions, not unique non-overlapping tests.

Each related suite skips six httpfs cases and one spatial case because those extensions are absent from the local build. PostgreSQL statistics excludes one native-only test through its standard configuration; it has no runtime skips. The existing GitHub CI covers additional builds and dependency configurations.

The same legacy fixture passes 26 assertions on the feature-off base, fails after 13 passing assertions on the reviewed head, and passes all 26 on the corrected head. The failure is the expected wrong equality result, not a setup failure. See the three `review-r1-*.log` files.

Formatting and `git diff --check` passed. The build manifest verifies the SHA-256 of all 47 changed source files against the committed worktree.
