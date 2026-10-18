# Avatar identity preservation — 2026-10-18

CharacterPersistence now rejects replacement when the stored avatar is unreadable, has the wrong storage type, omits essential legacy fields, contains unknown fields/enum options, or the separate name has the wrong type. Original payload and name remain in their existing keys. Unknown data is not automatically repaired or erased. Supported older single-outfit saves still migrate; current independent garments still round-trip. A separately readable name is restored even if the appearance cannot load.

The wardrobe shows a scrollable explanation and close action while editing is paused. Home, World and onboarding only apply identities after successful persistence. Existing room/progression/session data is unchanged. This is normal UserDefaults persistence, not an atomic transaction or concurrent-writer guarantee.

Verification:

- `bash Tests/run-study-session-checks.sh`: passed with production sources and disposable preferences, including exact raw payload/name preservation, unknown field/enum rejection, malformed name rejection, legacy outfit migration and current independent garments. Existing session/reward/catalogue checks also passed.
- App and UI target `build-for-testing`: passed. [Build excerpts](build.log).
- Initial sandbox runs blocked Observation compiler plugins and simulator runtime discovery; approved-access retries passed. A model compile restarted after its source changed; the final run passed.
- Targeted simulator attempt reached the first case startup, then Xcode reported `NSMachErrorDomain -308`, simulator launcher server died. The retry also stalled at app launch; the 420-second runner bound stopped its process group. No completed UI assertions or current render inspection. [UI log](ui-run.log).
- `git diff --check`: passed before handoff.

No user saves erased, no deployment, no remote push. Next: recover bounded simulator launch and finish runtime acceptance, then remaining Phase2 system accessibility checks.
