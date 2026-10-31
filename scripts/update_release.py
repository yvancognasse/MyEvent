#!/usr/bin/env python3
"""Version code changes, date every build, and enforce English help maintenance."""
import argparse
import hashlib
import json
from pathlib import Path
import plistlib
from datetime import datetime, timezone
import tempfile

ROOT = Path(__file__).resolve().parent.parent

def digest(paths):
    sha = hashlib.sha256()
    for path in sorted(paths):
        sha.update(str(path.relative_to(ROOT)).encode())
        sha.update(path.read_bytes())
    return sha.hexdigest()

def atomic_write(path, data):
    with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as tmp:
        tmp.write(data)
        temporary = Path(tmp.name)
    temporary.replace(path)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true', help='Verify freshness without changing metadata.')
    args = parser.parse_args()
    state_path = ROOT / '.release-state.json'
    state = json.loads(state_path.read_text()) if state_path.exists() else {'version': '1.3.0', 'build': 3}
    sources = list((ROOT/'Sources').rglob('*.swift')) + list((ROOT/'scripts').glob('*')) + [ROOT/'Package.swift']
    code_hash = digest([p for p in sources if p.is_file()])
    template = ROOT/'docs/help.template.html'
    help_hash = hashlib.sha256(template.read_bytes()).hexdigest()
    changed = code_hash != state.get('code_hash')
    if changed and state.get('code_hash') and help_hash == state.get('help_hash'):
        raise SystemExit('Code changed: update docs/help.template.html before building (required English help review).')
    if args.check:
        if changed or help_hash != state.get('help_hash'):
            raise SystemExit('Release metadata/help is stale. Update the guide and run scripts/build.sh.')
        info = plistlib.loads((ROOT/'Info.plist').read_bytes())
        for key, value in [('CFBundleShortVersionString',state['version']),('CFBundleVersion',str(state['build'])),('MyEventBuildDate',state['date'])]:
            if info.get(key) != value: raise SystemExit('Release metadata does not match: '+key)
        expected = template.read_text().replace('{{VERSION}}',state['version']).replace('{{BUILD}}',str(state['build'])).replace('{{BUILD_DATE}}',state['date'])
        if (ROOT/'Resources/help.html').read_text()!=expected: raise SystemExit('English guide does not match this build.')
        print('Release metadata and English help are current.')
        return
    version = state['version']
    if changed and state.get('code_hash'):
        major, minor, patch = map(int, version.split('.'))
        version = f'{major}.{minor}.{patch + 1}'
    build = state['build'] + 1
    date = datetime.now(timezone.utc).isoformat(timespec='seconds').replace('+00:00','Z')
    info = plistlib.loads((ROOT/'Info.plist').read_bytes())
    info.update(CFBundleShortVersionString=version, CFBundleVersion=str(build), MyEventBuildDate=date)
    atomic_write(ROOT/'Info.plist',plistlib.dumps(info,sort_keys=False))
    rendered = template.read_text().replace('{{VERSION}}',version).replace('{{BUILD}}',str(build)).replace('{{BUILD_DATE}}',date)
    atomic_write(ROOT/'Resources/help.html',rendered.encode())
    state.update(version=version,build=build,date=date,code_hash=code_hash,help_hash=help_hash)
    atomic_write(state_path,(json.dumps(state,indent=2)+'\n').encode())
    print(f'MyEvent {version} · Build {build} · {date}; English help refreshed.')

if __name__ == '__main__': main()
