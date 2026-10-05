extends Node
## Dev-only harness. Inert during normal play unless a flag is passed.
##
##   --shot=PATH [--shot-frames=N] [--shot-admin]   capture a screenshot and quit
##   --selftest                                     validate collision vs the tile grid

var _path := ""
var _frames := 120
var _count := 0
var _armed := false
var _open_admin := false
var _selftest := false
var _play := false
var _pause_shot := false
var _strike_shot := false
var _giveup_shot := false
var _admin_shot := false
var _menu_shot := false
var _savetest := false


func _ready() -> void:
	# Keep ticking even while the tree is paused, so we can screenshot the
	# pause menu (and any other paused state).
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			_path = a.substr(7)
		elif a.begins_with("--shot-frames="):
			_frames = int(a.substr(14))
		elif a == "--shot-admin":
			_open_admin = true
		elif a == "--selftest":
			_selftest = true
		elif a == "--shot-play":
			_play = true
		elif a == "--savetest":
			_savetest = true
		elif a == "--shot-pause":
			_play = true
			_pause_shot = true
		elif a == "--shot-strike":
			_play = true
			_strike_shot = true
		elif a == "--shot-giveup":
			_giveup_shot = true
		elif a == "--shot-admin2":
			_play = true
			_admin_shot = true
		elif a == "--shot-menu":
			_play = false
			_menu_shot = true
	if _selftest or _savetest:
		_armed = true
		set_process(true)
		return
	if _path == "":
		set_process(false)
		return
	# Force menu state for plain screenshots (no --play flag)
	if _menu_shot:
		_play = false
	if not _play and not _pause_shot and not _strike_shot and not _giveup_shot and not _admin_shot:
		_play = false
	_armed = true
	print("[dev_capture] armed -> ", _path, " after ", _frames, " frames (admin=", _open_admin, ")")


func _process(_delta: float) -> void:
	if not _armed:
		return
	_count += 1
	if _selftest:
		if _count < 90:            # let the level fully build + settle
			return
		_armed = false
		_run_selftest()
		get_tree().quit()
		return
	if _savetest:
		if _count < 20:
			return
		_armed = false
		_run_savetest()
		get_tree().quit()
		return
	# jump straight into a run for gameplay screenshots
	if _menu_shot and _count == 30:
		# Force menu state - hide everything else
		var main = get_node_or_null("/root/Main")
		if main and main.has_node("MainMenu") and main.has_node("HUD"):
			main.state = main.State.MENU
			var menu = main.get_node("MainMenu")
			menu.visible = true
			main.hud.visible = false
			main.level.visible = false
			main.gameover.visible = false
			main.pause.set_open(false)
			main.admin.set_open(false)
			# Stop any running fade transition
			main.fade.stop()
			# Force redraw
			if menu.has_node("Root"):
				menu.get_node("Root").queue_redraw()
	if _play and _count == 30:
		EventBus.request_restart.emit()
	if _strike_shot and _count == 48:
		# capture mid-strike (bolt lands ~10 frames after the run starts)
		_armed = false
		await RenderingServer.frame_post_draw
		var im2 := get_viewport().get_texture().get_image()
		im2.save_png(_path)
		print("[dev_capture] saved strike -> ", _path)
		get_tree().quit()
		return
	if _pause_shot and _count == 120:
		EventBus.request_pause.emit()
	if _giveup_shot and _count == 40:
		EventBus.request_give_up.emit()
	if _admin_shot and _count == 60:
		EventBus.admin_toggled.emit(true)
	if _count == int(_frames * 0.5) and _open_admin:
		EventBus.admin_toggled.emit(true)
	if _count < _frames:
		return
	_armed = false
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(_path)
	print("[dev_capture] saved=", err == OK, " -> ", _path, " ", img.get_size())
	await get_tree().process_frame
	get_tree().quit()


# ---------------------------------------------------------------------------
# Collision self-test
# ---------------------------------------------------------------------------
func _find_level() -> Node:
	# The Level is a child of Main; walk the whole tree looking for the grid.
	return _search_for_level(get_tree().root)


func _search_for_level(n: Node) -> Node:
	if n.get("grid") != null and n.get("GW") != null:
		return n
	for c in n.get_children():
		var found := _search_for_level(c)
		if found != null:
			return found
	return null


