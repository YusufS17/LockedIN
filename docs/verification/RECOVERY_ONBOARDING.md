# Recovery onboarding polish — 2026-10-03

Implementation preserves the six-step flow, saved character IDs, wardrobe customization, display-name persistence and completion flag.

- All onboarding primary controls use shared Studio buttons; readable native fonts follow Dynamic Type. Gallery selection has a visible checkmark and selected accessibility trait.
- Welcome, introduction, reveal and arrival scroll independently of their pinned actions. Gallery heading scrolls with the grid. Keyboard dismissal is interactive; the name field remains editable without a parent tap gesture stealing focus.
- Step badge occupies a reserved header rather than overlaying headings. A 44-point previous-step action allows returning to earlier decisions.
- Removed the misleading Log in action and real-time friend claims. Introduction accurately describes simulated companions and earned furniture.
- Welcome uses the shared personal-room scene and grounded avatar instead of unrelated floating seated bodies over one desk.
- Arrival names the user's room and explains the real earned-upgrade loop.

Stable test identifiers: `onboarding.continue`, `onboarding.skip`, `onboarding.name`, `onboarding.finish`, `onboarding.back`, and `onboarding.avatar.<catalogue ID>`. Customizer controls retain their existing IDs.

Source review and `git diff --check` pass. This agent did not run builds or a simulator; root owns compiled/runtime verification. Real onboarding render inspection and Accessibility XXXL render inspection are required before claiming visual acceptance. Original references remain richer than the procedural character artwork.
