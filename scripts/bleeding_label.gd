class_name BleedingLabel
extends Label
## Any label that bleeds. Blood drips from the baseline of each line of text.
## Works like BloodText but extends Label so it can be used anywhere a Label
## is expected (headings, body text, buttons, HUD, etc).

var _drips: Array = []          # [line_idx, x_off, len, target_len, speed, drop_y, drop_vy, delay]
var _t: float = 0.0
var _hovered := false
var _blood_colour: Color = Color("#8b0000")
var _streak_colour: Color = Color("#4a0000")
var _drip_density: float = 1.0   # multiplier: higher = more drips per char


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spawn_drips()


func _spawn_drips() -> void:
	_drips.clear()
	var lines := _get_line_count()
	for li in lines:
		var n := int((randi_range(2, 5)) * _drip_density)
		for _i in n:
			_drips.append(_new_drip(li))


func _new_drip(line_idx: int) -> Array:
	return [
		line_idx,
		randf_range(0.05, 0.95),     # x offset (0..1 across line width)
		randf_range(1.0, 4.0),       # current streak length
		randf_range(6.0, 22.0),      # target streak length
		randf_range(4.0, 14.0),      # growth speed px/s
		-1.0,                         # droplet y (-1 = attached)
		randf_range(20.0, 70.0),     # droplet fall speed
		randf_range(0.0, 3.0),       # delay before droplet detaches
	]


func _get_line_count() -> int:
	if text.is_empty():
		return 1
	return text.split("\n").size()


func _process(delta: float) -> void:
	_t += delta
	var speed_mult := 2.0 if _hovered else 1.0
	for d in _drips:
		if d[2] < d[3]:
			d[2] = minf(d[3], d[2] + d[4] * speed_mult * delta)
		d[7] -= delta * speed_mult
		if d[7] <= 0.0:
			if d[5] < 0.0:
				d[5] = d[2]
			d[5] += d[6] * delta
			d[6] += 220.0 * delta
			if d[5] > size.y + 60:
				var fresh := _new_drip(d[0])
				for i in fresh.size():
					d[i] = fresh[i]
	queue_redraw()


func _draw() -> void:
	if text.is_empty():
		return
	var font: Font = get_theme_font("font")
	var font_size: int = get_theme_font_size("font_size")
	var lines := text.split("\n")
	var line_height := font.get_height(font_size)
	var total_h := line_height * lines.size()
	var start_y := (size.y - total_h) * 0.5 + font_size * 0.8

	for li in lines.size():
		var line_text: String = lines[li]
		if line_text.is_empty():
			continue
		var line_w := font.get_string_size(line_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var start_x := (size.x - line_w) * 0.5
		var baseline := start_y + li * line_height

		# draw blood streaks under each character
		for d in _drips:
			if d[0] != li:
				continue
			var gx := start_x + line_w * float(d[1])
			var top := baseline + 1.0
			var ln: float = float(d[2])
			# streak
			draw_line(Vector2(gx, top), Vector2(gx, top + ln), _streak_colour, 2.0)
			draw_rect(Rect2(Vector2(gx - 1.8, top + ln - 1.8), Vector2(3.6, 3.6)), _blood_colour)
			# detached droplet
			if d[5] > 0.0:
				var dy := top + float(d[5])
				draw_line(Vector2(gx, top + ln), Vector2(gx, dy),
					Color(_streak_colour.r, _streak_colour.g, _streak_colour.b, 0.5), 1.2)
				draw_rect(Rect2(Vector2(gx - 2.2, dy - 2.2), Vector2(4.4, 4.4)), _blood_colour)
				draw_rect(Rect2(Vector2(gx - 3.4, dy - 3.4), Vector2(6.8, 6.8)), Color(_blood_colour.r, _blood_colour.g, _blood_colour.b, 0.25))


func set_blood_colour(c: Color) -> void:
	_blood_colour = c


func set_streak_colour(c: Color) -> void:
	_streak_colour = c


func set_drip_density(d: float) -> void:
	_drip_density = d
	_spawn_drips()
