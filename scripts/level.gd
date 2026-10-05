class_name Level
extends Node2D
## The dungeon itself: draws the tile grid, tracks fog of war, spawns the
## player / monsters / loot, and handles descent.

const GW := 72          # grid width in tiles
const GH := 48          # grid height in tiles
const TILE := 16
const VIEW_RADIUS := 9.0
const LIGHT_RADIUS := 5.0

var grid: Array = []
var rooms: Array = []
var depth: int = 1
var biome: String = "default"
var spawn_cell: Vector2i = Vector2i.ZERO
var stairs_cell: Vector2i = Vector2i.ZERO

var explored: Array = []        # Array[Array[bool]]
var vis_map: Array = []         # Array[Array[bool]] — "visible" collides with CanvasItem
var _vis_timer: float = 0.0

var player: Player = null
var entities: Node2D
var loot: Node2D
var projectiles: Node2D
var fx: Node2D

var _tex_cache: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _player_dead := false
var _stairs_reached := false


func _ready() -> void:
	z_index = 0
	entities = Node2D.new(); entities.name = "Entities"; add_child(entities)
	loot = Node2D.new(); loot.name = "Loot"; add_child(loot)
	projectiles = Node2D.new(); projectiles.name = "Projectiles"; add_child(projectiles)
	fx = Node2D.new(); fx.name = "FX"; add_child(fx)
	_rng.randomize()
	EventBus.cheat_kill_all.connect(_cheat_kill_all)
	EventBus.cheat_reveal_map.connect(_cheat_reveal)
	EventBus.cheat_teleport_stairs.connect(_cheat_teleport_stairs)
	EventBus.cheat_spawn_enemy.connect(_cheat_spawn_enemy)
	EventBus.cheat_spawn_item.connect(_cheat_spawn_item)
	EventBus.cheat_spawn_chest.connect(_cheat_spawn_chest)
	EventBus.cheat_nuke.connect(_cheat_nuke)
	EventBus.cheat_set_biome.connect(_cheat_set_biome)
	EventBus.request_regenerate.connect(func(): build(depth, true))
	EventBus.request_next_floor.connect(func(): descend())
	build(depth, false)


# ---------------------------------------------------------------------------
# Building
# ---------------------------------------------------------------------------
func build(at_depth: int, regenerate: bool = false) -> void:
	depth = at_depth
	_player_dead = false
	_stairs_reached = false
	_rng.seed = hash("depth_%d_%d" % [depth, randi() if regenerate else depth * 7919])

	biome = _pick_biome()
	_clear_world()

	var result := DungeonGen.generate(GW, GH, depth, _rng)
	grid = result["grid"]
	rooms = result["rooms"]
	spawn_cell = result["spawn"]
	stairs_cell = result["stairs"]

	explored = []
	vis_map = []
	for y in GH:
		var er: Array = []; er.resize(GW); er.fill(false)
		var vr: Array = []; vr.resize(GW); vr.fill(false)
		explored.append(er)
		vis_map.append(vr)

	_spawn_player()
	_spawn_loot()
	_spawn_monsters()
	_update_visibility(true)
	queue_redraw()

	EventBus.dungeon_generated.emit(grid, rooms, depth)
	EventBus.floor_changed.emit(depth)
	EventBus.toast_msg("%s  —  Depth %d" % [Assets.BIOME_NAMES.get(biome, biome), depth],
		Assets.BIOME_ACCENT.get(biome, Color.WHITE))


func _pick_biome() -> String:
	if GameState.biome != "auto" and GameState.biome != "":
		return GameState.biome
	# deterministic-ish rotation through the seven themes, no immediate repeats
	var order := Assets.BIOMES
	return order[(depth - 1) % order.size()]


func _clear_world() -> void:
	for n in [entities, loot, projectiles, fx]:
		for c in n.get_children():
			c.queue_free()
	player = null


