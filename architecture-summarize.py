"""Summarize retained verbose output from fixed 20-sample ABBA comparisons."""
import json
from pathlib import Path
import re
from statistics import median
import sys

for filename in sys.argv[1:]:
    path = Path(filename)
    rows = {}
    for match in re.finditer(r"^benchmark/micro/read/inlined_filters/([^\s/]+)\.benchmark\t([1-5])\t([0-9.]+)$", path.read_text(), re.MULTILINE):
        rows.setdefault(match[1], []).append((int(match[2]), float(match[3])))
    assert rows, path
    results = {}
    for case, samples in rows.items():
        assert len(samples) % 40 == 0, (path, case, len(samples))
        attempts = []
        for start in range(0, len(samples), 40):
            attempt = {"baseline": [], "candidate": []}
            for i, (run, timing) in enumerate(samples[start:start + 40]):
                assert run == i % 5 + 1, (case, i, run)
                variant = ("baseline", "candidate", "candidate", "baseline")[(i // 5) % 4]
                attempt[variant].append(timing)
            attempt["medians_seconds"] = {key: median(values) for key, values in attempt.items()}
            old, new = (attempt["medians_seconds"][key] for key in ("baseline", "candidate"))
            attempt["change_percent"] = (new / old - 1) * 100
            attempts.append(attempt)
        results[case] = {"attempts": attempts}
        final = attempts[-1]
        print(path.stem, case, len(attempts), final["medians_seconds"], round(final["change_percent"], 2))
    path.with_suffix('.json').write_text(json.dumps(results, indent=2) + '\n')
