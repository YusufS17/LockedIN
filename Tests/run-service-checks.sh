#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
fixture_dir="$(mktemp -d "${TMPDIR:-/tmp}/LockedIN-services.XXXXXX")"
trap 'rm -rf "$fixture_dir"' EXIT
swiftc -module-cache-path "$fixture_dir/module-cache" \
  LockedIN/Models/{Money,CommitmentContract,SettlementRecord,FocusEvent}.swift \
  LockedIN/Services/{CommitmentService,MockCommitmentService,FocusControlAdapter,MockFocusControlAdapter}.swift \
  Tests/ServiceBoundaryChecks.swift -o "$fixture_dir/service-checks"
"$fixture_dir/service-checks"
