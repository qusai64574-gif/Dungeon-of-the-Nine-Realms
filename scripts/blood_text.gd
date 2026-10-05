class_name BloodText
extends Control
## Text that bleeds.
##
## Each glyph is drawn individually in blood red, then a streak runs down from
## its baseline and droplets detach and fall. The streaks breathe and the
## droplets respawn, so the line is never static.

var message: String = "every action has consequences"
var font: Font
var font_size: int = 22
var colour: Color = Color("#b3121a")
var streak_colour: Color = Color("#7d0a10")
var letter_spacing: float = 2.0

var _glyph_x: Array[float] = []
var _glyph_w: Array[float] = []
var _drips: Array = []          # [gi, x_off, len, target_len, speed, drop_y, drop_vy, active]
var _t: float = 0.0
var _built := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if font == null:
		font = load("res://assets/fonts/Inter.ttf")
	_measure()
	_spawn_all()


func _measure() -> void:
	_glyph_x.clear()
	_glyph_w.clear()
	if font == null:
		return
	var x := 0.0
	for i in message.length():
		var ch := message[i]
		var w := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		_glyph_x.append(x)
		_glyph_w.append(w)
		x += w + letter_spacing
	custom_minimum_size = Vector2(x, font_size * 3.4)
	_built = true


func _spawn_all() -> void:
	_drips.clear()
	for gi in _glyph_x.size():
		if message[gi] == " ":
			continue
		# 1-3 drips per glyph
		var n := randi_range(1, 3)
		for _k in n:
			_drips.append(_new_drip(gi))


func _new_drip(gi: int) -> Array:
	var w: float = _glyph_w[gi] if gi < _glyph_w.size() else 8.0
	return [
		gi,
		randf_range(0.15, 0.85),               # x offset within the glyph (0..1)
		randf_range(2.0, 6.0),                 # current streak length
		randf_range(9.0, 26.0),                # target streak length
		randf_range(5.0, 16.0),                # growth speed px/s
		-1.0,                                   # droplet y (negative = attached)
		randf_range(26.0, 70.0),               # droplet fall speed
		randf_range(0.0, 2.0),                 # delay before the droplet lets go
	]


func _process(delta: float) -> void:
	_t += delta
	for d in _drips:
		# the streak grows toward its target
		if d[2] < d[3]:
			d[2] = minf(d[3], d[2] + d[4] * delta)
		# then a droplet detaches and falls
		d[7] -= delta
		if d[7] <= 0.0:
			if d[5] < 0.0:
				d[5] = d[2]
			d[5] += d[6] * delta
			d[6] += 240.0 * delta
			# once it falls far enough, reset the drip so it bleeds again
			if d[5] > size.y - font_size:
				var fresh := _new_drip(d[0])
				for i in fresh.size():
					d[i] = fresh[i]
	queue_redraw()


func _draw() -> void:
	if not _built or font == null:
		return
	var baseline := float(font_size)
	# --- the glyphs -------------------------------------------------------
	for i in message.length():
		var ch := message[i]
		if ch == " ":
			continue
		var pos := Vector2(_glyph_x[i], baseline)
		# dark under-layer for readability over any backdrop
		draw_string(font, pos + Vector2(1.5, 1.5), ch,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.75))
		# the blood-red letter itself, with a slight pulse
		var pulse := 0.86 + 0.14 * sin(_t * 2.1 + float(i) * 0.35)
		draw_string(font, pos, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
			Color(colour.r * pulse, colour.g, colour.b, 1.0))

	# --- streaks and droplets --------------------------------------------
	for d in _drips:
		var gi: int = d[0]
		if gi >= _glyph_x.size():
			continue
		var gx: float = _glyph_x[gi] + _glyph_w[gi] * float(d[1])
		var top := baseline + 1.0
		var ln: float = float(d[2])
		# streak: a thin tapering line
		draw_line(Vector2(gx, top), Vector2(gx, top + ln), streak_colour, 2.0)
		draw_rect(Rect2(Vector2(gx - 1.9, top + ln - 1.9), Vector2(3.8, 3.8)), colour)
		# detached droplet with a fading trail
		if d[5] > 0.0:
			var dy := top + float(d[5])
			draw_line(Vector2(gx, top + ln), Vector2(gx, dy),
				Color(streak_colour.r, streak_colour.g, streak_colour.b, 0.55), 1.4)
			draw_rect(Rect2(Vector2(gx - 2.4, dy - 2.4), Vector2(4.8, 4.8)), colour)
			draw_rect(Rect2(Vector2(gx - 3.6, dy - 3.6), Vector2(7.2, 7.2)), Color(colour.r, colour.g, colour.b, 0.28))
