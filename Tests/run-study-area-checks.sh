#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swiftc -module-cache-path /tmp/LockedIN-swift-cache \
  LockedIN/Models/StudyAreaLayout.swift Tests/StudyAreaLayoutChecks.swift \
  -o /tmp/LockedIN-study-area-checks
/tmp/LockedIN-study-area-checks
