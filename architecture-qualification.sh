#!/bin/bash
set -euo pipefail
cd /src
for config in native sqlite ducklake_version deletion_vectors postgres postgres-v10; do
  options=()
  if [ "$config" != native ]; then options=(--config "/job/$config.json"); fi
  for fixture in temporal_filter_stats filter_literals scalar_filter_pushdown scalar_filter_edges filter_semantics integer_filter_pushdown integer_filter_types; do
    python3 /job/run-sqltest.py "architecture-$config-$fixture" "/src/test/sql/data_inlining/inlined_$fixture.test" --binary /src/build/experiment/test/unittest "${options[@]}"
  done
done
python3 /job/run-sqltest.py architecture-postgres-legacy-float /src/test/sql/issues/issue_843_postgres_legacy_inlined_types.test --binary /src/build/experiment/test/unittest --config /job/postgres.json
for config in native postgres; do
  config_path=/job/$config.json
  if [ "$config" = native ]; then config_path=/job/native-config.json; fi
  python3 /job/run-suite.py "architecture-stats-$config" --binary /src/build/experiment/test/unittest --config "$config_path" --file-list /job/review-stats-tests.txt
  python3 /job/run-suite.py "architecture-related-$config" --binary /src/build/experiment/test/unittest --config "$config_path" --file-list /job/expanded-related-tests.txt
done
