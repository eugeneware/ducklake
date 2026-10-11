"""Supplement the upstream latency suite with DuckDB CLI process CPU counters."""

import json
import os
from pathlib import Path
import re
import statistics
import shutil
import tempfile
import uuid
import subprocess
import sys

sys.path.insert(0, "/src/.github/regression")
from catalog import create_catalog, render_root

source = Path("/src")
evidence = Path("/job/evidence")
temporary_root = Path(tempfile.mkdtemp(prefix="ducklake-inline-cpu-"))
root = temporary_root / "benchmarks"
database = "ducklake_inline_cpu_" + uuid.uuid4().hex
cases = ["integer_wide", "boolean", "decimal", "float", "double", "varchar", "blob", "date", "timestamp", "timestamptz", "source_timestamp_count", "date_broad", "timestamptz_broad", "full_scan"]
benchmarks = [f"benchmark/micro/read/inlined_filters/{name}.benchmark" for name in cases]
render_root(source, root, benchmarks, create_catalog("postgres", database))
subprocess.run(["createdb", "--no-password", database], check=True)
try:
    setup = subprocess.run([
        "/job/refined/benchmark/benchmark_runner", benchmarks[0],
        "--root-dir", str(root), "--threads=2", "--memory_limit=3GB", "--timed-runs", "1",
    ], capture_output=True, text=True, check=True, timeout=600)
    (evidence / "refinement-cpu-setup.log").write_text(setup.stdout + setup.stderr)
    assert re.search(r"\.benchmark\t1\t[\d.]+", setup.stderr), setup.stderr
    assert not re.search(r"ERROR|INCORRECT|TIMEOUT", setup.stderr), setup.stderr
    results = {}
    for name, path in zip(cases, benchmarks):
        query = (source / path).read_text().split("\nrun\n", 1)[1].split("\nresult_query", 1)[0].strip().replace("${rows}", "100000")
        samples = {"baseline": [], "candidate": []}
        for block, variant in enumerate(("baseline", "candidate", "candidate", "baseline")):
            binary_root = Path("/job/integer") if variant == "baseline" else Path("/job/refined")
            sql = (
                ".bail on\n.mode trash\nLOAD ducklake;\nLOAD postgres;\n"
                "SET threads=2;\nSET memory_limit='3GB';\nSET TimeZone='UTC';\n"
                f"ATTACH 'ducklake:postgres:dbname={database}' AS lake "
                "(METADATA_SCHEMA 'inlined_filters_100000', READ_ONLY);\n"
                + ".mode json\nEXPLAIN (FORMAT JSON) " + query + "\n.mode trash\n"
                + query + "\n.timer on\n" + (query + "\n") * 5 + ".timer off\n"
            )
            label = f"refinement-cpu-{name}-{block}-{variant}"
            (evidence / f"{label}.sql").write_text(sql)
            env = os.environ.copy()
            env["LD_LIBRARY_PATH"] = str(binary_root / "src")
            result = subprocess.run([str(binary_root / "duckdb"), "-batch", ":memory:"],
                                    input=sql, capture_output=True, text=True, env=env, check=True, timeout=300)
            (evidence / f"{label}.log").write_text(result.stdout + result.stderr)
            timings = re.findall(r"Run Time[^\n]*real\s+([\d.]+)\s+user\s+([\d.]+)\s+sys\s+([\d.]+)", result.stdout)
            assert len(timings) == 5, result.stdout
            for real, user, system in timings:
                samples[variant].append({"wall_seconds": float(real), "cpu_seconds": float(user) + float(system)})
        summary = {variant: {metric: statistics.median(sample[metric] for sample in values)
                             for metric in ("wall_seconds", "cpu_seconds")}
                   for variant, values in samples.items()}
        results[name] = {"samples": samples, "medians": summary}
        print(json.dumps({"case": name, "medians": summary}), flush=True)
    (evidence / "refinement-cpu.json").write_text(json.dumps(results, indent=2) + "\n")

finally:
    subprocess.run(["dropdb", "--no-password", "--force", database], check=True)
    shutil.rmtree(temporary_root)