func _spawn_player() -> void:
	player = Player.new()
	player.name = "Player"
	player.add_to_group("player")
	var spr := AnimSprite.new()
	spr.name = "Sprite"
	player.add_child(spr)
	var sh := Sprite2D.new()
	sh.name = "Shadow"
	sh.texture = _shadow_tex()
	sh.scale = Vector2(0.9, 0.42)
	sh.modulate = Color(0, 0, 0, 0.35)
	player.add_child(sh)
	player.position = _cell_center(spawn_cell)
	player.bind_grid(grid, GW, GH)
	player.attacked.connect(_on_player_attacked)
	entities.add_child(player)


func _shadow_tex() -> Texture2D:
	if not _tex_cache.has("__shadow__"):
		var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		for y in 16:
			for x in 16:
				var d := Vector2(x - 7.5, y - 7.5).length() / 7.5
				img.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d * d, 0.0, 1.0)))
		_tex_cache["__shadow__"] = ImageTexture.create_from_image(img)
	return _tex_cache["__shadow__"]


func _spawn_monsters() -> void:
	var count := clampi(6 + depth * 2, 6, 26)
	# Spawn INSIDE rooms only — never corridors, never in a wall, never outside.
	var cells := DungeonGen.room_cells(rooms, spawn_cell, 9.0, _rng)
	var spawned := 0
	for c in cells:
		if spawned >= count:
			break
		var id := EnemyDB.for_depth(depth, _rng)
		_spawn_enemy_at(id, _cell_center(c))
		spawned += 1

	# Boss on the milestone depths — confined to the largest room, with a
	# couple of guards, so it fights you in an arena rather than a corridor.
	var boss := EnemyDB.boss_for_depth(depth)
	if not boss.is_empty():
		var boss_id := String(boss["id"])
		var arena := DungeonGen.largest_room(rooms)
		if arena != null:
			var centre := _cell_center(arena.center())
			var e := _spawn_enemy_at(boss_id, centre, float(boss["hp_mult"]), float(boss["dmg_mult"]))
			if e:
				e.make_boss(String(boss["title"]), float(boss["scale"]))
				EventBus.boss_spawned.emit(e, String(boss["title"]), e.max_hp, e.max_hp)
				EventBus.toast_msg("⚠  " + String(boss["title"]), Color(1.0, 0.35, 0.35))
			# guards inside the same arena
			var seats := DungeonGen.cells_in_room(arena, _rng, 2)
			var placed := 0
			for c in seats:
				if placed >= 3:
					break
				if _cell_center(c).distance_to(centre) < 40.0:
					continue
				_spawn_enemy_at(EnemyDB.for_depth(depth, _rng), _cell_center(c))
				placed += 1


func _spawn_enemy_at(id: String, pos: Vector2, hp_mult: float = 1.0, dmg_mult: float = 1.0) -> Enemy:
	var e := Enemy.new()
	e.name = "Enemy_" + id
	e.add_to_group("enemies")
	var spr := AnimSprite.new(); spr.name = "Sprite"; e.add_child(spr)
	var sh := Sprite2D.new(); sh.name = "Shadow"
	sh.texture = _shadow_tex(); sh.scale = Vector2(0.9, 0.42)
	sh.modulate = Color(0, 0, 0, 0.3); e.add_child(sh)
	# add to the tree first so the @onready children resolve, then configure
	entities.add_child(e)
	e.position = pos
	e.setup(id, depth, hp_mult, dmg_mult)
	e.bind_grid(grid, GW, GH)
	return e


