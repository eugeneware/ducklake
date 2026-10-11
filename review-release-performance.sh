#!/bin/bash
set -euo pipefail
cd /src
python3 /job/review-cpu.py --source /src --old /job/review-release-baseline --new /job/review-release-fixed --output /job/evidence/review-release-cpu-off-on --threads 2 --memory 3GB > /job/evidence/review-release-cpu-off-on.log 2>&1
python3 .github/regression/run.py --catalog postgres --old /job/review-release-baseline/benchmark/benchmark_runner --new /job/review-release-fixed/benchmark/benchmark_runner --benchmarks /job/review-release-cases.csv --threads 2 --samples 20 --memory-limit 3GB > /job/evidence/review-release-latency-off-on.log 2>&1
