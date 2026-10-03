#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swiftc -module-cache-path /tmp/LockedIN-swift-cache \
  LockedIN/Design/Theme.swift \
  LockedIN/Models/{CharacterAppearance,Cosmetic,StudyCharacter,AvatarStatus,PersonalRoom,Money,CommitmentContract,SettlementRecord,RoomSession,FocusClock,ActiveStudySession,Progression,WorldState}.swift \
  LockedIN/Services/{CommitmentService,CharacterPersistence}.swift \
  LockedIN/App/{StudySessionStore,WorldStore}.swift \
  Tests/StudySessionChecks.swift -o /tmp/LockedIN-session-checks
/tmp/LockedIN-session-checks
