#!/bin/bash
set -euo pipefail
cd /src
freeze() {
  destination=$1
  mkdir -p "$destination/src" "$destination/benchmark" "$destination/repository/v2.0.0-dev0/linux_amd64"
  cp build/review-release/duckdb "$destination/"
  cp build/review-release/src/libduckdb.so "$destination/src/"
  cp build/review-release/benchmark/benchmark_runner "$destination/benchmark/"
  cp build/review-release/extension/postgres_scanner/postgres_scanner.duckdb_extension "$destination/repository/v2.0.0-dev0/linux_amd64/"
  cp build/review-release/extension/sqlite_scanner/sqlite_scanner.duckdb_extension "$destination/repository/v2.0.0-dev0/linux_amd64/"
  cp build/review-release/CMakeCache.txt "$destination/"
  ninja -C build/review-release -t commands duckdb benchmark_runner > "$destination/compile-commands.txt"
}
cmake --build build/review-release --target src/libduckdb.so --parallel 8
freeze /job/review-release-fixed
git config --global --add safe.directory '*'
export ENABLE_SQLITE_SCANNER=ON ENABLE_POSTGRES_SCANNER=ON
cmake -S duckdb -B build/review-release '-DDUCKDB_EXTENSION_CONFIGS=/job/review-base-source/extension_config.cmake;/job/extra-extension-config.cmake'
cmake --build build/review-release --target duckdb src/libduckdb.so ducklake_loadable_extension benchmark_runner postgres_scanner_loadable_extension sqlite_scanner_loadable_extension --parallel 8
freeze /job/review-release-baseline
