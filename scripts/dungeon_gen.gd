class_name DungeonGen
extends RefCounted
## Procedural dungeon generator.
## Rooms + corridors carved into a grid, then decorated per-biome.

enum Cell { WALL, FLOOR, DOOR, STAIRS, PIT }

const TILE := 16
const FLOOR_VARIANTS := 4


class Room:
	var x: int
	var y: int
	var w: int
	var h: int
	func _init(_x: int, _y: int, _w: int, _h: int) -> void:
		x = _x; y = _y; w = _w; h = _h
	func center() -> Vector2i:
		return Vector2i(x + w / 2, y + h / 2)
	func intersects(o: Room, pad: int = 2) -> bool:
		return (x - pad < o.x + o.w + pad and x + w + pad > o.x - pad
			and y - pad < o.y + o.h + pad and y + h + pad > o.y - pad)


static func generate(width: int, height: int, depth: int, rng: RandomNumberGenerator) -> Dictionary:
	var grid: Array = []
	for y in height:
		var row: Array = []
		row.resize(width)
		row.fill(Cell.WALL)
		grid.append(row)

	var rooms: Array = []
	var attempts := 240
	var max_rooms := clampi(7 + depth, 8, 20)

	for _i in attempts:
		if rooms.size() >= max_rooms:
			break
		var rw := rng.randi_range(6, 12)
		var rh := rng.randi_range(5, 10)
		var rx := rng.randi_range(1, maxi(2, width - rw - 2))
		var ry := rng.randi_range(1, maxi(2, height - rh - 2))
		var cand := Room.new(rx, ry, rw, rh)
		var ok := true
		for other in rooms:
			if cand.intersects(other):
				ok = false
				break
		if not ok:
			continue
		_carve_room(grid, cand)
		if not rooms.is_empty():
			var prev: Room = rooms[rooms.size() - 1]
			_carve_corridor(grid, prev.center(), cand.center(), rng)
		rooms.append(cand)

	if rooms.size() < 2:
		# degenerate fallback: guarantee at least one room
		var r := Room.new(2, 2, mini(10, width - 4), mini(8, height - 4))
		_carve_room(grid, r)
		rooms = [r]

	# --- place stairs in the room farthest from the spawn room ---------------
	var spawn_room: Room = rooms[0]
	var best_dist := -1.0
	var exit_room: Room = rooms[rooms.size() - 1]
	for r in rooms:
		var d := Vector2(r.center() - spawn_room.center()).length()
		if d > best_dist:
			best_dist = d
			exit_room = r
	var stairs: Vector2i = exit_room.center()
	grid[stairs.y][stairs.x] = Cell.STAIRS

	return {
		"grid": grid,
		"rooms": rooms,
		"width": width,
		"height": height,
		"spawn": spawn_room.center(),
		"stairs": stairs,
		"depth": depth,
	}


static func _carve_room(grid: Array, r: Room) -> void:
	for y in range(r.y, r.y + r.h):
		for x in range(r.x, r.x + r.w):
			if y >= 0 and y < grid.size() and x >= 0 and x < grid[0].size():
				grid[y][x] = Cell.FLOOR


static func _carve_corridor(grid: Array, from: Vector2i, to: Vector2i, rng: RandomNumberGenerator) -> void:
	var x := from.x
	var y := from.y
	if rng.randf() < 0.5:
		while x != to.x:
			x += signi(to.x - x)
			_put(grid, x, y, Cell.FLOOR)
		while y != to.y:
			y += signi(to.y - y)
			_put(grid, x, y, Cell.FLOOR)
	else:
		while y != to.y:
			y += signi(to.y - y)
			_put(grid, x, y, Cell.FLOOR)
		while x != to.x:
			x += signi(to.x - x)
			_put(grid, x, y, Cell.FLOOR)


static func _put(grid: Array, x: int, y: int, v: int) -> void:
	if y >= 0 and y < grid.size() and x >= 0 and x < grid[0].size():
		if grid[y][x] == Cell.WALL:
			grid[y][x] = v


static func walkable(grid: Array, x: int, y: int) -> bool:
	if y < 0 or y >= grid.size() or x < 0 or x >= grid[0].size():
		return false
	var c: int = grid[y][x]
	return c == Cell.FLOOR or c == Cell.DOOR or c == Cell.STAIRS


static func is_solid(c: int) -> bool:
	return c == Cell.WALL


static func cell_from_pos(p: Vector2, tile: int = 16) -> Vector2i:
	return Vector2i(int(floor(p.x / tile)), int(floor(p.y / tile)))


## Find free floor cells, excluding a radius around `avoid`.
static func free_cells(grid: Array, avoid: Vector2i, avoid_radius: float, rng: RandomNumberGenerator) -> Array:
	var out: Array = []
	for y in grid.size():
		for x in grid[0].size():
			if not walkable(grid, x, y):
				continue
			if Vector2(x - avoid.x, y - avoid.y).length() < avoid_radius:
				continue
			out.append(Vector2i(x, y))
	out.shuffle()
	return out


## The room with the largest floor area — used to host a boss.
static func largest_room(rooms: Array) -> Room:
	var best: Room = null
	var best_area := -1
	for r in rooms:
		var a: int = r.w * r.h
		if a > best_area:
			best_area = a
			best = r
	return best


## Free cells that lie INSIDE a room, never in a corridor. Monsters spawn here
## so they can never appear in a wall or stranded in a 1-tile hallway.
static func room_cells(rooms: Array, avoid: Vector2i, avoid_radius: float,
		rng: RandomNumberGenerator, margin: int = 1) -> Array:
	var out: Array = []
	for r in rooms:
		for y in range(r.y + margin, r.y + r.h - margin):
			for x in range(r.x + margin, r.x + r.w - margin):
				if Vector2(x - avoid.x, y - avoid.y).length() < avoid_radius:
					continue
				out.append(Vector2i(x, y))
	out.shuffle()
	return out


## Cells belonging to one specific room (used to place a boss and its guards).
static func cells_in_room(r: Room, rng: RandomNumberGenerator, margin: int = 1) -> Array:
	var out: Array = []
	for y in range(r.y + margin, r.y + r.h - margin):
		for x in range(r.x + margin, r.x + r.w - margin):
			out.append(Vector2i(x, y))
	out.shuffle()
	return out
