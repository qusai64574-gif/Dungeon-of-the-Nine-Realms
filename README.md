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
