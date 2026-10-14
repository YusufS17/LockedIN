#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swiftc -module-cache-path /tmp/LockedIN-numeric-swift-cache \
  LockedIN/Design/Theme.swift \
  LockedIN/Models/{CharacterAppearance,Cosmetic,StudyCharacter,AvatarStatus,PersonalRoom,Money,CommitmentContract,SettlementRecord,RoomSession,FocusClock,ActiveStudySession}.swift \
  LockedIN/Services/CommitmentService.swift \
  LockedIN/App/StudySessionStore.swift \
  Tests/SessionNumericSafetyChecks.swift -o /tmp/LockedIN-session-numeric-checks
/tmp/LockedIN-session-numeric-checks
