# Home/setup accessibility and usability recovery pass

Implemented 2026-10-03. This is a focused code pass preserving the existing journey, saved models, route identifiers and pixel artwork.

## Changes

- Home greeting scales with the user's text size. Body captions, editor routes, room statistics and level badges use scalable text styles.
- At accessibility text sizes, the greeting, avatar/decorating routes, room statistics, demo club presentation and progression details stack vertically instead of squeezing text beside artwork.
- Study setup scales its title, labels, descriptive text and duration values. Preview artwork, seats description and duration choices stack at accessibility sizes; minus/count/plus remain one coherent control row.
- Subject and goal fields have explicit VoiceOver names and character-limit hints. Empty required inputs show an explanation for the disabled start action.
- Decorative avatar previews and numbered step markers do not create extra VoiceOver stops. Seat controls announce their current seat count; level and progress have readable labels.
- Shared headers and section titles expose heading traits; shared selected inventory tiles expose selection traits.
- Shared primary/secondary buttons permit wrapped labels with vertical padding. The Home coin control now has a minimum 44-point target.

## Verification and limits

`git diff --check` passed after edits. No simulator, Xcode build, UI automation or physical-device VoiceOver check was run by this agent; the coordinating agent owns integration and runtime verification.

Suggested integration inspection: default text size Home and solo/group setup; accessibility XXXL Home and both setup variants, including long subject/goal and the eight-seat boundary. Check that start actions stay reachable, duration labels remain intact, and selected traits and field names read correctly with VoiceOver. Inspect all shared StudioButtonStyle callers because its wrapped-label padding applies app-wide.

This pass does not establish comprehensive app-wide Dynamic Type or physical-device accessibility acceptance. Wardrobe/decorating grids and live/results screens remain separate review work.
