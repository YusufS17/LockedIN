#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swiftc -module-cache-path /tmp/LockedIN-swift-cache \
  LockedIN/Design/Theme.swift \
  LockedIN/Models/{CharacterAppearance,Cosmetic,StudyCharacter,AvatarStatus,PersonalRoom,Money,CommitmentContract,SettlementRecord,RoomSession,Progression,WorldState}.swift \
  LockedIN/App/WorldStore.swift \
  LockedIN/Services/CommitmentService.swift \
  Tests/WorldSemanticChecks.swift -o /tmp/LockedIN-world-semantic-checks
/tmp/LockedIN-world-semantic-checks
