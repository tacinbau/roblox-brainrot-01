[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/tacinbau/roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/tacinbau/roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

# Brainrot Bazaar

A 3D Roblox brainrot collector in the spirit of Steal a Brainrot, built entirely
from Parts, colours, lighting and GUI — no catalog assets, no decals, no meshes,
no sounds. You play in a bright plaza under a 3D camera, claim absurd meme-born
characters off a central conveyor belt, park them on your own base, and watch
the Cash tick up at their $/s while rivals try to steal them and a giant wave
sweeps the map.

## The loop

1. **Claim** — a new brainrot spawns on the conveyor every 7 seconds and walks
   ~45 seconds across the plaza. Touch it (or click it) to send it to your first
   free base slot.
2. **Earn** — every brainrot on your base pays its $/s into your Cash, once a
   second, forever. Rarer brainrots pay far more.
3. **Climb** — 11 characters across 7 rarities (Common to Secret), 4 mutations
   (Normal, Golden 2x, Diamond 5x, Rainbow 10x), 6 free base slots plus 4 more
   bought with Cash, and rebirths that reset everything for x2 income each.
4. **Steal** — touch a brainrot in another player's base and hold still for 3
   seconds to pick it up and carry it home. The owner can slap you with the
   Slap Glove to knock you down and make you drop it.
5. **Survive** — every 180 seconds the Brainrot Wave sweeps the plaza. Caught
   outside your base, you are knocked down for 3 seconds and drop anything you
   are carrying. Your base is the safe zone.

## The cast

| Character | Rarity | $/s |
| --- | --- | --- |
| Sock Goblin | Common | 1 |
| Pigeon Professor | Common | 3 |
| Banana Bandit | Uncommon | 8 |
| Noodle Ninja | Uncommon | 15 |
| Cactus Cowboy | Rare | 30 |
| Disco Duck | Rare | 55 |
| Pizza Pirate | Epic | 100 |
| Toilet Tornado | Epic | 180 |
| Sir Cappuccino | Legendary | 350 |
| Grandma's WiFi | Mythic | 750 |
| Golden Toilet King | Secret | 2000 |

Spawn weights: Common 40%, Uncommon 28%, Rare 16%, Epic 9%, Legendary 5%,
Mythic 1.5%, Secret 0.5%. Mutations on spawn: Normal 80%, Golden 12%,
Diamond 6%, Rainbow 2%.

## Shop (bought with Cash)

- **Slap Glove** $100 — slap thieves to make them drop your brainrots
  (click the glove, or press E).
- **Speed Coil** $500 — +8 walk speed, forever.
- **Base Lock** $1,000 — nobody can steal from your base for 60 seconds.
- **Lucky Charm** $2,500 — mutation luck doubled for 5 minutes.

**Rebirth** costs $25,000 x (rebirths + 1): resets Cash and your collection,
multiplies ALL income x2 per rebirth, and grants a title shown over your
character (Rookie Collector, Brainrot Boss, Meme Lord, ...).

## The world

A bright plaza on a big baseplate: a central conveyor belt down the middle, 8
player base plots around it (each with its own colour, flag and owner label),
a spawn area under an entrance arch, decorative trees and warm lamps, bright
warm lighting. Your character spawns normally in the 3D world and runs around
it under the default camera.

## How to run it

- **Build the place** (Rojo 7.7.1): `rojo build default.project.json --output game.rbxl`
- **Play it**: open `game.rbxl` in Roblox Studio and press Play, or publish it
  as a Public experience.
- **Hand it in** (Node 22): `mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts`
  — copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `out/` and
  writes `out/dossier.json` with `vendor/makefun-roblox.ts`.

## Layout

- `src/shared/BrainrotData.luau` — every number the game runs on: the cast,
  rarities, mutations, prices, wave timing.
- `src/server/Main.server.luau` — remotes, HUD snapshots, income tick, saves.
- `src/server/Conveyor.luau` — spawning, belt movement, claiming, stealing.
- `src/server/CharacterFactory.luau` — builds each brainrot Model from Parts.
- `src/server/PlayerState.luau` — one record per player, leaderstats, saves.
- `src/server/Wave.luau` — the Brainrot Wave: warning, wall, knockdowns.
- `src/server/Shop.luau` — shop buys, slap, rebirths, extra base slots.
- `src/client/GameClient.client.luau` — top bar, collection and shop panels,
  wave banner, notifications, steal progress, tutorial hint.
- `default.project.json` — the Rojo project: the plaza, belt, bases, trees,
  lamps and arch, plus the service mounts.
- `main.ts` — the entry program: copies the game to `/output` and writes the dossier.
- `PLAY.json` — the link to the published place (filled in once published).

Progress (Cash, rebirths, unlocked slots, owned items) saves to a DataStore in
a `pcall` and never depends on the save working; your collection is earned
fresh every session.

<sub>Entered on [make.fun](https://make.fun/?ref=cranndvt&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
