class_name BloodyCrossLogo
extends Control
## The game's cross logo with blood dripping from it.
## Matches the pizza game's "PIZZA HOUR" logo position and style.

var _t: float = 0.0
var _blood_drips: Array = []  # [x_offset, len, target_len, speed, drop_y, drop_vy, delay]


func _ready() -> void:
	custom_minimum_size = Vector2(200, 200)
	_build()
	set_process(true)


func _build() -> void:
	# Draw a cross directly in code - more reliable than loading a texture
	# The cross is drawn in _draw() with blood drips
	
	# Spawn blood drips
	_spawn_drips()


func _spawn_drips() -> void:
	_blood_drips.clear()
	var n := randi_range(5, 8)
	for _i in n:
		_blood_drips.append(_new_drip())


func _new_drip() -> Array:
	return [
		randf_range(0.1, 0.9),       # x offset (0..1 across cross width)
		randf_range(2.0, 6.0),       # current streak length
		randf_range(10.0, 30.0),     # target streak length
		randf_range(5.0, 15.0),      # growth speed px/s
		-1.0,                         # droplet y (-1 = attached)
		randf_range(30.0, 80.0),     # droplet fall speed
		randf_range(0.0, 3.0),       # delay before droplet detaches
	]


func _process(delta: float) -> void:
	_t += delta
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
	var cross_size := minf(size.x, size.y) * 0.7
	var cx := size.x * 0.5
	var cy := size.y * 0.4
	
	# Draw the cross - vertical bar
	var bar_width := cross_size * 0.15
	var bar_height := cross_size * 0.8
	var arm_width := cross_size * 0.5
	var arm_height := cross_size * 0.12
	
	# Vertical bar
	draw_rect(Rect2(cx - bar_width/2, cy - bar_height/2, bar_width, bar_height), Color(0.9, 0.85, 0.8))
	# Horizontal bar
	draw_rect(Rect2(cx - arm_width/2, cy - arm_height/2, arm_width, arm_height), Color(0.9, 0.85, 0.8))
	
	# Blood on the cross - more prominent
	draw_rect(Rect2(cx - bar_width/2, cy - bar_height/2, bar_width, bar_height * 0.5), Color(0.8, 0.0, 0.0, 0.7))
	draw_rect(Rect2(cx - arm_width/2, cy - arm_height/2, arm_width, arm_height * 0.6), Color(0.6, 0.0, 0.0, 0.5))
	
	# Draw blood streaks under the cross
	for d in _blood_drips:
		var gx := cx + (float(d[0]) - 0.5) * cross_size * 0.6
		var top := cy + bar_height * 0.4
		var ln: float = float(d[1])
		# streak
		draw_line(Vector2(gx, top), Vector2(gx, top + ln), Color("#4a0000"), 2.5)
		draw_circle(Vector2(gx, top + ln), 2.0, Color("#8b0000"))
		# detached droplet
		if d[4] > 0.0:
			var dy := top + float(d[4])
			draw_line(Vector2(gx, top + ln), Vector2(gx, dy),
				Color("#4a0000", 0.5), 1.5)
			draw_circle(Vector2(gx, dy), 2.5, Color("#8b0000"))
			draw_circle(Vector2(gx, dy), 4.0, Color("#8b0000", 0.25))
