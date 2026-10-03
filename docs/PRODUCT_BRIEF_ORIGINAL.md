# LockedIN — Product Brief

LockedIN is a **multiplayer study and focus app** built around small private rooms, visible accountability, focus enforcement, and a persistent pixel-art world.

The core idea is:

> **Study with friends in a shared room. Stay focused, or the room records that you cracked. Successful sessions improve your avatar and shared room.**

LockedIN should not feel like another generic Pomodoro timer. Its differentiation comes from combining:

- Serious focus enforcement.
- Small-group social accountability.
- Pixel avatars and persistent room progression.
- Subject and study-goal tracking.
- A dramatic group results reveal.
- Optional commitment/stakes mechanics later.

The product should be **useful before it is playful**. The timer, room state, focus rules, privacy and enforcement logic must work reliably. The game layer exists to make people care about returning.

## Core user experience

The main flow should be:

1. Open LockedIN.
2. See friends who are studying or an upcoming room.
3. Join or create a private room.
4. Choose a study subject.
5. Enter one concrete goal for the session.
6. Choose or accept the room's focus rules.
7. Start the session.
8. Everyone's pixel avatar appears together in the shared room.
9. During the session, avatars visually show whether someone is:
   - Focused.
   - On an authorised break.
   - Receiving a warning.
   - Left early.
   - Finished.
10. Attempts to break focus trigger friction rather than a simple "continue anyway" button.
11. The session ends with a group results reveal.
12. Users earn progress, coins or cosmetic rewards.
13. The group's persistent room improves over time.
14. Users can immediately start or schedule another session.

## The room

The shared room is the heart of LockedIN.

Start with **small private rooms of roughly 2–8 friends**, not giant public rooms. Rooms should use invite codes and require no camera or voice chat.

The shared room should contain everyone's pixel avatars and eventually persistent furniture, trophies and upgrades.

Users should feel:

> "We're all studying in the same place."

without needing to be on camera.

During focus, the game should mostly disappear. Avoid a constant chat, social feed or lots of things to click. Quiet reactions are enough.

## Starting a session

Starting should be extremely fast.

Offer preset sessions such as:

- **25-minute Sprint**
- **50-minute Serious Lock-In**
- **90-minute Deep Session**

Before starting, the user only really needs to set:

- Subject.
- Session goal.
- Optional checklist of up to three items.
- Focus strictness.

Do not turn room creation into a complicated configuration form. Advanced settings can sit behind **Custom**.

## Focus modes

There should eventually be three simple enforcement levels:

### Gentle / Supportive

Designed for people who want accountability without punishment.

- Flexible breaks.
- No public negative ranking.
- Personal results can remain private.
- Group receives a shared reward if everyone finishes.

This should be the safest/default experience.

### Serious / Competitive

Designed for friend groups that want stronger accountability.

- Stronger blocking/friction.
- Public focus metrics within the room.
- Users can see results such as "Most LockedIN".
- Light/funny teasing is acceptable only when users explicitly opted into it.

### Contract

The strongest mode.

- Rules are frozen before starting.
- The user explicitly accepts the contract.
- Strong warning before breaking the contract.
- Prototype uses fake/test stakes only.

Do **not** implement real-money staking yet.

## Distraction and override flow

Do not use a normal "Are you sure?" popup.

Breaking focus should feel intentional.

Suggested sequence:

1. Show the current commitment.
2. Show remaining warnings.
3. Force a short pause.
4. Ask the user to intentionally choose or state a reason.
5. Explain what consequence will occur.
6. Require hold-to-confirm.
7. Log an aggregate distraction/override event.

Room members should never see which specific app or website someone tried to open.

## Privacy

Privacy is a fundamental product feature.

LockedIN should **not** expose:

- Which app somebody opened.
- Which website they visited.
- Browsing history.
- Contacts.
- Messages.
- Notification contents.

Other people in the room can see only aggregate accountability metrics such as:

- Number of distractions.
- Override count.
- Break time.
- Whether someone left early.
- Completion.
- Focus score.

## Results reveal

The end of the session should feel like an event rather than a boring analytics screen.

Suggested sequence:

### 1. Group achievement

Example:

"4 people protected 186 focus minutes."

### 2. Completion

