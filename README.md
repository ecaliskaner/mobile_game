# Merge Keep

A pocket-sized, fully offline merge game. No server, no database, no
account — everything runs in the browser and saves to `localStorage`.

## Play it

Just open `index.html` in a mobile browser (or serve the folder with any
static file server, e.g. `python3 -m http.server`). It also works as an
installable PWA ("Add to Home Screen") and caches itself for offline use
via `sw.js`.

## The loop

- **Hatch** — tap the nest to spend 1 ⚡ energy and drop a tier-1 Seedling
  onto the 5x6 board. Energy refills over real time.
- **Merge** — drag one creature onto a matching one to fuse them into the
  next tier (Seedling → Sprout → Clover → ... → Crown Jewel). Merging
  pays coins, with a combo multiplier for chaining merges quickly.
- **Collect** — mature tiles periodically "ripen" (a coin badge appears);
  tap them to bank the coins.
- **Build** — spend coins in the Castle tab on five upgradable buildings
  (Gate, Watchtower, Market, Garden, Treasury), each boosting a different
  stat (max energy, regen speed, coin value, trickle speed, offline cap).
- **Collect & compete with yourself** — a 10-slot Bestiary tracks every
  tier you've discovered, and 10 achievements reward milestones.
- **Come back tomorrow** — a daily login streak grants bonus coins and a
  full energy refill; the game also computes rough offline earnings based
  on how long you were away.

## Design notes

This combines the mechanics most current top-charting mobile games share:
a tactile merge/collection core (Merge Mansion-style drag merging, not
swipe), an idle/incremental resource trickle that rewards short repeat
check-ins, a gacha-free energy gate that paces sessions, a visible
base-building meta-progression (the castle), a collection log, and a daily
streak — all without needing any backend, since the entire game state is a
single JSON blob in `localStorage`.

## Files

- `index.html` — markup / screens
- `style.css` — mobile-first styling, animations
- `game.js` — all game logic (state, rendering, drag/merge, economy)
- `manifest.json`, `sw.js`, `icons/` — PWA install + offline caching
