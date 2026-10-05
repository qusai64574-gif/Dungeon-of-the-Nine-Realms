# Dungeon of the Nine Realms

A 2D roguelike dungeon crawler built in **Godot 4.7** (GDScript, `gl_compatibility` renderer).
Descend through seven themed biomes, fight monsters that telegraph their attacks, loot
everything, and die a lot.

---

## Running it

```bash
flatpak run org.godotengine.Godot --path /home/qusai13q/roguelike-game
```

Or open the project in the Godot editor (`project.godot`) and press F5.

---

## Controls

| Input | Action |
|---|---|
| `WASD` / arrows | Move |
| Left mouse button | Melee slash (arc in front of you, can crit) |
| Right mouse button | Ranged bolt |
| `Esc` | **Pause menu** (resume / save / settings / quit to menu) |

---

## Menus & saving

**Main menu** — New Run, Continue, Settings, Bestiary, Quit. Shows your best depth,
total kills and run count. *Continue* is greyed out when there's no save.

**Pause menu** (`Esc`) — freezes the world. Resume, Save Now, Settings,
Save & Quit to Menu, Quit Game. Shows your current run line.

**Auto-save** — the in-progress run is written to disk every 20 seconds and on
every floor change and kill, plus on a manual "Save Now". Death or victory clears
the save (it's a roguelike — the run is consumed), and the meta stats
(best depth / total kills / total runs) persist forever.

**Settings** — master volume, brightness, camera zoom, damage numbers, screen
shake. Saved to disk and re-applied on launch. Brightness is applied both to the
world shader and the tile draw, so it stacks with the per-tile light falloff.

Save files live in the Godot user dir:

```
~/.var/app/org.godotengine.Godot/data/godot/app_userdata/Dungeon of the Nine Realms/
    settings.cfg    preferences
    save_run.cfg    the in-progress run (auto-saved)
    meta.cfg        best depth, total kills, total runs
```

Delete `save_run.cfg` to force a fresh start.

---

## The Admin Console

Eight pages of cheats, all live — they take effect the moment you flip them.

| Page | What's in it |
|---|---|
| **Player** | God mode, auto-heal, infinite gold, loot magnet, heal/+max HP/+gold/+levels, kill-self test |
| **Power** | One-hit kill, damage / crit / crit-mult / lifesteal / armour / speed / XP multipliers, no-cooldown, projectiles-per-shot (up to 24), projectile speed. Plus presets: **GOD BUILD**, **GLASS CANNON**, **SPEEDRUNNER**, **NUKE MODE**, reset |
| **Enemies** | Freeze all monsters, monster speed multiplier (0–4×), kill-all, NUKE with VFX, live monster census |
| **Spawner** | Spawn any of the 14 monster types ×N, spawn waves, spawn a boss, spawn any of 28 items ×N, chests, "every item ×5" |
| **World** | Reveal map, teleport to exit, regenerate floor, descend, jump to any depth, depth +10, switch biome theme (all 7) |
| **Bestiary** | Full stat block + flavour text for every monster, with a one-click "spawn ×3" per entry, plus the boss schedule |
| **Telemetry** | Live run stats (depth, kills, gold, time, level, rooms, alive monsters, FPS) and engine stats (draw calls, memory, object count) |
| **System** | Restart run, respawn, save/load cheat state to disk, camera zoom, screen-shake test, controls, about |

Cheat flags persist to `user://dungeon_run.cfg` via **System → Save cheats to disk**, so
god mode survives a restart if you want it to.

---

## Game systems

**Procedural generation** (`scripts/dungeon_gen.gd`) — rooms are placed with rejection
sampling, connected by L-shaped corridors, and the exit is placed in whichever room is
farthest from spawn. Room count scales with depth (8 → 20).

**Seven biome themes** — `default`, `dark`, `fire`, `ice`, `forest`, `temple`, `rainbow`.
Each has its own floor, wall, door and ladder tiles, and rotates as you descend.

**Fog of war** — Bresenham line-of-sight from the player, radius 9 tiles. Unexplored
tiles aren't drawn at all; explored-but-unseen tiles render dim and blue-tinted. Standing
inside a room reveals that room on the minimap.

**Monsters are deliberately slow.** This was an explicit design constraint. Player move
speed is **132 px/s**; monsters run **18–34 px/s** — roughly a quarter of your speed.
The fastest monster in the game (`goblin`, `imp`, `orc_warrior`, `chort` at ~30–34 px/s)
still can't catch a walking player. They close in, stop at attack range, telegraph, and
commit. Casters keep their distance and throw instead of chasing. `GameState.enemy_speed_mult`
exposes the multiplier if you want them faster — the admin panel starts it at 1.0×.

**Monsters spawn only inside rooms** — never in corridors, never in a wall, never
outside the map. `DungeonGen.room_cells()` restricts spawning to room interiors with a
1-tile margin.

**Bosses fight in an arena.** On depths 3/6/9/12/15 the boss spawns at the centre of the
**largest room** on the floor, with up to 3 guards placed in the same room — so it's a
set-piece fight, not a corridor ambush.

**Size and collision are tuned to the tile grid.** Every actor is sized in *pixels*
(`size_px`), not by raw sheet dimensions, so a 16×28 knight and a 32×36 ogre both come
out sane: player 26px (≈1.6 tiles), trash monsters 19–22px, elites 28px, bosses 40px.
Collision radii are 5px for the player and most monsters, 6.5px for elites, 8px for
bosses. Feet are anchored to the collision point, so nobody floats or sinks.

**Fog of war hides entities, not just tiles.** Sight is Bresenham line-of-sight (radius
9). Unexplored tiles aren't drawn at all; explored-but-unseen tiles render dim and
blue-tinted. Crucially, monsters and loot are **culled from view** when outside your
sight, so nothing is visible through a wall. Standing in a room reveals that room on the
minimap.

**14 monster types** with distinct stat blocks, behaviours (`chase` / `caster` / `wander`)
and elite tiers, scaling with depth. **5 bosses** on depths 3, 6, 9, 12 and 15.

**Loot** — coins, health potions, gems, swords (5 variants), armour, helmets, shields,
rings, necklaces, scrolls, keys, and chests that spill a small pile when opened. Items
have distinct effects: swords add attack, armour adds damage reduction, rings add crit,
necklaces add lifesteal.

**Progression** — XP curve, levels grant +12 max HP and +3 attack. A run ends at depth 15
(victory) or on death, with a stats screen and instant restart.

**Damage numbers** — normal hits, crits (larger, orange, with a `!`), heals (green `+`),
and damage taken (red `-`), all with outlines so they read over any background.

---

## HUD design

The HUD follows the conventions the research surfaced, rather than inventing a layout:

- **Edge-anchored, centre clear.** Vitals bottom-left, run info (depth + biome) top-left,
  minimap top-right, run counters bottom-right, ability cards bottom-centre.
- **Every element carries its own contrast guarantee** — dark scrim panels behind text
  plus black outlines on every glyph, so it survives the brightest and darkest rooms.
- **Colour never carries meaning alone.** The health bar changes colour *and* length,
  and the heart icon switches between full / half / empty silhouettes.
- **Hierarchy by urgency.** Health is the largest persistent element; the low-health state
  pulses the screen-edge vignette and turns the bar orange→red.
- **Animation only on change, never at rest.** HUD elements don't jump around.
- **Progressive disclosure** — the boss bar only exists when a boss does; toasts fade.

---

## Assets

All art is **CC0 (public domain)** — free for commercial use, no attribution required.
Attribution is given anyway because the artists earned it.

| Source | What | License |
|---|---|---|
| [Kenney](https://kenney.nl) via the [shorepine/kenney](https://github.com/shorepine/kenney) mirror | UI Pack (9-slice panels, buttons), Fantasy UI Borders, Cursor Pack | CC0 |
| [0x72](https://0x72.itch.io/dungeontileset-ii) dungeon tiles, via [Dungeon-CampusMinden/Dungeon](https://github.com/Dungeon-CampusMinden/Dungeon) | 669 dungeon tiles across 7 biomes, 21 animated characters, 273 items, 118 objects, HUD, emotes | CC0 |
| [Google Fonts](https://fonts.google.com) | Cinzel (titles), Inter (UI), Pixelify Sans | OFL |

Total: **~2,450 sprite files**. Character animation frames come from the asset pack's own
JSON descriptors (`assets/sprite_manifest.json` is generated from them), so frame geometry
is exact rather than guessed.

---

## Project layout

```
roguelike-game/
├── project.godot                  # autoloads, input, renderer, window
├── scenes/main.tscn               # entry scene (a single Node2D)
├── assets/
│   ├── sprite_manifest.json       # generated: per-character animation geometry
│   ├── fonts/                     # Cinzel, Inter, Pixelify Sans
│   ├── kenney/                    # CC0 UI chrome
│   └── dungeon_pack/              # CC0 tiles, characters, items, HUD
└── scripts/
    ├── autoload/
    │   ├── input_setup.gd         # registers every input action at runtime
    │   ├── event_bus.gd           # global signal bus — no hard cross-references
    │   └── game_state.gd          # run state, stats, cheat flags, save/load
    ├── assets.gd                  # single source of truth for asset paths
    ├── ui_theme.gd                # palette, styleboxes, full Theme
    ├── dungeon_gen.gd             # procedural rooms + corridors
    ├── enemy_db.gd                # monster + boss database
    ├── actor.gd                   # grid movement with axis-separated collision
    ├── player.gd                  # input, melee, ranged, i-frames
    ├── enemy.gd                   # AI behaviours, slow pursuit, death
    ├── projectile.gd              # bolts and fireballs with trails
    ├── pickup.gd                  # loot, magnet, chest spill
    ├── hit_fx.gd / floating_text.gd
    ├── level.gd                   # tile rendering, fog of war, spawning, cheats
    ├── camera_rig.gd              # smooth follow, look-ahead, screen shake
    ├── hud.gd                     # the HUD
    ├── admin_panel.gd             # the admin console
    ├── main.gd                    # orchestrator + game-over screen
    └── dev_capture.gd             # dev-only screenshot tool (no-op in normal play)
```

Architecture notes: everything talks through `EventBus` signals rather than node paths,
so the HUD and admin panel never hold a hard reference to gameplay. Movement resolves
against the tile grid with per-axis separation (no physics bodies), which means actors
slide along walls instead of sticking and there's no tunnelling at high speed.

---

## Dev tooling

`dev_capture.gd` is a screenshot autoload that does nothing unless you pass a flag:

```bash
# capture the game after 200 frames and quit
flatpak run org.godotengine.Godot --path . -- --shot=/path/out.png --shot-frames=200

# same, but with the admin console open
flatpak run org.godotengine.Godot --path . -- --shot=/path/out.png --shot-frames=200 --shot-admin
```

Note: under Flatpak, write screenshots to a path under `$HOME` — the sandbox has its own
private `/tmp`, so `/tmp/...` silently lands somewhere you can't read.

---

## Verification

Every script was syntax-checked individually (`godot --headless --check-only --script`)
and the game boots clean with **zero script errors** in headless *and* windowed mode.
Both the gameplay view and the admin console were captured and visually inspected.

Known gap: input-driven gameplay (actually holding WASD and clicking) was not simulated
end-to-end in this environment — the run was verified by boot, render, and inspection
rather than by a scripted playthrough.
