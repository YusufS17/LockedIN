# LockedIN execution plan

Started 2026-10-03. The user authorised beginning the remaining phases and autonomous follow-through. This expands the active ROADMAP; it does not replace its acceptance gates. Preserve all existing local work. The offline study-to-earned-upgrade goal is complete with model and simulator UI evidence; no scheduled automation. See docs/verification/OFFLINE_LOOP.md.

## 1. Verify and improve the visible local app — current

Deliver: usable home, wardrobe, decorating, solo/demo-club setup and live room at iPhone size.

- Inspect real screens and record navigation, saved customisation, start, break/resume, early exit and results.
- Improve shared-room spacing, furniture perspective and character layering using the existing production layers.
- Review normal-size screenshots against the saved references. Keep source-art exports separate from app screenshots.
- Build, inspect and fix failures before marking each check complete. A simulator failure must not block independent implementation indefinitely.

Current slice: compact shelves, isometric chair variants, shared-room perimeter furniture, staggered desks and a clear foreground break position. Source-art exports inspected; current build/runtime evidence goes in docs/verification/OCT03_CHECKPOINT.md.

## 2. Finish the room/avatar art family

Deliver: one polished personal room, a readable four-person room, distinct customisable characters and convincing seated poses.

- Refine faces, hair, separate clothing/shoes and desk/chair occlusion.
- Preserve room catalogue identifiers, purchases and avatar selections.
- Verify normal phone size, light/dark scenes, upgrade variants and break placement.
- Keep generated concepts as references, never as flattened replacements for interactive layers.

## 3. Make study sessions durable and truthful — implemented and verified

Deliver: a session can survive relaunch without changing its reward identity, and results reflect recorded events.

- Move the running session out of view-only state into a persisted, versioned session model.
- Store the frozen configuration, full roster (including the existing user participant UUID), focus clock, break state/count, outcome and reward handoff.
- Define and test active, paused, completed and exited transitions; preserve deadlines on background/foreground and relaunch.
- Replace seeded user scores with explained measured values. Companions stay clearly simulated until networking exists.
- Test replay, migration, termination during breaks, expiry while suspended and repeated results using disposable saves.

## 4. Verify the complete offline journey — verified for solo

Deliver: home → goal/setup → study → goal check → results → earned visible upgrade, persisting after relaunch.

- Add the goal check and clear earned-item feedback.
- Verify completion rewards, early-exit/demo exclusions, purchases and restoration together.
- Keep supportive mode free of negative rankings.
- Correct simulated test-stake errors rather than presenting invented successful settlement.
- Record a full interaction walkthrough and screenshots; automated model checks alone are insufficient.

## 5. Build the private friends beta

Deliver: two actual people can join a private room, see permitted aggregate study states and reconnect safely.

- Prepare backend/authentication/access-control design and local fixtures first.
- Implement invites, authoritative room membership/session state, subject/goal sharing, presence and reconnect.
- Preserve server-side reward idempotency and private shared progression.
- Provisioning credentials, choosing paid services and testing on two real devices require the user's available accounts/devices; raise concrete dependencies when reached.

## 6. Add native focus controls

Deliver: supported focus controls with honest permissions and tested enforcement.

- Verify current Apple capability and entitlement requirements before implementation.
- Build permission, selection and override flows; track only permitted aggregate events.
- Verify on supported real devices before claiming app blocking.

## Working agreement for long runs

Proceed with authorised edits, builds, disposable tests and reversible fixes without repeated confirmation. Keep concise updates and checkpoint notes with evidence and next actions. Do not claim background activity once a run has ended. Stop dependent work for missing credentials, required product decisions or actual permission restrictions, while continuing independent authorised work. Never claim all phases complete based on a build or mockup.