func _spawn_loot() -> void:
	var cells := DungeonGen.free_cells(grid, spawn_cell, 5.0, _rng)
	var i := 0

	# scattered coins and potions
	var gold_piles := clampi(4 + depth, 4, 16)
	for _n in gold_piles:
		if i >= cells.size(): break
		_drop_loot("gold", _rng.randi_range(3, 9 + depth * 2), cells[i]); i += 1
	for _n in clampi(1 + depth / 3, 1, 4):
		if i >= cells.size(): break
		_drop_loot("health_potion", 25, cells[i]); i += 1
	for _n in 2:
		if i >= cells.size(): break
		_drop_loot("gem", 1, cells[i]); i += 1

	# gear
	var gear := ["sword", "armor", "helmet", "ring", "shield", "necklace", "scroll", "spell_book"]
	for _n in clampi(1 + depth / 2, 1, 5):
		if i >= cells.size(): break
		_drop_loot(gear.pick_random(), 2, cells[i]); i += 1

	# chests
	for _n in clampi(1 + depth / 4, 1, 4):
		if i >= cells.size(): break
		_drop_loot("chest", 1, cells[i]); i += 1

	# scenery props (non-interactive, just dressing)
	for _n in clampi(6 + depth, 6, 18):
		if i >= cells.size(): break
		var prop: String = ["torch", "vase", "cauldron", "stone", "mushroom", "lever"].pick_random()
		var p := Sprite2D.new()
		p.texture = _tex(Assets.item(prop))
		p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		p.position = _cell_center(cells[i]) + Vector2(_rng.randf_range(-4, 4), _rng.randf_range(-4, 4))
		var sz := p.texture.get_size()
		var s: float = 17.0 / maxf(sz.x, sz.y)
		p.scale = Vector2(s, s)
		p.z_index = 2
		loot.add_child(p)
		i += 1


func _drop_loot(kind: String, amount: int, cell: Vector2i) -> void:
	var pk := Pickup.new()
	pk.add_to_group("pickups")
	pk.setup(kind, amount)
	pk.position = _cell_center(cell)
	pk.grid = grid
	loot.add_child(pk)


func _cell_center(c: Vector2i) -> Vector2:
	return Vector2(c.x * TILE + TILE * 0.5, c.y * TILE + TILE * 0.5)


func cell_of(p: Vector2) -> Vector2i:
	return Vector2i(int(floor(p.x / TILE)), int(floor(p.y / TILE)))


# ---------------------------------------------------------------------------
# Combat wiring
# ---------------------------------------------------------------------------
func _on_player_attacked(kind: String, origin: Vector2, dir: Vector2, damage: int) -> void:
	if kind == "melee":
		var hit_any := false
		for e in entities.get_children():
			if not (e is Enemy) or e.is_dead:
				continue
			var to: Vector2 = e.global_position - origin
			if to.length() > Player.MELEE_RANGE + e.radius:
				continue
			if absf(dir.angle_to(to.normalized())) > Player.MELEE_ARC:
				continue
			var dmg := damage
			var crit := randf() < GameState.stat_crit
			if crit:
				dmg = int(round(dmg * GameState.crit_mult))
			e.hurt(dmg, origin, 10.0)
			EventBus.damage_number.emit(e.global_position + Vector2(0, -20), dmg, 1 if crit else 0)
			hit_any = true
		if not hit_any:
			_spawn_slash(origin, dir)
		else:
			_spawn_slash(origin, dir)
	else:
		var n := maxi(1, GameState.projectile_count)
		for i in n:
			var spread := 0.0 if n == 1 else (float(i) - float(n - 1) * 0.5) * 0.20
			var proj := Projectile.new()
			proj.setup(origin, dir.rotated(spread), damage, true,
				GameState.projectile_speed, Color(1.0, 0.85, 0.4))
			proj.grid = grid
			projectiles.add_child(proj)


