"""Deployment-only regression: the real `source_tarball` from release/release.sh against temporary git repos.

Checks: sub repo files are archived from their own repos only, secrets and
release state are excluded even when accidentally tracked, deleted tracked files are skipped, and
non-ASCII (Hangul) paths survive. No Docker, SSH or service runtime is used.
"""
import io
from pathlib import Path
import subprocess
import tarfile
import tempfile

root = Path(__file__).resolve().parents[2]
script = (root / 'release/release.sh').read_text()
archiver = script[script.index('source_tarball() {'):script.index('\ncmd_deploy() {')]
program = '''set -euo pipefail
ROOT="$1"
ALL_SERVICES="ws-api ws-worker ws-web"
detect_os() { if [ "$(uname)" = Darwin ]; then echo macos; else echo linux; fi; }
''' + archiver + '\nsource_tarball\n'

with tempfile.TemporaryDirectory(prefix='ws-release-test-') as temp:
    fixture = Path(temp)
    gitignore_root = '/ws-api/\n/ws-worker/\n/ws-web/\nrelease/.state/\n'
    paths = {
        '.': ['.gitignore', 'PRD.md', 'docs/old.md', 'release/.state/tokens.json', '.secrets/example', '.env.prod',
              'release/deploy.env'],
        'ws-api': ['go.mod', 'cmd/server/main.go', '.env.prod', 'test/impl/한글 파일.md'],
        'ws-worker': ['app/main.py', '.secrets/key'],
        'ws-web': ['src/App.tsx', 'node_modules/x/index.js'],
    }
    for repo, files in paths.items():
        directory = fixture / repo
        directory.mkdir(exist_ok=True)
        subprocess.run(['git', 'init', '-q', str(directory)], check=True)
        for name in files:
            path = directory / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(gitignore_root if (repo == '.' and name == '.gitignore') else 'synthetic test fixture\n')
        # force-add: simulates secrets that were tracked by mistake (ignore rules bypassed)
        subprocess.run(['git', '-C', str(directory), 'add', '-f', '.'], check=True)
    (fixture / 'docs/old.md').unlink()                      # tracked but deleted before commit
    (fixture / 'ws-api/untracked.go').write_text('package x\n')   # untracked, not ignored

    out = subprocess.run(['bash', '-c', program, 'archive', str(fixture)], check=True, capture_output=True).stdout
    names = set(tarfile.open(fileobj=io.BytesIO(out)).getnames())

expected = {'.gitignore', 'PRD.md', 'ws-api/go.mod', 'ws-api/cmd/server/main.go',
            'ws-api/test/impl/한글 파일.md', 'ws-api/untracked.go',
            'ws-worker/app/main.py', 'ws-web/src/App.tsx'}
forbidden = {'release/.state/tokens.json', '.secrets/example', '.env.prod', 'release/deploy.env', 'docs/old.md',
             'ws-api/.env.prod', 'ws-worker/.secrets/key',
             'ws-web/node_modules/x/index.js'}
missing = expected - names
leaked = forbidden & names
assert not missing, f'missing from archive: {sorted(missing)}'
assert not leaked, f'leaked into archive: {sorted(leaked)}'
print(f'source archive OK ({len(names)} files, {len(forbidden)} forbidden paths excluded)')
