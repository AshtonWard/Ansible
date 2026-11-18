#!/usr/bin/env python3
"""Private staging only: flag source changes requiring a fresh sanitization review."""
import argparse
import hashlib
import json
from pathlib import Path
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--source-root', type=Path, required=True)
args = parser.parse_args()
manifest = json.loads((Path(__file__).resolve().parents[1] / 'SOURCE_REVIEW.json').read_text())
root = args.source_root.resolve()
paths = {str(p.relative_to(root)) for folder in ('.github/workflows', 'playbooks', 'roles', 'scripts') for p in (root / folder).rglob('*') if p.is_file() and p.name != 'validate-sanitized.yml'}
paths.add('ansible.cfg')
changed = sorted(paths.symmetric_difference(manifest['source_files']))
for name, expected in manifest['source_files'].items():
    path = root / name
    if path.is_file() and hashlib.sha256(path.read_bytes()).hexdigest() != expected:
        changed.append(name)
if changed:
    raise SystemExit('Source drift requires sanitization review:\n' + '\n'.join(sorted(set(changed))))
print('PASS: reviewed implementation files match the recorded source snapshot')
