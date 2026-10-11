#!/bin/bash
set -euo pipefail
cd /src
python3 /job/review-cpu.py --source /src --old /job/review-release-baseline --new /job/architecture-release-fixed --output /job/evidence/architecture-release-cpu-off-on --threads 2 --memory 3GB > /job/evidence/architecture-release-cpu-off-on.log 2>&1
python3 .github/regression/run.py --catalog postgres --old /job/review-release-baseline/benchmark/benchmark_runner --new /job/architecture-release-fixed/benchmark/benchmark_runner --benchmarks /job/review-release-cases.csv --threads 2 --samples 20 --memory-limit 3GB > /job/evidence/architecture-release-latency-off-on.log 2>&1
python3 .github/regression/run.py --catalog postgres --old /job/review-fixed/benchmark/benchmark_runner --new /job/architecture-fixed/benchmark/benchmark_runner --benchmarks .github/regression/inlined_filters.csv --threads 2 --samples 20 --memory-limit 3GB > /job/evidence/architecture-latency-incremental.log 2>&1
