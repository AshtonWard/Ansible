#!/usr/bin/env python3
"""Conservative publication checks; review is still required before copying files."""
import ipaddress
import re
import subprocess
from pathlib import Path
import yaml

ROOT = Path(__file__).resolve().parents[1]
errors = []
allowed_networks = tuple(map(ipaddress.ip_network, ('192.0.2.0/24', '198.51.100.0/24', '203.0.113.0/24', '127.0.0.0/8')))
# Never echo matched values: diagnostics identify files and categories only.
patterns = {
    'private key': r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----',
    'GitHub token': r'\b(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{30,})\b',
    'AWS access key': r'\b(?:AKIA|ASIA)[A-Z0-9]{16}\b',
    'vault payload': r'\$ANSIBLE_VAULT;|!vault\b',
    'personal checkout path': r'/home/[^/\s]+/',
    'private network prefix': r'\b(?:10\.\d{1,3}|192\.168|172\.(?:1[6-9]|2\d|3[01]))\.(?:\$|\{|\*)',
    'non-example internal hostname': r'\b(?:[a-z0-9-]+\.)+(?:local|lan|internal)\b',
}
for path in sorted(ROOT.rglob('*')):
    if any(p in {'.git', '__pycache__', '.venv'} for p in path.relative_to(ROOT).parts):
        continue
    if path.is_symlink():
        errors.append(f'{path.relative_to(ROOT)}: symlink is not publishable')
        continue
    if not path.is_file():
        continue
    name = str(path.relative_to(ROOT))
    if re.search(r'(^|/)(?:vault(?:\.ya?ml)?|vault-pass|\.vault_pass|credentials\.ya?ml|secrets\.ya?ml|\.env|id_rsa|id_ed25519)$|\.(?:pem|key|p12|pfx)$', name):
        errors.append(f'{name}: secret/runtime filename')
    try:
        content = path.read_text(encoding='utf-8')
    except UnicodeError:
        errors.append(f'{name}: binary content requires manual review')
        continue
    for category, pattern in patterns.items():
        if path != Path(__file__).resolve() and re.search(pattern, content, re.I):
            errors.append(f'{name}: {category}')
    for match in re.finditer(r'(?<![\w.])(?:\d{1,3}\.){3}\d{1,3}(?![\w.])', content):
        try:
            address = ipaddress.ip_address(match.group())
        except ValueError:
            continue  # Deliberately invalid input fixtures are not addresses.
        if address != ipaddress.ip_address('0.0.0.0') and not any(address in net for net in allowed_networks):
            errors.append(f'{name}: non-example IPv4 address')
    # Plaintext secret assignments must be empty or variable references.
    if path.suffix in {'.yml', '.yaml', '.toml', '.env'}:
        for line in content.splitlines():
            if re.match(r'\s*(?:ansible_password|ansible_become_password|komodo_database_password|komodo_onboarding_key|vault_\w+)\s*[:=]', line):
                value = re.split(r'[:=]', line, maxsplit=1)[1].strip().strip('\"\'')
                if value and not value.startswith(('{{', '${')):
                    errors.append(f'{name}: literal credential assignment')
    if path.suffix in {'.yml', '.yaml'}:
        try:
            data = yaml.load(content, Loader=yaml.BaseLoader)
            if '/defaults/' in '/' + name and data not in (None, "") and not isinstance(data, dict):
                errors.append(f'{name}: role defaults must be a mapping')
            if name.startswith('.github/workflows/'):
                assert isinstance(data, dict) and 'on' in data and 'jobs' in data
                for job in data['jobs'].values():
                    assert job.get('if') == "vars.ENABLE_LAB_AUTOMATION == 'true'", 'Infrastructure job needs explicit opt-in'
                    for step in job.get('steps', []):
                        if 'run' in step and step.get('shell', 'bash') == 'bash':
                            result = subprocess.run(['bash', '-n'], input=step['run'], text=True, capture_output=True)
                            if result.returncode:
                                errors.append(f'{name}: invalid Bash syntax in {step.get("name", "step")}')
        except (yaml.YAMLError, AssertionError, AttributeError) as error:
            errors.append(f'{name}: invalid YAML/structure ({type(error).__name__})')
if errors:
    raise SystemExit('\n'.join(errors))
print('PASS: publication patterns, example addresses, YAML, workflow opt-in, and Bash syntax')
