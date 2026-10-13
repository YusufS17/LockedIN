# Active roadmap: LockedIN

Updated: 2026-10-13. Current status: [PROGRESS.md](../PROGRESS.md). Exact handoff: [STATE.md](STATE.md).

This roadmap supersedes the June hackathon sequence, preserved in [archive/ROADMAP-2026-06-13.md](archive/ROADMAP-2026-06-13.md). Product rationale and baseline gaps remain in [PRODUCT_AUDIT.md](../docs/PRODUCT_AUDIT.md). No overall completion percentage is claimed.

Product target: [restored user direction](../docs/USER_DIRECTION.md), with the [original supplied brief](../docs/PRODUCT_BRIEF_ORIGINAL.md) retained as source. Visual quality and eventual real friend sessions are required outcomes.

Detailed implementation sequence: [Execution plan](EXECUTION_PLAN.md), authorised 2026-10-03. The room-spacing/chair slice is implemented and source-art inspected; solo and demo-club iPhone interaction acceptance passed; final art fidelity remains open.

Active phases, Builder/Verifier/QC ownership and acceptance: [PHASES_AND_AGENTS.md](PHASES_AND_AGENTS.md). Phase1 save protection/session validation/accessibility is active; commits and non-force push authorised.

Current engineering sequence and identified defects: [engineering audit and milestones](../docs/ENGINEERING_AUDIT.md), created after the lead-engineer request on 2026-10-13. Maintenance and save/accessibility safeguards precede unapproved art implementation and external-service work. Historical phase plans are reference only.

## Next delivery sequence

**Current visual priority:** the first substantial [character and interface redesign](VISUAL_REDESIGN.md) is implemented and phone-verified ([evidence](../docs/verification/VISUAL_REDESIGN.md)). Continue richer character/room craft and onboarding/accessibility consistency before further private-service implementation. The original mockups’ full quality bar remains open; functional test passes do not close it.

1. **Friends-ready clubs — verified local milestone:** selectable2–8-person demo rooms, legible seating areas, per-person study goals, directional clothing and durable restoration. [Plan](CLUB_EXPANSION_PLAN.md) · [Evidence](../docs/verification/CLUB_EXPANSION.md). Five affected UI cases plus second-area check passed; final phone images inspected.
2. **Real private session:** implement the authenticated service/adapter, durable admission and reconnect, preserve participant/reward identity, then verify two actual accounts/devices. Local contract fixtures cannot close this gate.
3. **Shared earned room:** authoritative individual outcomes and group contributions, persistent shared furniture, replay-safe purchases and reconnect.
4. **Native focus controls:** establish supported platform capabilities, implement honest permission/override flows and verify physical-device enforcement.

Character/room reference fidelity continues alongside these deliveries. Existing solo progress and customisation must remain usable through each phase. No deployment or real-money work is implied by this roadmap.

## 1. Make the current implementation visible — locally verified

- [x] Implement room-centred home, shared study setup, wardrobe, decorating and live-session interface.
- [x] Compile the current app for iPhone Simulator.
- [x] Recover simulator startup/install and capture actual home screen (`docs/verification/simulator-recovery/home.png`, 2026-09-27). Full walkthrough remains separate.
- [x] Inspect home, wardrobe, decorating, solo/group setup and live-session layouts at iPhone size (local-beta simulator evidence).
- [x] Walk through solo navigation, saved customisation, study start, break/resume, early leave and results (October 3 UI evidence).
- [x] Fix observed layout/interaction defects and recheck affected screens (labels, ambient edges, break collision; final solo/group rerun passed).

Acceptance: the user can run and inspect the actual app, screenshots show app screens, and the complete local interaction path has recorded results. Build success alone does not close this milestone.

## 2. Establish the room and avatar art target

- [x] Export existing source artwork and identify concrete differences from the supplied references.
- [x] Compare full runtime screens against saved references; remaining fidelity differences recorded in LOCAL_BETA_TEAM.md.
- [ ] Refine the personal room, four-seat room and customisable character family as separate runtime layers. New character proportions/turned faces/hairstyles/independent clothing and main-flow design are runtime-verified, including tapered hands and2–8-person areas. Richer hair/garment volume, room atmosphere and final reference fidelity remain unfinished.
- [x] Verify current furniture/avatar layering, seated poses, customisation changes and readability on iPhone; final art fidelity is still open.

