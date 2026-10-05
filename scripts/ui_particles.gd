class_name UIParticles
extends Control
## Lightweight spark burst for UI. Draws in its own space and self-disables
## when idle, so an unused instance costs nothing.

class P:
	var pos: Vector2
	var vel: Vector2
	var life: float
	var max_life: float
	var size: float
	var col: Color

var _p: Array[P] = []
var _active := false
var gravity: float = 190.0
var drag: float = 0.90


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func burst(count: int, col: Color, spread: float = 130.0, origin: Vector2 = Vector2.ZERO,
		radius: float = 0.0) -> void:
	for _i in count:
		var a := randf() * TAU
		var sp := randf_range(spread * 0.35, spread)
		var p := P.new()
		if radius > 0.0:
			p.pos = origin + Vector2.RIGHT.rotated(a) * radius
		else:
			p.pos = origin
		p.vel = Vector2.RIGHT.rotated(a) * sp
		p.life = randf_range(0.30, 0.65)
		p.max_life = p.life
		p.size = randf_range(1.5, 3.6)
		p.col = col
		_p.append(p)
	_active = true
	set_process(true)
	queue_redraw()


func ring(col: Color, origin: Vector2, radius: float = 26.0, count: int = 18) -> void:
	for i in count:
		var a := TAU * float(i) / float(count)
		var p := P.new()
		p.pos = origin + Vector2.RIGHT.rotated(a) * radius
		p.vel = Vector2.RIGHT.rotated(a) * randf_range(40.0, 80.0)
		p.life = randf_range(0.25, 0.45)
		p.max_life = p.life
		p.size = randf_range(1.5, 3.0)
		p.col = col
		_p.append(p)
	_active = true
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	if not _active:
		return
	for i in range(_p.size() - 1, -1, -1):
		var p := _p[i]
		p.life -= delta
		if p.life <= 0.0:
			_p.remove_at(i)
			continue
		p.vel.y += gravity * delta
		p.vel *= drag
		p.pos += p.vel * delta
	if _p.is_empty():
		_active = false
		set_process(false)
	queue_redraw()


func _draw() -> void:
	for p in _p:
		var t := clampf(p.life / p.max_life, 0.0, 1.0)
		var c := Color(p.col.r, p.col.g, p.col.b, t)
		var s := p.size * (0.4 + 0.6 * t)
		draw_rect(Rect2(p.pos - Vector2(s, s) * 0.5, Vector2(s, s)), c, true)
		# a faint glow so sparks read against dark panels
		draw_circle(p.pos, s * 1.5, Color(p.col.r, p.col.g, p.col.b, t * 0.18))
