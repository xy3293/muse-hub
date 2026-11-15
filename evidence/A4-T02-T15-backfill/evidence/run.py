#!/usr/bin/env python3
"""Two local A4 replays using the genuine Test 7 event/receipt; no remote writes."""
import collections
import datetime
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time

OUT = Path(__file__).resolve().parent
ROOT = OUT.parent.parent
STATE = ROOT / 'real-home/hooks/state/muse-hub'
NAME = 'result-T-904-node-1-bc3206e97018cebe7a4accf0ff1fdfe2b63943a9.json'
EVENT = STATE / 'events' / NAME
RECEIPT = STATE / 'receipts' / NAME


def write(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n')


def metadata(path):
    data = path.read_bytes()
    return dict(bytes=len(data), sha256=hashlib.sha256(data).hexdigest(),
                mtime_ns=path.stat().st_mtime_ns)


def originals():
    paths = []
    for directory in (ROOT / 'real-home', ROOT / 'test-repo'):
        paths.extend(p for p in directory.rglob('*') if p.is_file())
    paths.extend([ROOT / 'ack/step6b-real.py', ROOT / 'ack/step6b-resume.py',
                  ROOT / 'ack/stub_server.py', ROOT / 'ack/worker_sim.py',
                  ROOT / 'ack/step6-before/save-receipt.sh'])
    return {str(p.relative_to(ROOT)): metadata(p) for p in sorted(paths)}


def command(argv, env, label, cwd=None):
    p = subprocess.run(argv, env=env, cwd=cwd, capture_output=True, text=True, timeout=40)
    (OUT / (label + '.stdout')).write_text(p.stdout)
    (OUT / (label + '.stderr')).write_text(p.stderr)
    write(OUT / (label + '.command.json'), dict(argv=argv, cwd=str(cwd or ROOT), exit=p.returncode))
    return p


def seed(label, cursor):
    home = OUT / label / 'real-home'
    state = home / 'hooks/state/muse-hub'
    for directory in ('events', 'receipts', 'logs'):
        (state / directory).mkdir(parents=True)
    shutil.copy2(EVENT, state / 'events' / NAME)
    shutil.copy2(RECEIPT, state / 'receipts' / NAME)
    write(state / 'scan.json', dict(schema_version=1, scan_cursor=cursor, comments={}))
    write(state / 'health.json', {})
    return home, state


def snapshot(state):
    paths = list((state / 'events').glob('*.json')) + list((state / 'receipts').glob('*.json'))
    return dict(scan=json.loads((state / 'scan.json').read_text()),
                health=json.loads((state / 'health.json').read_text()),
                files={str(p.relative_to(state)): dict(**metadata(p), json=json.loads(p.read_text()))
                       for p in sorted(paths)})


assert not (OUT / 'originals.before.json').exists(), 'Use a new evidence directory; never overwrite a run.'
before = originals()
write(OUT / 'originals.before.json', before)
source_event = json.loads(EVENT.read_text())
source_receipt = json.loads(RECEIPT.read_text())
assert source_event['state'] == 'ACKED' and source_event['main_ack']['acked'] is True
assert source_event['event_id'] == source_receipt['event_id']
assert metadata(RECEIPT)['sha256'] == '9f4d2d76a75b6ed96e50bb9f6ca12910eed93dc652d0dde790124ae44b8f8a2c'
saved = json.loads((ROOT / 'ack/step6b-real-ack.after.json').read_text())
assert saved['events'][NAME] == source_event
write(OUT / 'prerequisites.json', dict(
    at_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
    event_counts=dict(collections.Counter(json.loads(p.read_text())['state'] for p in (STATE / 'events').glob('*.json'))),
    receipts_count=len(list((STATE / 'receipts').glob('*.json'))),
    genuine_event_matches_saved_ack_after=True, event=source_event,
    event_file=metadata(EVENT), receipt_file=metadata(RECEIPT)))

# Recover the exact Step 6b poll from its saved syntax-fault fixture, removing only
# the fault explicitly appended by test_faults.py:syntax(). Verify the historical hash.
damaged = ROOT / 'ack/run.wDtnvV/fault-T19/hooks/scripts/director-watch-poll.sh'
raw = damaged.read_bytes()
suffix = b'\nif then\n'
assert raw.endswith(suffix)
poll = OUT / 'director-watch-poll.step6b.sh'
poll.write_bytes(raw[:-len(suffix)])
protected = json.loads((ROOT / 'ack/step6b-resume-protected-before.json').read_text())
assert metadata(poll)['sha256'] == protected['/home/hatch/hooks/scripts/director-watch-poll.sh']
helper = ROOT / 'ack/step6-before/save-receipt.sh'
assert metadata(helper)['sha256'] == protected['/home/hatch/hooks/scripts/save-receipt.sh']
write(OUT / 'code-provenance.json', dict(damaged_copy=str(damaged), removed_suffix=suffix.decode(),
      poll=metadata(poll), historical_poll_sha256=protected['/home/hatch/hooks/scripts/director-watch-poll.sh'],
      helper=str(helper), helper_metadata=metadata(helper)))

# Reuse the existing server; only its repository route changes in this local copy.
server_code = (ROOT / 'ack/stub_server.py').read_text()
assert server_code.count("prefix = '/repos/xy3293/muse-hub/'") == 1
(OUT / 'stub_server.py').write_text(server_code.replace("prefix = '/repos/xy3293/muse-hub/'",
                                                     "prefix = '/repos/xy3293/muse-hub-test/'"))
binpath = OUT / 'bin'
binpath.mkdir()
(binpath / 'git').write_text('''#!/usr/bin/env bash
set -euo pipefail
[[ "$#" == 3 && "$1" == ls-remote && "$2" == https://github.com/xy3293/muse-hub-test.git && "$3" == HEAD ]]
printf '%s\\tHEAD\\n' "$TEST_HEAD_SHA"
''')
(binpath / 'curl').write_text('''#!/usr/bin/env bash
set -euo pipefail
[[ "$GITHUB_API_BASE" == http://127.0.0.1:* ]]
for arg in "$@"; do
  case "$arg" in http://*|https://*) [[ "$arg" == "$GITHUB_API_BASE/"* ]] ;; esac
done
[[ "${!#}" == "$GITHUB_API_BASE/"* ]]
exec /usr/bin/curl --disable --noproxy '*' "$@"
''')
for path in binpath.iterdir():
    path.chmod(0o755)

env = dict(PATH='/usr/bin:/bin', HOME=str(OUT), TMPDIR='/tmp', LANG='C.UTF-8',
           GIT_CONFIG_NOSYSTEM='1', GIT_CONFIG_GLOBAL='/dev/null',
           GIT_AUTHOR_NAME='A4 isolated fixture', GIT_AUTHOR_EMAIL='a4@example.invalid',
           GIT_COMMITTER_NAME='A4 isolated fixture', GIT_COMMITTER_EMAIL='a4@example.invalid')
for i, path in enumerate([poll, helper, binpath / 'git', binpath / 'curl']):
    assert command(['/bin/bash', '-n', str(path)], env, f'syntax-{i}').returncode == 0

# Real local Git objects give the fixture real SHAs; this repository has no remote.
repo = OUT / 'test-repo'
shutil.copytree(ROOT / 'test-repo', repo)


def git(*args):
    p = command(['/usr/bin/git', *args], env, 'git-' + str(git.count), repo)
    git.count += 1
    assert p.returncode == 0, p.stderr
    return p.stdout.strip()


git.count = 0
git('init', '--initial-branch=main')
git('add', '.')
git('commit', '-m', 'A4 local baseline from existing test-repo snapshot')
base = git('rev-parse', 'HEAD')
result_file = repo / 'results/node-1/T-904-step6b.md'
text = result_file.read_text()
assert 'version: 1' in text
result_file.write_text(text.replace('result v1', 'result v2').replace('version: 1', 'version: 2'))
git('add', 'results/node-1/T-904-step6b.md')
git('commit', '-m', 'A4 T02 local result revision; no semantic acceptance')
v2 = git('rev-parse', 'HEAD')
new_id = 'result:T-904:node-1:' + v2
write(OUT / 'local-commits.json', dict(baseline=base, T02=v2, remote=None))

server_out = (OUT / 'server.stdout').open('w')
server_err = (OUT / 'server.stderr').open('w')
server = subprocess.Popen([sys.executable, str(OUT / 'stub_server.py'), str(OUT)],
                          stdout=server_out, stderr=server_err, env=env)
summary = dict(scope='local loopback replay, genuine saved Test 7 event/receipt, exact Step 6b poll',
               production_reads=0, remote_writes=0, cases={})
try:
    for _ in range(100):
        if (OUT / 'port').exists():
            break
        assert server.poll() is None, 'fixture server exited'
        time.sleep(.02)
    api = 'http://127.0.0.1:' + (OUT / 'port').read_text()

    def invoke(label, cursor, head, files, message):
        home, state = seed(label, cursor)
        fx = dict(case=label, cursor=cursor, head=head, commits={head: dict(
            sha=head, commit=dict(message=message), author=dict(login='xy3293'),
            files=[dict(filename=f) for f in files])}, comments=[])
        write(OUT / 'fixture.json', fx)
        write(OUT / (label + '.fixture.json'), fx)
        runenv = dict(env, HOME=str(home), PATH=str(binpath) + ':/usr/bin:/bin',
                      MUSE_HUB_REPO='xy3293/muse-hub-test', GITHUB_API_BASE=api,
                      HATCH_HOOK_DRY_RUN='0', TEST_HEAD_SHA=head)
        initial = snapshot(state)
        write(OUT / (label + '.before.json'), initial)
        p = command(['/bin/bash', str(poll)], runenv, label)
        after = snapshot(state)
        write(OUT / (label + '.after.json'), after)
        assert p.returncode == 0 and len(p.stdout.splitlines()) == 1, p.stderr
        assert p.stdout.startswith('RESULT '), p.stdout
        result = json.loads(p.stdout[7:])
        assert after['scan']['scan_cursor'] == head
        assert after['health']['consecutive_api_failures'] == 0
        for key, old in initial['files'].items():
            assert after['files'][key] == old, key + ' changed'
        print(f'{label}: exit={p.returncode}', flush=True)
        print(p.stdout, end='', flush=True)
        return state, runenv, result

    state, runenv, result = invoke('T02', base, v2, ['results/node-1/T-904-step6b.md'],
                                  git('log', '-1', '--format=%B'))
    assert result['decision'] == 'wake' and result['reason'] == 'muse-hub-activity'
    assert [e['event_id'] for e in result['payload']['events']] == [new_id]
    new_file = state / 'events' / (new_id.replace(':', '-') + '.json')
    new_event = json.loads(new_file.read_text())
    assert new_event['state'] == 'DETECTED' and new_event['review'] is None
    assert new_event['main_ack']['acked'] is False
    assert len(list((state / 'events').glob('*.json'))) == 2
    # Reuse the existing harness's pure receipt identity predicate. Do not run its
    # worker oracle, semantic validation, approvals, notifications, or remote effects.
    spec = importlib.util.spec_from_file_location('a4_worker_sim', ROOT / 'ack/worker_sim.py')
    module = importlib.util.module_from_spec(spec)
    sys.dont_write_bytecode = True
    spec.loader.exec_module(module)
    assert module.valid(source_receipt, source_event) is True
    assert module.valid(source_receipt, new_event) is False
    new_receipt = state / 'receipts' / new_file.name
    assert not new_receipt.exists()
    old_hash = metadata(state / 'receipts' / NAME)
    positive = command(['/bin/bash', str(helper), source_event['event_id'], str(RECEIPT)], runenv, 'T02-save-old-control')
    negative = command(['/bin/bash', str(helper), new_id, str(RECEIPT)], runenv, 'T02-save-old-as-new')
    assert positive.returncode == 0
    assert negative.returncode == 1 and 'invalid or incomplete receipt' in negative.stderr
    assert not new_receipt.exists() and not list((state / 'receipts').glob('.tmp-*'))
    assert metadata(state / 'receipts' / NAME) == old_hash
    write(OUT / 'T02.final.json', snapshot(state))
    summary['cases']['T02'] = dict(local_status='PASS', source_event_id=source_event['event_id'],
        new_event_id=new_id, old_receipt_valid_for_old=True, old_receipt_valid_for_new=False,
        helper_old_exit=positive.returncode, helper_new_exit=negative.returncode,
        new_receipt_exists=False, old_event_bytes_mtime_preserved=True,
        old_receipt_bytes_mtime_preserved=True, event_count=2, receipt_count=1,
        result=result, real_remote_new_version_status='NOT TESTED')

    board = repo / 'BOARD.md'
    board.write_text(board.read_text() + '\nA4 T15: isolated local BOARD maintenance.\n')
    git('add', 'BOARD.md')
    git('commit', '-m', 'A4 T15 unrelated BOARD maintenance')
    t15 = git('rev-parse', 'HEAD')
    message = git('log', '-1', '--format=%B')
    files = git('diff-tree', '--no-commit-id', '--name-only', '-r', 'HEAD').splitlines()
    assert files == ['BOARD.md'] and 'MUSE-ACK' not in message
    state, _, result = invoke('T15', v2, t15, files, message)
    assert result['decision'] == 'silent' and result['reason'] == 'no-change'
    assert result['payload']['unacked_count'] == 0
    assert len(list((state / 'events').glob('*.json'))) == 1
    summary['cases']['T15'] = dict(ACKED_local_status='PASS',
        REJECTED_real_status='NOT TESTED', SUPERSEDED_real_status='NOT TESTED',
        all_terminal_states_status='NOT TESTED', real_remote_unrelated_commit_status='NOT TESTED',
        director_login_is_fixture=True, terminal_event_bytes_mtime_preserved=True,
        receipt_bytes_mtime_preserved=True, result=result)
    write(OUT / 'local-commits.json', dict(baseline=base, T02=v2, T15=t15, remote=None))
    requests = [json.loads(s) for s in (OUT / 'requests.jsonl').read_text().splitlines()]
    assert collections.Counter(x['case'] for x in requests) == {'T02': 3, 'T15': 3}
    assert not any('contents/BOARD.md' in x['path'] for x in requests)
    summary['loopback_requests'] = dict(collections.Counter(x['case'] for x in requests))
finally:
    server.terminate()
    server.wait(timeout=5)
    server_out.close()
    server_err.close()
    after = originals()
    write(OUT / 'originals.after.json', after)
    summary['originals_unchanged'] = before == after
    write(OUT / 'summary.json', summary)

assert summary['originals_unchanged']
print('PASS local T02; PASS local T15 ACKED; NOT TESTED REJECTED/SUPERSEDED and live new-commit scenarios.', flush=True)