func _spawn_slash(origin: Vector2, dir: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = _tex(Assets.skill_icon("melee"))
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.position = origin + dir * 16.0
	s.rotation = dir.angle()
	s.z_index = 15
	var sz := s.texture.get_size()
	s.scale = Vector2(30.0 / maxf(sz.x, sz.y), 30.0 / maxf(sz.x, sz.y))
	fx.add_child(s)
	var tw := create_tween()
	tw.tween_property(s, "modulate:a", 0.0, 0.16)
	tw.tween_callback(s.queue_free)


# ---------------------------------------------------------------------------
# Fog of war
# ---------------------------------------------------------------------------
func _update_visibility(_force: bool = false) -> void:
	if player == null:
		return
	var pc := player.cell_of(player.global_position)
	for y in GH:
		for x in GW:
			vis_map[y][x] = false
	var r := int(ceil(VIEW_RADIUS))
	for y in range(pc.y - r, pc.y + r + 1):
		for x in range(pc.x - r, pc.x + r + 1):
			if y < 0 or y >= GH or x < 0 or x >= GW:
				continue
			var d := Vector2(x - pc.x, y - pc.y).length()
			if d > VIEW_RADIUS:
				continue
			if _has_los(pc, Vector2i(x, y)):
				vis_map[y][x] = true
				explored[y][x] = true

	# Standing in a room reveals that room on the map (standard roguelike
	# courtesy — it makes the minimap useful without giving away the layout).
	for rm in rooms:
		if pc.x >= rm.x and pc.x < rm.x + rm.w and pc.y >= rm.y and pc.y < rm.y + rm.h:
			for y in range(rm.y, rm.y + rm.h):
				for x in range(rm.x, rm.x + rm.w):
					if y >= 0 and y < GH and x >= 0 and x < GW:
						explored[y][x] = true
			break

	if GameState.map_revealed:
		for y in GH:
			for x in GW:
				explored[y][x] = true

	# Hide entities standing outside the player's sight, so monsters and loot
	# can't be seen through walls (fog alone only culls the tile layer).
	for e in entities.get_children():
		if e.has_method("apply_visibility"):
			e.apply_visibility()
	for pk in loot.get_children():
		if pk is Pickup:
			var c: Vector2i = cell_of(pk.global_position)
			if c.y >= 0 and c.y < GH and c.x >= 0 and c.x < GW:
				pk.visible = vis_map[c.y][c.x]

	queue_redraw()


func _has_los(from: Vector2i, to: Vector2i) -> bool:
	var x0 := from.x; var y0 := from.y
	var x1 := to.x; var y1 := to.y
	var dx := absi(x1 - x0); var dy := absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx - dy
	while true:
		if x0 == x1 and y0 == y1:
			return true
		# walls block sight, but you can always see the wall itself
		if not (x0 == from.x and y0 == from.y):
			if not DungeonGen.walkable(grid, x0, y0):
				return (x0 == x1 and y0 == y1)
		var e2 := 2 * err
		if e2 > -dy:
			err -= dy; x0 += sx
		if e2 < dx:
			err += dx; y0 += sy
	return false


# ---------------------------------------------------------------------------
# Per-frame
# ---------------------------------------------------------------------------
func _process(delta: float) -> void:
	GameState.run_time += delta
	_vis_timer += delta
	if _vis_timer > 0.08:
		_vis_timer = 0.0
		_update_visibility()
	if GameState.auto_heal and player and not player.is_dead:
		GameState.hp = GameState.max_hp
		EventBus.hp_changed.emit(GameState.hp, GameState.max_hp)

	if _player_dead or player == null:
		return

	# stairs
	if not _stairs_reached:
		var pc := player.cell_of(player.global_position)
		if pc == stairs_cell:
			_stairs_reached = true
			_on_reach_stairs()

	# falling out of the world shouldn't happen, but clamp anyway
	if player.global_position.x < 0 or player.global_position.y < 0:
		player.position = _cell_center(spawn_cell)


func _on_reach_stairs() -> void:
	EventBus.toast_msg("Descending…", Color(0.8, 0.9, 1.0))
	var tw := create_tween()
	tw.tween_interval(0.35)
	tw.tween_callback(func(): descend())


func descend() -> void:
	GameState.descend()
	build(GameState.depth, false)


func mark_player_dead() -> void:
	_player_dead = true
	if player:
		player.play_death()


# ---------------------------------------------------------------------------
# Admin cheats
# ---------------------------------------------------------------------------
func _cheat_kill_all() -> void:
	for e in entities.get_children():
		if e is Enemy and not e.is_dead:
			e.hurt(999999, Vector2.ZERO, 0.0)
	EventBus.toast_msg("KILL ALL", Color(1.0, 0.4, 0.4))


func _cheat_nuke() -> void:
	for e in entities.get_children():
		if e is Enemy and not e.is_dead:
			var fx2 := HitFX.new()
			fx2.setup(e.global_position, Color(1.0, 0.5, 0.2), 14, 150.0, 4.0)
			fx.add_child(fx2)
			e.hurt(999999, Vector2.ZERO, 0.0)
	EventBus.toast_msg("☢  NUKE", Color(1.0, 0.3, 0.2))


func _cheat_reveal() -> void:
	GameState.map_revealed = true
	for y in GH:
		for x in GW:
			explored[y][x] = true
	queue_redraw()
	EventBus.toast_msg("MAP REVEALED", Color(0.6, 1.0, 0.9))


func _cheat_teleport_stairs() -> void:
	if player:
		player.position = _cell_center(stairs_cell)
		_update_visibility(true)
		EventBus.toast_msg("TELEPORTED TO EXIT", Color(0.6, 1.0, 0.9))


func _cheat_spawn_enemy(id: String, count: int) -> void:
	if player == null:
		return
	for _i in maxi(1, count):
		var ang := randf() * TAU
		var pos := player.global_position + Vector2.RIGHT.rotated(ang) * randf_range(40, 90)
		var e := _spawn_enemy_at(id, pos)
		if e:
			e.global_position = pos
	EventBus.toast_msg("SPAWNED %d x %s" % [count, id], Color(1.0, 0.7, 0.9))


func _cheat_spawn_item(id: String, count: int) -> void:
	if player == null:
		return
	for _i in maxi(1, count):
		_drop_loot(id, 1, player.cell_of(player.global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))))
	EventBus.toast_msg("SPAWNED %d x %s" % [count, id], Color(0.9, 1.0, 0.7))


