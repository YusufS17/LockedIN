# LockedIN — Product Vision (North Star)

> Recorded 2026-06-15. This is the long-range ambition that guides every phase.
> It does NOT change the v1.0 demo spine's scope; it sets the direction we build toward.

## The aspiration

LockedIN is not "a Pomodoro timer with avatars." The end goal is a **state-of-the-art,
studio-quality game layer** wrapped around a real commitment-to-focus loop — the
production polish people associate with **Pokémon- / Minecraft-tier** indie/AAA games,
but built for studying. Focus is the gameplay; the world is what focus creates.

The user's explicit aim: a **virtual world and characters built out properly**, with a
real **gamification** system and deep **character customization** — not placeholder art,
not a thin reward screen. The rooms, the characters, and the world should feel like a
real game you'd want to open even when you're not studying.

## Pillars

1. **Characters** — rich, customizable avatars (skin, hair, outfits, accessories,
   expressions, animations). Built code-first as scalable pixel-art today
   (`PixelAvatarView`), evolving toward a deep creator + wardrobe. No dependency on
   externally-supplied PNGs — we author the art in-engine. See
   `memory: characters-are-code-drawn-pixel-art`.
2. **Rooms** — the cozy isometric study room (`IsometricRoomView`) becomes a
   customizable personal space (desk, chair, lamp, rug, shelves, plants, posters,
   floors, walls) that visibly grows and reflects the player.
3. **World** — Personal Room → Squad Study Room → Shared District/World. A living,
   isometric world of buildings (Library Hub, Language Café, Science Lab, …) that the
   squad builds together with Focus XP. "The study room is where focus happens; the
   world is what focus creates."
4. **Gamification economy** — Focus XP (earned by genuine, quality participation),
   LockedIN coins (cosmetics, non-withdrawable, never pay-to-win), and building
   progress. Rewards favour completion, break discipline, low distraction, goals, and
   capped streaks — never raw time grinding.
5. **Production quality** — premium dark shell, warm cream cards, gold accents,
   nostalgic-but-modern pixel-art, juicy animation, satisfying reveals. Every screen
   should feel hand-crafted.

## How we get there (sequencing)

- **Build functional structure first, then make it beautiful.** Land the systems
  (progression, persistence, world model, customization data) as real working code, then
  iterate hard on the game/visual polish on top. This is the user's stated order.
- **Code-drawn art, scaled up over time.** Start with the pixel-art renderer we have;
  deepen it (more parts, palettes, animation frames) rather than waiting on assets.
- **Local-first.** World + coin progress persist on-device (UserDefaults/SwiftData per
  CLAUDE.md); networked Squad/District is a later milestone needing a backend.

## Guardrails (unchanged)

No deceptive buttons, always an honest emergency exit, no exposure of private
app/usage data, no harassment, no chance-based financial outcomes. The £ commitment
loop stays money-correct (Int pence, explicit settlement) — the game layer is a reward
and navigation layer, never a casino.

## Reference

Detailed world-layer spec: `.planning/reference/world-layer-prompt.md` (approved as the
v2 "World" milestone). Roadmap Phase 7 is the local-first MVP of this vision.
