"""Measure client CPU with the existing inlined-filter fixtures and DuckDB CLI .timer."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import statistics
import subprocess
import sys
import tempfile
from uuid import uuid4

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--source", type=Path, required=True)
parser.add_argument("--old", type=Path, required=True, help="baseline build directory")
parser.add_argument("--new", type=Path, required=True, help="candidate build directory")
parser.add_argument("--output", type=Path, required=True)
parser.add_argument("--threads", type=int, default=2)
parser.add_argument("--memory", default="3GB")
parser.add_argument("--rows", type=int, default=100000)
parser.add_argument("--runs-per-block", type=int, default=5)
args = parser.parse_args()
args.source = args.source.resolve()
args.output = args.output.resolve()
args.output.mkdir(parents=True, exist_ok=False)
sys.path.insert(0, str(args.source / "duckdb/scripts/regression"))
sys.path.insert(0, str(args.source / ".github/regression"))
from catalog import create_catalog, render_root
from run import (
    create_database,
    drop_database,
    postgres_extensions,
    EXTENSION_DIRECTORY_ENV,
)

cases = [
    "integer_wide",
    "float",
    "varchar",
    "timestamp",
    "source_timestamp_count",
    "date_broad",
    "timestamptz_broad",
    "full_scan",
]
benchmarks = [
    f"benchmark/micro/read/inlined_filters/{name}.benchmark" for name in cases
]
builds = {"baseline": args.old.resolve(), "candidate": args.new.resolve()}
database = "inline_cpu_" + uuid4().hex
results = {}
manifest = {
    "settings": vars(args).copy(),
    "binary_sha256": {},
    "commands": [],
    "scope": "DuckDB CLI user+system CPU; excludes PostgreSQL server CPU",
    "order": ["baseline", "candidate", "candidate", "baseline"] * 2,
}
for variant, build in builds.items():
    manifest["binary_sha256"][variant] = {
        str(file.relative_to(build)): hashlib.sha256(file.read_bytes()).hexdigest()
        for file in [
            build / "duckdb",
            build / "src/libduckdb.so",
            build / "benchmark/benchmark_runner",
        ]
    }


def execute(label, command, env, sql=None):
    manifest["commands"].append({"label": label, "command": command})
    if sql:
        (args.output / f"{label}.sql").write_text(sql)
    result = subprocess.run(
        command, input=sql, capture_output=True, text=True, env=env, timeout=600
    )
    raw = result.stdout + result.stderr
    (args.output / f"{label}.log").write_text(raw)
    result.check_returncode()
    if re.search(r"ERROR|INCORRECT|TIMEOUT|FAIL", raw):
        raise RuntimeError(f"{label} failed; see saved log")
    return raw


with tempfile.TemporaryDirectory(prefix="inline-cpu-") as temporary:
    root = Path(temporary) / "benchmarks"
    render_root(args.source, root, benchmarks, create_catalog("postgres", database))
    create_database(database)
    try:
        for name, path in zip(cases, benchmarks):
            # The existing runner verifies each binary against the native EXCEPT ALL oracle.
            # Fixture loading and all verification finish before .timer is enabled.
            for variant, build in builds.items():
                env = os.environ.copy()
                env["LD_LIBRARY_PATH"] = str(build / "src")
                runner = str(build / "benchmark/benchmark_runner")
                env[EXTENSION_DIRECTORY_ENV] = postgres_extensions(runner)
                raw = execute(
                    f"verify-{name}-{variant}",
                    [
                        runner,
                        path,
                        "--root-dir",
                        str(root),
                        f"--threads={args.threads}",
                        f"--memory_limit={args.memory}",
                        "--rows",
                        str(args.rows),
                        "--timed-runs",
                        "1",
                    ],
                    env,
                )
                if not re.search(r"\.benchmark\t1\t[\d.]+", raw):
                    raise RuntimeError("The benchmark was skipped or did not execute")
            query = (
                (args.source / path)
                .read_text()
                .split("\nrun\n", 1)[1]
                .split("\nresult_query", 1)[0]
            )
            query = query.strip().replace("${rows}", str(args.rows))
            samples = {variant: [] for variant in builds}
            for block, variant in enumerate(manifest["order"]):
                build = builds[variant]
                extension = Path(
                    postgres_extensions(str(build / "benchmark/benchmark_runner"))
                )
                # Absolute extension path and matching shared library keep binaries isolated.
                sql = (
                    ".bail on\n.mode trash\nLOAD ducklake;\n"
                    + "LOAD '"
                    + str(extension / "postgres_scanner.duckdb_extension").replace(
                        "'", "''"
                    )
                    + "';\n"
                    + f"SET threads={args.threads};\nSET memory_limit='{args.memory}';\nSET TimeZone='UTC';\n"
                    + f"ATTACH 'ducklake:postgres:dbname={database}' AS lake "
                    + f"(METADATA_SCHEMA 'inlined_filters_{args.rows}', READ_ONLY);\n"
                    + ".mode json\nEXPLAIN (FORMAT JSON) "
                    + query
                    + "\n.mode trash\n"
                    + query
                    + "\n.timer on\n"
                    + (query + "\n") * args.runs_per_block
                    + ".timer off\n"
                )
                env = os.environ.copy()
                env["LD_LIBRARY_PATH"] = str(build / "src")
                raw = execute(
                    f"{name}-{block}-{variant}",
                    [str(build / "duckdb"), "-batch", ":memory:"],
                    env,
                    sql,
                )
                timings = re.findall(
                    r"Run Time[^\n]*real\s+([\d.]+)\s+user\s+([\d.]+)\s+sys\s+([\d.]+)",
                    raw,
                )
                if len(timings) != args.runs_per_block:
                    raise RuntimeError("Unexpected number of CLI timer samples")
                for real, user, system in timings:
                    samples[variant].append(
                        {
                            "wall_seconds": float(real),
                            "user_seconds": float(user),
                            "system_seconds": float(system),
                            "cpu_seconds": float(user) + float(system),
                        }
                    )
            medians = {
                variant: {
                    metric: statistics.median(sample[metric] for sample in values)
                    for metric in ("wall_seconds", "cpu_seconds")
                }
                for variant, values in samples.items()
            }
            results[name] = {"samples": samples, "medians": medians}
            (args.output / "samples.json").write_text(
                json.dumps(results, indent=2) + "\n"
            )
            print(json.dumps({"case": name, "medians": medians}), flush=True)
    finally:
        (args.output / "invocation.json").write_text(
            json.dumps(manifest, indent=2, default=str) + "\n"
        )
        drop_database(database)
