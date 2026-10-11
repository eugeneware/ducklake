#!/bin/bash
set -euo pipefail
cd /src
python3 /job/review-cpu.py --source /src --old /job/baseline --new /job/review-fixed --output /job/evidence/review-cpu-off-on --threads 2 --memory 3GB > /job/evidence/review-cpu-off-on.log 2>&1
python3 .github/regression/run.py --catalog postgres --old /job/baseline/benchmark/benchmark_runner --new /job/review-fixed/benchmark/benchmark_runner --benchmarks .github/regression/inlined_filters.csv --threads 2 --samples 20 --memory-limit 3GB > /job/evidence/review-latency-off-on.log 2>&1
python3 .github/regression/run.py --catalog postgres --old /job/refined/benchmark/benchmark_runner --new /job/review-fixed/benchmark/benchmark_runner --benchmarks .github/regression/inlined_filters.csv --threads 2 --samples 20 --memory-limit 3GB > /job/evidence/review-latency-reviewed-fixed.log 2>&1
