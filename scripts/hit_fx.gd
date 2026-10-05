class_name HitFX
extends Node2D
## Tiny one-shot burst: sparks, blood, or a healing ring.

var colour: Color = Color(1, 1, 1)
var count: int = 8
var life: float = 0.32
var _max_life: float = 0.32
var _vels: Array[Vector2] = []
var _pos: Array[Vector2] = []
var radius: float = 3.0


func setup(at: Vector2, col: Color, n: int = 8, spread: float = 90.0, r: float = 3.0) -> void:
	position = at
	colour = col
	count = n
	radius = r
	for _i in count:
		var a := randf() * TAU
		_vels.append(Vector2.RIGHT.rotated(a) * randf_range(spread * 0.4, spread))
		_pos.append(Vector2.ZERO)
	z_index = 20


func _ready() -> void:
	_max_life = life


func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	for i in _pos.size():
		_pos[i] += _vels[i] * delta
		_vels[i] *= 0.90
	queue_redraw()


func _draw() -> void:
	var t := clampf(life / _max_life, 0.0, 1.0)
	for i in _pos.size():
		draw_circle(_pos[i], radius * t, Color(colour.r, colour.g, colour.b, t))
