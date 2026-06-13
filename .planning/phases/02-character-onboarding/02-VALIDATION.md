---
phase: 2
slug: character-onboarding
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-13
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> **Context:** native iOS 17 / SwiftUI hackathon (~5h budget). No automated test target exists and CLAUDE.md defers unit tests; the authoritative automated gate is a successful `xcodebuild`, and the phase's value (onboarding feel, avatar fidelity, persistence) is verified visually + by relaunch. This is recorded honestly rather than pretending unit coverage exists.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | none — no XCTest target (5h hackathon; tests deferred per CLAUDE.md). `xcodebuild` compile is the automated gate. |
| **Config file** | `LockedIN.xcodeproj` (synchronized root group — new `.swift` files auto-included) |
| **Quick run command** | `xcodebuild -project LockedIN.xcodeproj -scheme LockedIN -destination 'platform=iOS Simulator,name=iPhone 16' build` |
| **Full suite command** | same build + manual smoke (launch app, run onboarding, relaunch to confirm persistence) |
| **Estimated runtime** | ~30–60s build |

---

## Sampling Rate

- **After every task commit:** Run the quick build command — must end `** BUILD SUCCEEDED **`.
- **After every plan wave:** Build + manual smoke of the slice delivered.
- **Before `/gsd-verify-work`:** Build green + the manual verifications below all pass.
- **Max feedback latency:** ~60 seconds (build).
- **Note:** the harness's standalone SourceKit "cannot find type in scope" diagnostics are false positives without Xcode module context — `xcodebuild` is authoritative.

---

## Per-Task Verification Map

> Populated by the planner/executor as tasks are defined. Most Phase 2 behaviors are visual/manual (see below); the per-task automated signal is "the slice compiles and the screen renders in the simulator."

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| (tbd) | — | — | ONB-01..05 | — | local-only identity data; no network/PII exposure | build + manual | quick build command | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- No test framework to install (none used). 
- *Existing infrastructure (xcodebuild + simulator) covers the automated gate; behavioral verification is manual per the table below.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| First launch shows an animated, skippable onboarding (not static text) | ONB-01 | Visual/animation quality | Fresh install → launch → observe 3 animated beats; confirm a Skip control works |
| Character creator updates a live preview as skin/hair/outfit/accent change | ONB-02 | Visual/interaction | In creator, change each layer → preview updates immediately |
| Avatar renders consistently and carries non-colour status cues | ONB-03 | Visual/accessibility | Inspect avatar; confirm status cue is icon/shape+label, not colour-only (toggle a state if exposed) |
| Chosen avatar + display name represent the user and persist across relaunch | ONB-04 | Requires app restart | Create character + name → force-quit → relaunch → same avatar/name shown, onboarding NOT shown again |
| Onboarding ends with the avatar shown in a cozy isometric room | ONB-05 | Visual | Complete onboarding → confirm payoff renders avatar in the room view |
| Reduce Motion is respected | ONB-01/05 | Accessibility setting | Enable Reduce Motion in simulator → onboarding uses calm fallback (no large motion) |

---

## Validation Sign-Off

- [ ] Build green (`** BUILD SUCCEEDED **`) after every wave
- [ ] All six manual verifications pass before `/gsd-verify-work`
- [ ] Persistence confirmed via real relaunch (ONB-04)
- [ ] Reduce Motion fallback confirmed
- [ ] `nyquist_compliant: true` set once the above hold

**Approval:** pending