func _run_selftest() -> void:
	var level: Node = _find_level()
	if level == null:
		print("[selftest] NO LEVEL FOUND")
		return

	var grid: Array = level.grid
	var gw: int = level.GW
	var gh: int = level.GH
	var player = level.player
	if player == null:
		print("[selftest] NO PLAYER")
		return

	print("[selftest] grid %dx%d  player cell=%s  radius=%.2f  player_pos=%s" % [
		gw, gh, str(player.cell_of(player.global_position)), player.radius, str(player.global_position)])

	# --- compare walkable(cell) against can_stand_at(cell centre) -----------
	var walkable_but_cant_stand := 0
	var wall_but_can_stand := 0
	var samples_a: Array = []
	var samples_b: Array = []

	for y in gh:
		for x in gw:
			var w: bool = DungeonGen.walkable(grid, x, y)
			var centre := Vector2(x * 16 + 8, y * 16 + 8)
			var stand: bool = player.can_stand_at(centre)
			if w and not stand:
				walkable_but_cant_stand += 1
				if samples_a.size() < 8:
					samples_a.append("(%d,%d)" % [x, y])
			elif not w and stand:
				wall_but_can_stand += 1
				if samples_b.size() < 8:
					samples_b.append("(%d,%d)" % [x, y])

	print("[selftest] walkable-but-CANNOT-stand : %d  %s" % [walkable_but_cant_stand, str(samples_a)])
	print("[selftest] WALL-but-CAN-stand        : %d  %s" % [wall_but_can_stand, str(samples_b)])

	# --- can the player actually step in each direction? --------------------
	var pc: Vector2i = player.cell_of(player.global_position)
	var dirs := {"right": Vector2(1, 0), "left": Vector2(-1, 0), "up": Vector2(0, -1), "down": Vector2(0, 1)}
	print("[selftest] from spawn cell %s:" % str(pc))
	for dname in dirs:
		var d: Vector2 = dirs[dname]
		var tc := pc + Vector2i(int(d.x), int(d.y))
		var tw: bool = DungeonGen.walkable(grid, tc.x, tc.y)
		var probe: Vector2 = player.global_position + d * 6.0
		var can: bool = player.can_stand_at(probe)
		print("    %-6s neighbour_walkable=%-5s can_step=%-5s" % [dname, str(tw), str(can)])

	# --- ASCII map around the player ---------------------------------------
	print("[selftest] map around spawn (# wall, . floor, > stairs, P player):")
	var rr := 14
	for y in range(maxi(0, pc.y - rr), mini(gh, pc.y + rr + 1)):
		var line := ""
		for x in range(maxi(0, pc.x - rr), mini(gw, pc.x + rr + 1)):
			if x == pc.x and y == pc.y:
				line += "P"
			elif grid[y][x] == DungeonGen.Cell.WALL:
				line += "#"
			elif grid[y][x] == DungeonGen.Cell.STAIRS:
				line += ">"
			else:
				line += "."
		print("   ", line)

	# --- entity audit -------------------------------------------------------
	var outside := 0
	var in_wall := 0
	var enemies := 0
	for e in level.entities.get_children():
		if e is Enemy:
			enemies += 1
			var c: Vector2i = level.cell_of(e.global_position)
			if c.x < 0 or c.y < 0 or c.x >= gw or c.y >= gh:
				outside += 1
			elif not DungeonGen.walkable(grid, c.x, c.y):
				in_wall += 1
	print("[selftest] enemies=%d  in_wall=%d  outside_bounds=%d" % [enemies, in_wall, outside])

	# --- loot audit ---------------------------------------------------------
	var loot_in_wall := 0
	var loot_total := 0
	for p in level.loot.get_children():
		if p is Pickup:
			loot_total += 1
			var c2: Vector2i = level.cell_of(p.global_position)
			if c2.x < 0 or c2.y < 0 or c2.x >= gw or c2.y >= gh or not DungeonGen.walkable(grid, c2.x, c2.y):
				loot_in_wall += 1
	print("[selftest] loot=%d  loot_in_wall_or_out=%d" % [loot_total, loot_in_wall])

	# --- animation fps sanity ----------------------------------------------
	var m := Assets.manifest()
	var fps_seen := {}
	for k in m:
		for aname in m[k]["anims"]:
			var f: float = float(m[k]["anims"][aname].get("fps", 0.0))
			fps_seen[int(round(f))] = true
	var keys: Array = fps_seen.keys()
	keys.sort()
	print("[selftest] distinct anim fps values in manifest: ", str(keys))
	print("[selftest] DONE")


## Save round-trip test: write a run, read it back, compare fields.
func _run_savetest() -> void:
	var sm := get_node_or_null("/root/SaveManager")
	if sm == null:
		print("[savetest] NO SaveManager")
		return
	GameState.depth = 7
	GameState.gold = 4321
	GameState.kills = 99
	GameState.level = 5
	GameState.base_damage = 33
	GameState.armour = 12
	GameState.crit_chance = 0.44
	GameState.max_hp = 250
	GameState.hp = 180
	GameState.run_seed = 123456
	sm.save_run()
	print("[savetest] has_save=", sm.has_save())

	# clobber then reload
	GameState.depth = 0
	GameState.gold = 0
	GameState.kills = 0
	GameState.base_damage = 0
	GameState.run_seed = 0
	var ok: bool = sm.load_run()
	print("[savetest] load ok=", ok)
	print("[savetest] depth=%d (want 7)  gold=%d (want 4321)  kills=%d (want 99)  dmg=%d (want 33)  seed=%d (want 123456)" % [
		GameState.depth, GameState.gold, GameState.kills, GameState.base_damage, GameState.run_seed])
	var all_ok := GameState.depth == 7 and GameState.gold == 4321 and GameState.kills == 99 \
		and GameState.base_damage == 33 and GameState.run_seed == 123456
	print("[savetest] RESULT=", "PASS" if all_ok else "FAIL")

	# settings round-trip
	sm.brightness = 0.77
	sm.camera_zoom = 3.3
	sm.show_damage_numbers = false
	sm.save_settings()
	sm.brightness = 1.0
	sm.camera_zoom = 2.4
	sm.show_damage_numbers = true
	sm.load_settings()
	var s_ok: bool = absf(sm.brightness - 0.77) < 0.001 and absf(sm.camera_zoom - 3.3) < 0.001 \
		and sm.show_damage_numbers == false
	print("[savetest] settings brightness=%.2f zoom=%.2f dmg_nums=%s -> %s" % [
		sm.brightness, sm.camera_zoom, str(sm.show_damage_numbers), "PASS" if s_ok else "FAIL"])
	sm.clear_run()
	print("[savetest] DONE")
