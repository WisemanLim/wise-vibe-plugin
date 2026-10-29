"""Deployment-only regression for scripts/prod-secrets.sh (init/status) on a synthetic sub project.

Checks: CHANGE_ME replaced, DATABASE_URL rebuilt with the original scheme, re-run keeps values,
new template keys are appended, secret:// references produce 0440 files, values are never printed,
status flags a mismatch with exit 5. Dangling deploy symlinks (shared/) are written through.
"""
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
template = '''APP_ENV=prod
DB_ENGINE=postgres
DB_HOST=db
DB_PORT=5432
DB_NAME=app
DB_USER=app
DB_PASSWORD=CHANGE_ME
DATABASE_URL=postgresql+psycopg://app:CHANGE_ME@db:5432/app
AUTH_KEY=secret://file/run/secrets/auth_key
'''

TSV = '# repo\tshort\tcomponent\timage_var\thas_db\thost_port\nws-worker\tworker\tapi\tAPI_IMAGE\t1\t8281\n'


def run(fixture, *args, check=True):
    return subprocess.run(['bash', str(fixture / 'scripts/prod-secrets.sh'), *args],
                          capture_output=True, text=True, check=check)

def env_value(path, key):
    return re.search(rf'^{key}=(.*)$', path.read_text(), re.M).group(1)

with tempfile.TemporaryDirectory(prefix='ws-secrets-test-') as temp:
    fixture = Path(temp)
    (fixture / 'scripts').mkdir()
    shutil.copy(root / 'scripts/prod-secrets.sh', fixture / 'scripts/prod-secrets.sh')
    (fixture / 'release').mkdir()
    (fixture / 'release/services.tsv').write_text(TSV)
    svc = fixture / 'ws-worker'
    svc.mkdir()
    (svc / '.env.example').write_text(template)

    first = run(fixture, 'init', 'worker', '--env', 'dev')
    envf = svc / '.env.prod'
    password = env_value(envf, 'DB_PASSWORD')
    assert re.fullmatch(r'[0-9a-f]{48}', password), 'password not generated'
    assert password not in first.stdout + first.stderr, 'password printed'
    assert env_value(envf, 'DATABASE_URL') == f'postgresql+psycopg://app:{password}@db:5432/app'
    assert env_value(envf, 'APP_ENV') == 'dev'
    assert stat.S_IMODE(envf.stat().st_mode) == 0o600
    secret = svc / '.secrets/auth_key'
    assert stat.S_IMODE(secret.stat().st_mode) == 0o440
    assert secret.read_text().strip() not in first.stdout

    (svc / '.env.example').write_text(template + 'NEW_KEY=1\n')
    run(fixture, 'init', 'worker')
    assert env_value(envf, 'DB_PASSWORD') == password, 're-run changed the password'
    assert env_value(envf, 'NEW_KEY') == '1', 'new template key not added'

    status = run(fixture, 'status', 'worker')
    assert 'consistent' in status.stdout and password not in status.stdout
    envf.write_text(envf.read_text().replace('@db:5432', '@other:5432'))
    assert run(fixture, 'status', 'worker', check=False).returncode == 5, 'mismatch not detected'

    # deploy layout: releases/<V>/<svc>/.env.prod -> ../../../shared/<svc>/.env.prod (dangling at first init)
    rel = fixture / 'releases/1.0.0'
    (rel / 'scripts').mkdir(parents=True)
    shutil.copy(root / 'scripts/prod-secrets.sh', rel / 'scripts/prod-secrets.sh')
    (rel / 'release').mkdir()
    (rel / 'release/services.tsv').write_text(TSV)
    rsvc = rel / 'ws-worker'
    rsvc.mkdir()
    (rsvc / '.env.example').write_text(template)
    (fixture / 'shared/ws-worker').mkdir(parents=True)
    os.symlink('../../../shared/ws-worker/.env.prod', rsvc / '.env.prod')
    os.symlink('../../../shared/ws-worker/.secrets', rsvc / '.secrets')
    run(rel, 'init', 'worker')
    assert (fixture / 'shared/ws-worker/.env.prod').is_file(), 'shared .env.prod not created'
    assert (fixture / 'shared/ws-worker/.secrets/auth_key').is_file(), 'shared secret not created'
print('prod-secrets OK (init/re-run/new key/secret file/status mismatch/shared symlink)')
