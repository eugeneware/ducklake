import shutil
from pathlib import Path
import subprocess

for source_name, destination_name in [('experiment', 'architecture-fixed'), ('review-release', 'architecture-release-fixed')]:
    source = Path('/src/build') / source_name
    destination = Path('/job') / destination_name
    destination.mkdir()
    for path in ['duckdb', 'src/libduckdb.so', 'benchmark/benchmark_runner', 'CMakeCache.txt']:
        target = destination / path
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source / path, target)
    repository = destination / 'repository/v2.0.0-dev0/linux_amd64'
    repository.mkdir(parents=True)
    for extension in ['postgres_scanner', 'sqlite_scanner']:
        shutil.copy2(source / 'extension' / extension / (extension + '.duckdb_extension'), repository)
    with (destination / 'compile-commands.txt').open('w') as output:
        subprocess.run(['ninja', '-C', str(source), '-t', 'commands', 'duckdb', 'benchmark_runner'], stdout=output, check=True)
