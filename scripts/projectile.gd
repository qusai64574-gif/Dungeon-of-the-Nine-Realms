class_name Projectile
extends Node2D
## Anything that flies: player bolts, enemy fireballs.

var velocity: Vector2 = Vector2.ZERO
var damage: int = 5
var from_player: bool = true
var life: float = 2.4
var radius: float = 4.0
var colour: Color = Color(1, 1, 1)
var _trail: Array[Vector2] = []
var grid: Array = []
var grid_w := 0
var grid_h := 0

const SPEED_DEFAULT := 420.0


func setup(origin: Vector2, dir: Vector2, dmg: int, is_player: bool,
		speed: float = SPEED_DEFAULT, col: Color = Color(1, 1, 1)) -> void:
	position = origin
	velocity = dir.normalized() * speed
	damage = dmg
	from_player = is_player
	colour = col
	z_index = 8


func _ready() -> void:
	# callers usually assign `grid` before adding us to the tree; only fall
	# back to the parent when they haven't.
	if grid.size() == 0:
		var par := get_parent()
		if par and par.get("grid") != null:
			grid = par.get("grid")
	set_process(true)


func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	var step := velocity * delta
	position += step
	_trail.append(position)
	if _trail.size() > 6:
		_trail.pop_front()
	_check_hits()
	queue_redraw()


func _check_hits() -> void:
	# walls
	var cell := Vector2i(int(floor(position.x / 16.0)), int(floor(position.y / 16.0)))
	if grid.size() > 0 and not DungeonGen.walkable(grid, cell.x, cell.y):
		_burst()
		return
	# actors
	if from_player:
		for e in get_tree().get_nodes_in_group("enemies"):
			if e is Enemy and not e.is_dead and position.distance_to(e.global_position) < radius + e.radius:
				e.hurt(damage, global_position, 6.0)
				_burst()
				return
	else:
		for p in get_tree().get_nodes_in_group("player"):
			if p is Player and not p.is_dead and position.distance_to(p.global_position) < radius + p.radius:
				p.hurt(damage, global_position)
				_burst()
				return


func _burst() -> void:
	var parent := get_parent()
	if parent:
		var fx := preload("res://scripts/hit_fx.gd").new()
		fx.setup(position, colour, 8)
		parent.add_child(fx)
	queue_free()


func _draw() -> void:
	# glow
	draw_circle(Vector2.ZERO, radius * 2.2, Color(colour.r, colour.g, colour.b, 0.18))
	draw_circle(Vector2.ZERO, radius, colour)
	draw_circle(Vector2.ZERO, radius * 0.45, Color(1, 1, 1, 0.9))
	# trail
	for i in _trail.size():
		var t := float(i) / float(maxi(1, _trail.size()))
		var local := _trail[i] - position
		draw_circle(local, radius * 0.6 * t, Color(colour.r, colour.g, colour.b, 0.25 * t))
