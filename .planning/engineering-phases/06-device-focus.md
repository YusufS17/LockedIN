# Phase 6 — native focus controls and device readiness

Prerequisite: verify supported capabilities/entitlements against current primary Apple documentation; obtain an available supported physical iPhone and appropriate signing/provisioning. Simulator behaviour does not prove enforcement.

1. Capability Verifier researches supported APIs, entitlement/process requirements and exact limits; save links/date and distinguish capability from approval/availability.
2. Focus Builder implements `FocusControlAdapter` with honest permission, denial, unsupported and override flows. Aggregate events expose only permitted state; no specific apps/sites/messages are shared with friends.
3. UI Builder makes consent and focus status understandable. Keep timer-only study available where enforcement is unavailable; do not label simulation as blocking.
4. Device Verifier tests authorisation, denial/revocation, actual enforcement, overrides, relaunch, suspension and interruption on supported physical hardware. Verify access/privacy with two actual accounts where shared states are involved.
5. QC checks claims against evidence, accessible navigation, Reduce Motion, supportive/competitive privacy, lifecycle durability and release configuration.

Exit: any enforcement claim names only tested capability; device evidence supports it; failures/overrides are visible and recoverable. Full beta release requires a separate user deployment/distribution decision. Code push does not authorise distribution, new entitlements/accounts or production data changes.
