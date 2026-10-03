#!/bin/bash
set -euo pipefail
prototype_dir="$(cd "$(dirname "$0")" && pwd)"
fixture_dir="$(mktemp -d "${TMPDIR:-/tmp}/LockedIN-friends.XXXXXX")"
trap 'rm -rf "$fixture_dir"' EXIT
swiftc -module-cache-path "$fixture_dir/module-cache" \
  "$prototype_dir/FriendsProtocol.swift" "$prototype_dir/FriendsChecks.swift" \
  -o "$fixture_dir/friends-checks"
"$fixture_dir/friends-checks"