func _cheat_spawn_chest() -> void:
	if player == null:
		return
	for _i in 3:
		_drop_loot("chest", 1, player.cell_of(player.global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))))
	EventBus.toast_msg("CHESTS SPAWNED", Color(1.0, 0.85, 0.4))


func _cheat_set_biome(b: String) -> void:
	GameState.biome = b
	build(depth, true)
	EventBus.toast_msg("BIOME -> " + b, Color(0.8, 1.0, 0.9))


# ---------------------------------------------------------------------------
# Drawing
# ---------------------------------------------------------------------------
func _tex(path: String) -> Texture2D:
	if not _tex_cache.has(path):
		var t := load(path)
		if t == null:
			t = load(Assets.floor_tile("default", 0))
		_tex_cache[path] = t
	return _tex_cache[path]


func _draw() -> void:
	var floor_tex := _tex(Assets.floor_tile(biome, 0))
	var floor_alt := _tex(Assets.floor_tile(biome, 1))
	var wall_tex := _tex(Assets.wall_tile(biome))
	var door_tex := _tex(Assets.door_tile(biome))
	var stairs_tex := _tex(Assets.ladder_tile(biome))
	var pit_tex := _tex(Assets.pit_tile(biome))

	var br: float = 1.0
	var sm := get_node_or_null("/root/SaveManager")
	if sm:
		br = clampf(sm.brightness, 0.4, 1.6)

	for y in GH:
		for x in GW:
			var vis: bool = vis_map[y][x]
			var exp: bool = explored[y][x]
			if not exp:
				continue
			var cell: int = grid[y][x]
			var rect := Rect2(x * TILE, y * TILE, TILE, TILE)
			var tex := floor_tex
			match cell:
				DungeonGen.Cell.WALL: tex = wall_tex
				DungeonGen.Cell.DOOR: tex = door_tex
				DungeonGen.Cell.STAIRS: tex = stairs_tex
				DungeonGen.Cell.PIT: tex = pit_tex
				_: tex = floor_alt if ((x * 7 + y * 13) % 11 == 0) else floor_tex
			var m := Color(1, 1, 1, 1)
			if not vis:
				# remembered but unseen — cool and dim
				m = Color(0.22, 0.24, 0.34, 1.0)
			else:
				# light falloff from the player, tuned darker so the dungeon
				# reads as a dungeon rather than a lit room
				if player:
					var d := Vector2(x - player.cell_of(player.global_position).x,
						y - player.cell_of(player.global_position).y).length()
					var f := clampf(1.0 - (d / maxf(1.0, VIEW_RADIUS)) * 0.35, 0.55, 1.0)
					m = Color(f, f, f * 1.04, 1.0)
			draw_texture_rect(tex, rect, false, Color(m.r * br, m.g * br, m.b * br, m.a))
