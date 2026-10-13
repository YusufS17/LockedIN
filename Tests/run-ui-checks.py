#!/usr/bin/env python3
"""Run the built UI checks with a wall-clock bound; never erase simulator/app data."""
import argparse
import os
from pathlib import Path
import signal
import subprocess
import tempfile

def positive_seconds(value):
    try:
        seconds = int(value)
    except ValueError as error:
        raise argparse.ArgumentTypeError("Use a positive whole number of seconds") from error
    if seconds <= 0:
        raise argparse.ArgumentTypeError("Use a positive whole number of seconds")
    return seconds


parser = argparse.ArgumentParser()
parser.add_argument('--device', required=True, help='Existing simulator UUID')
parser.add_argument('--timeout', type=positive_seconds, default=900)
parser.add_argument('--test-timeout', type=positive_seconds, default=180, help='Per-case allowance, bounded overall by --timeout')
parser.add_argument('--only-testing', action='append', help='Optional target/class/method to rerun a specific check')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
output = Path(tempfile.mkdtemp(prefix='LockedIN-ui-checks-'))
command = [
    'xcodebuild', '-project', 'LockedIN.xcodeproj', '-scheme', 'LockedIN',
    '-configuration', 'Debug', '-sdk', 'iphonesimulator', '-derivedDataPath', '/tmp/LockedIN-codex-build',
    '-destination', f'platform=iOS Simulator,id={args.device}', '-destination-timeout', '20',
    '-parallel-testing-enabled', 'NO', '-test-timeouts-enabled', 'YES',
    '-default-test-execution-time-allowance', str(args.test_timeout),
    '-maximum-test-execution-time-allowance', str(max(240, args.test_timeout)),
    '-resultBundlePath', str(output / 'OfflineLoop.xcresult'),
    'CODE_SIGNING_ALLOWED=NO', 'test-without-building',
]
for selected_test in args.only_testing or []:
    command.append(f'-only-testing:{selected_test}')
print(f'UI log: {output / "run.log"}', flush=True)
print(f'Result bundle: {output / "OfflineLoop.xcresult"}', flush=True)
with (output / 'run.log').open('w') as log:
    process = subprocess.Popen(command, cwd=root, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
    try:
        code = process.wait(timeout=args.timeout)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGINT)
        try:
            process.wait(timeout=20)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait()
        print(f'TIMEOUT: stopped this test process group after {args.timeout}s; simulator data preserved.', flush=True)
        code = 124
print(f'UI checks exit: {code}', flush=True)
raise SystemExit(code)
