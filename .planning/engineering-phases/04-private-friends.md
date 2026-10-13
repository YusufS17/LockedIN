# Phase 4 — real private friend sessions

Prerequisite: select/authenticate a backend provider and create an approved development environment. Existing `docs/PRIVATE_FRIENDS_BETA.md` and `Tools/FriendsPrototype` define contracts; they are not production networking. No deployment is authorised by the current push request.

| Slice | Builder deliverable | Verifier/QC acceptance |
| --- | --- | --- |
| Account/admission | Provider adapter and session membership boundary (new app service files), private invitations, explicit authenticated identity mapping | Two real accounts, expired/reused invite tests, unauthorised third account cannot read/join |
| Shared intent | Transport permitted subject/goal and aggregate focus states; preserve frozen intent for a running session | No app/site/message details sent; session change rules enforced |
| Authoritative session | Server lifecycle and revisions, roster capacity, stable participant UUID mapping and completion rules | Retry/reconnect retains participant reward identity; local fixture is not evidence of server authority |
| Presence/reconnect | Durable client cache/reconciliation, ordering/retry/backoff and honest disconnected UI | Airplane mode/network loss, app termination and reconnect do not duplicate membership or roll back shared state |
| Native UI adapter | `StudySessionStore`/flow and room scene consume authenticated state without removing the solo path | Two accounts/devices see the intended same private room and actual changes; simulations remain separately labelled |

Lead coordinates model/server/UI ownership and reviews deployment/account costs with the user before provisioning or publishing. Verifier exercises adversarial admission/retries against development data. QC audits privacy, stability, labels and reward identity; cloud fixtures cannot close two-device acceptance.

Exit: actual private friends can join and study together with tested reconnection and access boundaries. App blocking and shared earned furniture are separate gates.
