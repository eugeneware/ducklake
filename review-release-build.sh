#!/bin/bash
set -euo pipefail
cd /src
git config --global --add safe.directory '*'
export ENABLE_SQLITE_SCANNER=ON ENABLE_POSTGRES_SCANNER=ON
cmake -S duckdb -B build/review-release -G Ninja \
  -DCMAKE_C_COMPILER=clang-20 -DCMAKE_CXX_COMPILER=clang++-20 \
  -DCMAKE_BUILD_TYPE=Release \
  '-DDUCKDB_EXTENSION_CONFIGS=/src/extension_config.cmake;/job/extra-extension-config.cmake' \
  -DBUILD_UNITTESTS=ON -DBUILD_SHELL=ON -DBUILD_BENCHMARKS=ON -DEXTENSION_STATIC_BUILD=0 \
  -DCMAKE_CXX_STANDARD_LIBRARIES=-lpq
cmake --build build/review-release --target duckdb src/libduckdb.so ducklake_loadable_extension benchmark_runner postgres_scanner_loadable_extension sqlite_scanner_loadable_extension --parallel 8
