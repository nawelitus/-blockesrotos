# BlockesRotos - design

Android puzzle game built with Godot 4.7. Portrait 720x1280. Offline, no ads, no purchases.
Package id: `com.blockesrotos.game` (permanent once published).

## Core rules (Classic mode, the only mode in v1)

- 8x8 grid. Three pieces are offered at a time; the player drags each one onto the grid.
- A piece is placed only if every cell is free. Pieces are not rotated.
- A completed row or column is cleared. Several lines can clear in one move.
- After all three pieces are placed, three new ones are offered.
- The game ends when none of the offered pieces fits anywhere on the grid.

## Scoring

- 1 point per cell placed.
- 10 points per cleared line, multiplied by the number of lines cleared in the same move
  (1 line = 10, 2 = 40, 3 = 90, ...).
- Combo: consecutive moves that clear lines raise a multiplier (x2, x3, ...). A move that
  clears nothing resets it.
- Empty board after a move: 100 bonus points.
- The best score is saved the moment it is beaten, not at game over.

## Difficulty

- Early moves offer easy pieces, and at least one offered piece always fits.
- As the score rises, larger and more awkward pieces become more likely.

## Presentation

- UI text in neutral Spanish. Code, comments and docs in English.
- Three skins from `GameSkin` resources: wood, colorful, dark-neon. No fixed colors in scenes.
- Sounds are synthesized in code; haptics through the Godot vibration API.
- All art is drawn in code or original SVG. No assets from other games.

## Out of scope for v1

- Other modes (timed, levels), ads, in-app purchases. Monetization would change the SDK,
  permissions, Data safety form and privacy policy, so it is a separate phase.

## Intellectual property

Only the genre mechanics are reused. The name, icon, art, sounds, texts and screen layouts
are original. The name must not resemble "Block Blast" or any registered mark.