Acceptance: coherent runtime artwork and visible customisation; a generated flat concept image does not qualify.

## 3. Complete the reliable session core

- [x] Use deadline-based focus timing with paused breaks and task cancellation.
- [x] Distinguish early exit from completion; prevent quick-demo/early-exit completion rewards.
- [x] Persist reward receipts and test duplicate results, normal reload and old-save migration.
- [x] Extract durable session/outcome state from the view and preserve session identity through restoration (production-model and simulator relaunch checks passed).
- [x] Record timer time, breaks and explicit interruption self-reports; replace seeded user scoring with explained timer completion. Native app tracking/overrides remain in phase 6.
- [x] Freeze session rules and test lifecycle accounting, termination/recovery and outcome replay (injected-date model checks plus simulator relaunch; no physical-device soak test).

Acceptance: meaningful lifecycle and scoring tests pass; restored/repeated results cannot duplicate progression. Existing receipt tests do not establish active-session recovery.

## 4. Verify one complete offline study loop

- [x] Personal room → setup → solo or labelled demo club → focus → goal check → results → earned room item.
- [x] Provide explicit self-reported interruptions and labelled simulated companions.
- [x] Audit supportive results for negative public rankings and label remaining simulated data.
- [ ] Complete the broader legacy test-commitment hold audit; settlement failures now report zero confirmed amounts and are regression tested.
- [x] Verify progression and purchases survive relaunch without duplicate awards.

Acceptance: a complete usable offline journey with honest results and persistent progress. Test stakes remain optional demo material.

## 5. Private friends beta

- [x] Plan backend, authentication, access boundaries and deployment requirements ([private-friends contract](../docs/PRIVATE_FRIENDS_BETA.md)); provider/account provisioning remains external.
- [x] Verify isolated membership/reconnect/identity/shared-intent fixtures (83 assertions; no networking or production integration).
- [x] Implement and verify local 2–8-person demo areas, per-person study intent and frozen restoration; labelled simulations only.
- [ ] Implement real private invites, authenticated membership, shared authoritative state and presence/reconnect.
- [ ] Synchronise real participants’ explicitly shared study subject/goal and permitted aggregate focus states.
- [ ] Persist shared-room furniture/upgrades earned through group study.
- [ ] Test on two real devices, including reconnects, retries and reward deduplication.

Acceptance: two real users share the intended room and outcomes; simulated companions do not count as multiplayer.

## 6. Native focus controls

- [ ] Verify platform capabilities and entitlement/permission requirements.
- [ ] Implement supported controls with honest permission and override flows.
- [ ] Verify actual enforcement on supported devices.

Acceptance: make blocking claims only for capabilities actually implemented and tested. Simulation remains labelled until then.

## Later / outside the current slice

Privacy-safe session history and sharing follow reliable outcome data. Real payments, public rooms, feeds, voice/video and a full freeform room editor remain outside the current local slice.

## Maintenance

Update gates after verified milestones. Link evidence or reproducible commands in the handoff. Keep implementation, automated checks and runtime verification distinct; preserve historical planning under `archive/`.


## October3 restart checkpoint

Recovered and committed the accumulated app work; a three-agent polish pass improved onboarding, room atmosphere and Home/setup Dynamic Type. Build/model checks pass; actual welcome/club/large-text renders inspected. Full new onboarding acceptance remains open because simulator cleanup stalled and Xcode then lost the destination. [Exact evidence and next checks](../docs/verification/RECOVERY_POLISH.md). This does not close final reference fidelity or multiplayer gates.


## Next refinement team — verified

Avatar fabric/hair/shoe detail, safer adaptive editors and live/check-in/results readability are implemented. Six targeted journeys have passing evidence, including normal/largest-text onboarding, saved solo upgrade and independent garments. Final3 affected cases and subsequent compact-editor recheck passed; actual/scrolled renders inspected. [Evidence](../docs/verification/CONTINUATION_TEAM.md). Next: smaller iPhone layout acceptance and VoiceOver/Reduce Motion interaction checks, continued reference craft. Real friend networking and original-reference fidelity gates remain open.
