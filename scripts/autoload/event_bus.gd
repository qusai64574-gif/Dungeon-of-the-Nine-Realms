extends Node
## Global signal bus. Every system talks through here so nothing needs a
## hard reference to anything else.

# --- Player vitals ---------------------------------------------------------
signal hp_changed(current: int, maximum: int)
signal player_damaged(amount: int, source: Vector2)
signal player_healed(amount: int)
signal player_died
signal player_leveled(level: int)
signal xp_changed(current: int, needed: int, level: int)
signal stats_changed

# --- Economy / progress ----------------------------------------------------
signal gold_changed(amount: int)
signal floor_changed(depth: int)
signal run_started
signal run_ended(victory: bool)

# --- Combat ----------------------------------------------------------------
signal enemy_killed(enemy_name: String, position: Vector2, xp: int)
signal damage_number(position: Vector2, amount: int, kind: int)  # kind 0=hit 1=crit 2=heal 3=player
signal boss_spawned(boss: Node, name: String, hp: int, max_hp: int)
signal boss_hp_changed(hp: int, max_hp: int)

# --- World -----------------------------------------------------------------
signal dungeon_generated(grid: Array, rooms: Array, depth: int)
signal message(text: String, colour: Color)

# --- UI / shell ------------------------------------------------------------
signal toast(text: String, colour: Color)
signal admin_toggled(open: bool)
signal cheats_changed
signal request_regenerate
signal request_next_floor
signal request_restart
signal request_to_menu
signal request_pause
signal request_give_up
signal settings_applied

# --- Cheat hooks (admin panel -> gameplay) ---------------------------------
signal cheat_kill_all
signal cheat_reveal_map
signal cheat_teleport_stairs
signal cheat_spawn_enemy(id: String, count: int)
signal cheat_spawn_item(id: String, count: int)
signal cheat_spawn_chest
signal cheat_nuke
signal cheat_full_heal
signal cheat_add_gold(amount: int)
signal cheat_add_xp(amount: int)
signal cheat_set_biome(biome: String)


func toast_msg(text: String, colour: Color = Color(1, 1, 1)) -> void:
	toast.emit(text, colour)


func damage_popup(pos: Vector2, amount: int, kind: int = 0) -> void:
	damage_number.emit(pos, amount, kind)
