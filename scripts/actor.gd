class_name Actor
extends Node2D
## Base for anything that walks the dungeon. Movement is resolved against the
## tile grid with axis separation — deterministic, cheap, and it slides along
## walls instead of sticking to them.

var grid: Array = []
var grid_w: int = 0
var grid_h: int = 0
var radius: float = 7.0
var tile: int = 16
var velocity: Vector2 = Vector2.ZERO
var facing: Vector2 = Vector2.DOWN
var is_dead: bool = false


func bind_grid(g: Array, w: int, h: int) -> void:
	grid = g
	grid_w = w
	grid_h = h


## World position -> grid cell
func cell_of(p: Vector2) -> Vector2i:
	return Vector2i(int(floor(p.x / tile)), int(floor(p.y / tile)))


func cell_walkable(cx: int, cy: int) -> bool:
	return DungeonGen.walkable(grid, cx, cy)


## True when the actor's AABB at `p` overlaps only walkable cells.
func can_stand_at(p: Vector2) -> bool:
	var r := radius
	var corners := [
		p + Vector2(-r, -r), p + Vector2(r, -r),
		p + Vector2(-r, r), p + Vector2(r, r),
		p + Vector2(0, -r), p + Vector2(0, r),
		p + Vector2(-r, 0), p + Vector2(r, 0),
	]
	for c in corners:
		var cell := cell_of(c)
		if not cell_walkable(cell.x, cell.y):
			return false
	return true


## Move by `delta_pos`, resolving each axis independently so we slide on walls.
func move_resolved(delta_pos: Vector2) -> void:
	if delta_pos == Vector2.ZERO:
		return
	var target := position
	var nx := target + Vector2(delta_pos.x, 0.0)
	if can_stand_at(nx):
		target = nx
	var ny := target + Vector2(0.0, delta_pos.y)
	if can_stand_at(ny):
		target = ny
	position = target


func dir_from_vec(v: Vector2) -> String:
	if v == Vector2.ZERO:
		return "down"
	if absf(v.x) > absf(v.y):
		return "right" if v.x > 0.0 else "left"
	return "down" if v.y > 0.0 else "up"
