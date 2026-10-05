class_name BloodySwordLogo
extends Control
## A bleeding sword logo drawn in code. Blood drips from the blade.
## Pixel art style, upside down (handle up, blade pointing down).

var _t: float = 0.0
var _blood_drips: Array = []

var _hover_t: float = 0.0
var _hovered := false
var _base_y: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(200, 200)
	_spawn_drips()
	set_process(true)
	mouse_entered.connect(func(): _hovered = true)
	mouse_exited.connect(func(): _hovered = false)


func _spawn_drips() -> void:
	_blood_drips.clear()
	var n := randi_range(4, 7)
	for _i in n:
		_blood_drips.append(_new_drip())


func _new_drip() -> Array:
	return [
		randf_range(0.2, 0.8),
		randf_range(2.0, 6.0),
		randf_range(10.0, 30.0),
		randf_range(5.0, 15.0),
		-1.0,
		randf_range(30.0, 80.0),
		randf_range(0.0, 3.0),
	]


func _process(delta: float) -> void:
	_t += delta
	_hover_t = lerp(_hover_t, 1.0 if _hovered else 0.0, 0.12)
	if _base_y == 0.0:
		_base_y = position.y
	position.y = _base_y - _hover_t * 12.0
	rotation = sin(_t * 0.8) * 0.02 + _hover_t * 0.05
	scale = Vector2.ONE * (1.0 + _hover_t * 0.08)
	for d in _blood_drips:
		if d[1] < d[2]:
			d[1] = minf(d[2], d[1] + d[3] * delta)
		d[6] -= delta
		if d[6] <= 0.0:
			if d[4] < 0.0:
				d[4] = d[1]
			d[4] += d[5] * delta
			d[5] += 200.0 * delta
			if d[4] > size.y + 40:
				var fresh := _new_drip()
				for i in fresh.size():
					d[i] = fresh[i]
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var cx := w * 0.5

	# Sword is UPSIDE DOWN: handle at top, blade pointing down
	# Handle (top)
	var handle_w := w * 0.06
	var handle_h := h * 0.18
	var handle_y := h * 0.08
	draw_rect(Rect2(cx - handle_w / 2, handle_y, handle_w, handle_h), Color(0.25, 0.08, 0.08))
	# Handle wrap lines
	for i in 3:
		var wy := handle_y + handle_h * (0.2 + float(i) * 0.25)
		draw_rect(Rect2(cx - handle_w / 2, wy, handle_w, 2), Color(0.4, 0.15, 0.1))

	# Pommel (top of handle)
	draw_circle(Vector2(cx, handle_y), w * 0.05, Color(0.4, 0.1, 0.1))
	draw_circle(Vector2(cx, handle_y), w * 0.03, Color(0.6, 0.15, 0.1))

	# Crossguard
	var guard_w := w * 0.38
	var guard_h := h * 0.045
	var guard_y := handle_y + handle_h
	draw_rect(Rect2(cx - guard_w / 2, guard_y, guard_w, guard_h), Color(0.4, 0.1, 0.1))
	# Guard ends
	draw_circle(Vector2(cx - guard_w / 2, guard_y + guard_h / 2), guard_h * 0.7, Color(0.5, 0.15, 0.1))
	draw_circle(Vector2(cx + guard_w / 2, guard_y + guard_h / 2), guard_h * 0.7, Color(0.5, 0.15, 0.1))

	# Blade (pointing down from crossguard)
	var blade_w := w * 0.09
	var blade_h := h * 0.52
	var blade_top := guard_y + guard_h
	var blade_bottom := blade_top + blade_h

	# Blade body - metallic grey
	draw_rect(Rect2(cx - blade_w / 2, blade_top, blade_w, blade_h), Color(0.7, 0.65, 0.6))
	# Blade edge highlight (left side)
	draw_rect(Rect2(cx - blade_w / 2, blade_top, blade_w * 0.25, blade_h), Color(0.85, 0.8, 0.75))
	# Blade center ridge
	draw_rect(Rect2(cx - 1, blade_top, 2, blade_h), Color(0.6, 0.55, 0.5))

	# Blade tip (triangle pointing down)
	var tip := PackedVector2Array([
		Vector2(cx - blade_w / 2, blade_bottom),
		Vector2(cx + blade_w / 2, blade_bottom),
		Vector2(cx, blade_bottom + h * 0.06),
	])
	draw_colored_polygon(tip, Color(0.7, 0.65, 0.6))

	# Blood on the blade - red streaks
	draw_rect(Rect2(cx - blade_w / 2, blade_top + blade_h * 0.1, blade_w, blade_h * 0.35), Color(0.6, 0.0, 0.0, 0.4))
	draw_rect(Rect2(cx - blade_w / 2, blade_top + blade_h * 0.5, blade_w * 0.5, blade_h * 0.3), Color(0.8, 0.0, 0.0, 0.3))
	# Blood near the tip
	draw_rect(Rect2(cx - blade_w / 2, blade_bottom - blade_h * 0.15, blade_w, blade_h * 0.15), Color(0.7, 0.0, 0.0, 0.5))

	# Blood drips from the blade tip
	for d in _blood_drips:
		var gx := cx + (float(d[0]) - 0.5) * w * 0.3
		var top := blade_bottom + h * 0.06
		var ln: float = float(d[1])
		draw_line(Vector2(gx, top), Vector2(gx, top + ln), Color("#4a0000"), 2.5)
		draw_circle(Vector2(gx, top + ln), 2.0, Color("#8b0000"))
		if d[4] > 0.0:
			var dy := top + float(d[4])
			draw_line(Vector2(gx, top + ln), Vector2(gx, dy), Color("#4a0000", 0.5), 1.5)
			draw_circle(Vector2(gx, dy), 2.5, Color("#8b0000"))
			draw_circle(Vector2(gx, dy), 4.0, Color("#8b0000", 0.25))