Example:

"Three passed. One cracked."

### 3. Most focused

Show the highest focus score.

### 4. Biggest distraction culprit

Show aggregate distraction/override numbers only.

### 5. Rewards

Show:

- Coins earned.
- Avatar progress.
- Shared room progress.
- Newly unlocked item/furniture.

### 6. Share

Generate a privacy-safe result card users can send to friends or social media.

Users must be able to disable teasing/public comparison.

## Focus score

Do not rank users purely on how long they studied.

An initial scoring model can roughly consider:

- 40% session completion.
- 20% staying within break allowance.
- 20% distraction count.
- 10% override count.
- 10% stated-goal completion.

The exact formula can change later, but it must be transparent so users understand why they received their score.

## Avatar and progression

Every user creates a pixel avatar.

Customisation can eventually include:

- Hair.
- Skin tone.
- Clothing.
- Accessories.
- Desk.
- Personal room.
- Shared squad room.

Items should mainly be earned through actual focus achievements rather than simply purchased.

The persistent world is important: every real study session should leave some visual evidence of progress.

The **shared room is LockedIN's equivalent of Forest's forest**.

Examples:

- Study → earn coins.
- Complete sessions → unlock clothes or furniture.
- Group sessions → upgrade the shared room.
- Exam challenges → earn trophies.
- Consistency → unlock rare cosmetics.

## Product aesthetic

The overall app shell should feel:

- Modern.
- Premium.
- Simple.
- Trustworthy.

Pixel art should mainly appear in:

- Avatars.
- Rooms.
- Furniture.
- Items.
- Animations.
- Rewards.

Do not make every button/navigation element pixel-art.

Think **premium productivity app wrapped around a small expressive game world**, rather than a retro game with a timer bolted onto it.

## MVP / vertical slice

Do not build the entire vision yet.

Build **one excellent end-to-end session** first.

The initial demo should let someone:

1. Create a pixel avatar.
2. Enter a Demo Room.
3. See 2–4 seeded/simulated friends.
4. Choose a subject.
5. Write a study goal.
6. Accept a fixed 25-minute commitment contract.
7. Authorise a clearly simulated £5 test commitment.
8. Start the focus session.
9. See avatars change state during the session.
10. Trigger simulated distraction attempts.
11. Experience escalating override friction.
12. Finish the session.
13. See a dramatic results sequence.
14. See winner / biggest culprit / transparent statistics.
15. Have the fake test stake returned or forfeited.
16. Earn coins.
17. Unlock or upgrade one avatar item or room object.

The whole demo must work offline with seeded participants if necessary.

## Do not build yet

Avoid scope creep.

Do not build:

- Public rooms.
- Full social feed.
- Direct messaging.
- Video chat.
- Voice chat.
- Flashcard platform.
- AI study coach.
- Full to-do manager.
- Complex room editor.
- Marketplace.
- Multiple currencies.
- University-wide rankings.
- Real-money gambling/stakes.
- Contact access.
- Random messages/calls.
- Full Android/iOS parity before one platform works properly.

## Technical/product principles

Use these as non-negotiable rules while implementing:

1. Useful before playful.
2. One-tap/very fast entry into focus.
3. Private by default.
4. No camera required.
5. Focus rules are frozen before starting.
6. Aggregate accountability, not surveillance.
7. The game largely disappears while studying.
8. Results should be dramatic and shareable.
9. The persistent world reflects genuine effort.
10. Never claim real blocking/tracking functionality that has not actually been implemented.
11. No real-money movement.
12. Supportive mode is a core experience, not an afterthought.

## What Codex should do first

Before changing code:

1. Inspect the entire existing repository.
2. Understand the current architecture, screens, navigation and styling.
3. Compare what currently exists against this brief.
4. Identify:
   - What should be preserved.
   - What needs modifying.
   - What should be removed.
   - What is completely missing.
5. Produce a concise gap analysis.
6. Propose the order in which the vertical slice should be implemented.
7. Only then begin implementation.

Do not rewrite functioning parts of the product unnecessarily. Preserve good existing work and iterate on top of it.

The priority is **not feature count**.

The priority is that one complete LockedIN session feels coherent, polished and genuinely different from an ordinary study timer.