import hashlib,json,subprocess
from pathlib import Path
job=Path('/job')
expected=json.loads((job/'architecture-source-sha256.json').read_text())
actual={f:hashlib.sha256((Path('/src')/f).read_bytes()).hexdigest() for f in expected}
assert actual==expected, 'Remote source differs from committed source'
head=(job/'architecture-head.txt').read_text().strip()
manifest=json.loads((job/'evidence/review-build-manifest.json').read_text())
manifest.update(source_sha256=actual,source_matches_committed_head=True,builds={})
for name,revision in [('architecture-fixed',head),('architecture-release-fixed',head),('review-fixed','c970d6284e7d79e0ea4b451d48d30b2281ee3261'),('review-release-baseline','b6f14fe678b80905e1ab86d3df26e4a5fe2f15b1')]:
    build=job/name
    cache=(build/'CMakeCache.txt').read_text() if (build/'CMakeCache.txt').exists() else None
    files=[build/'duckdb',build/'src/libduckdb.so',build/'benchmark/benchmark_runner']
    files.extend(sorted((build/'repository').rglob('*.duckdb_extension')))
    manifest['builds'][name]={'source':revision,'sha256':{str(f.relative_to(build)):hashlib.sha256(f.read_bytes()).hexdigest() for f in files},'build_flags': [line for line in (cache or '').splitlines() if line.startswith(('CMAKE_BUILD_TYPE:', 'CMAKE_CXX_FLAGS:', 'CMAKE_CXX_FLAGS_RELEASE:', 'CMAKE_CXX_FLAGS_MINSIZEREL:', 'CMAKE_C_FLAGS:', 'CMAKE_C_FLAGS_RELEASE:', 'CMAKE_C_FLAGS_MINSIZEREL:'))]}
for key in ['build_type','cxx_flags','c_flags']:
    manifest.pop(key,None)
(job/'evidence/architecture-build-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps({'head':head,'files_verified':len(actual),'variants':list(manifest['builds'])}))
