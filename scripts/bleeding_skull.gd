class_name BleedingSkull
extends Control
## A bleeding pixelated skull drawn in code. Blood drips from the jaw.

var _t: float = 0.0
var _drips: Array = []
var _black := false


func _ready() -> void:
	custom_minimum_size = Vector2(40, 40)
	set_process(true)
	_spawn_drips()


func _spawn_drips() -> void:
	_drips.clear()
	for _i in 3:
		_drips.append(_new_drip())


func _new_drip() -> Array:
	return [
		randf_range(0.2, 0.8),
		randf_range(1.0, 3.0),
		randf_range(6.0, 18.0),
		randf_range(4.0, 10.0),
		-1.0,
		randf_range(15.0, 40.0),
		randf_range(0.0, 2.0),
	]


func _process(delta: float) -> void:
	_t += delta
	for d in _drips:
		if d[1] < d[2]:
			d[1] = minf(d[2], d[1] + d[3] * delta)
		d[6] -= delta
		if d[6] <= 0.0:
			if d[4] < 0.0:
				d[4] = d[1]
			d[4] += d[5] * delta
			d[5] += 150.0 * delta
			if d[4] > size.y + 20:
				var fresh := _new_drip()
				for i in fresh.size():
					d[i] = fresh[i]
	queue_redraw()


func set_black(v: bool) -> void:
	_black = v

func _draw() -> void:
	var w := size.x
	var h := size.y
	var cx := w * 0.5

	# Skull shape — pixelated
	var skull_col := Color(0.08, 0.08, 0.08) if _black else Color(0.85, 0.82, 0.78)
	var eye_col := Color(0.8, 0.0, 0.0) if _black else Color(0.1, 0.0, 0.0)

	# Cranium
	draw_rect(Rect2(cx - w * 0.25, h * 0.1, w * 0.5, h * 0.35), skull_col)
	# Cheekbones
	draw_rect(Rect2(cx - w * 0.3, h * 0.4, w * 0.6, h * 0.15), skull_col)
	# Jaw
	draw_rect(Rect2(cx - w * 0.2, h * 0.55, w * 0.4, h * 0.2), skull_col)
	# Teeth
	for i in 4:
		var tx := cx - w * 0.15 + i * w * 0.1
		draw_rect(Rect2(tx, h * 0.7, w * 0.06, h * 0.1), skull_col)

	# Eye sockets
	draw_circle(Vector2(cx - w * 0.12, h * 0.28), w * 0.08, eye_col)
	draw_circle(Vector2(cx + w * 0.12, h * 0.28), w * 0.08, eye_col)

	# Nose
	draw_rect(Rect2(cx - w * 0.03, h * 0.38, w * 0.06, h * 0.08), eye_col)

	# Blood drips from jaw
	for d in _drips:
		var gx := cx + (float(d[0]) - 0.5) * w * 0.3
		var top := h * 0.75
		var ln: float = float(d[1])
		draw_line(Vector2(gx, top), Vector2(gx, top + ln), Color("#4a0000"), 1.5)
		draw_circle(Vector2(gx, top + ln), 1.5, Color("#8b0000"))
		if d[4] > 0.0:
			var dy := top + float(d[4])
			draw_line(Vector2(gx, top + ln), Vector2(gx, dy), Color("#4a0000", 0.5), 1.0)
			draw_circle(Vector2(gx, dy), 2.0, Color("#8b0000"))
