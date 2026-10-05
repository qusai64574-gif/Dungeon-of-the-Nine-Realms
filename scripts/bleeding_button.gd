class_name BleedingButton
extends Button
## Button with bleeding text. Dark red style, blood drips from text.

var _drips: Array = []
var _t: float = 0.0
var _hovered := false
var _blood_colour: Color = Color("#8b0000")
var _streak_colour: Color = Color("#4a0000")
var _drip_density: float = 1.5


func _init() -> void:
	custom_minimum_size = Vector2(0, 52)
	_spawn_drips()


func _ready() -> void:
	# Dark red style
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#2a0505")
	sb.border_color = Color("#8b0000")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	add_theme_stylebox_override("normal", sb)

	var sbh := sb.duplicate()
	sbh.bg_color = Color("#4a0808")
	sbh.border_color = Color("#c93a3a")
	add_theme_stylebox_override("hover", sbh)

	var sbp := sb.duplicate()
	sbp.bg_color = Color("#1a0202")
	sbp.border_color = Color("#4a0000")
	add_theme_stylebox_override("pressed", sbp)

	add_theme_font_override("font", DarkStyle.font_display())
	add_theme_font_size_override("font_size", 26)
	add_theme_color_override("font_color", Color("#c93a3a"))
	add_theme_color_override("font_hover_color", Color("#ff4444"))
	add_theme_color_override("font_pressed_color", Color("#ff4444"))
	add_theme_color_override("font_outline_color", Color("#000000"))
	add_theme_constant_override("outline_size", 2)

	mouse_entered.connect(func(): _hovered = true)
	mouse_exited.connect(func(): _hovered = false)


func _spawn_drips() -> void:
	_drips.clear()
	var n := int((randi_range(4, 7)) * _drip_density)
	for _i in n:
		_drips.append(_new_drip())


func _new_drip() -> Array:
	return [
		randf_range(0.1, 0.9),
		randf_range(1.0, 4.0),
		randf_range(6.0, 20.0),
		randf_range(4.0, 12.0),
		-1.0,
		randf_range(20.0, 60.0),
		randf_range(0.0, 3.0),
	]


func _process(delta: float) -> void:
	_t += delta
	var speed_mult := 2.0 if _hovered else 1.0
	for d in _drips:
		if d[1] < d[2]:
			d[1] = minf(d[2], d[1] + d[3] * speed_mult * delta)
		d[6] -= delta * speed_mult
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
	if text.is_empty():
		return
	var font: Font = get_theme_font("font")
	var font_size: int = get_theme_font_size("font_size")
	var text_w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var start_x := (size.x - text_w) * 0.5
	var baseline := size.y * 0.5 + font_size * 0.35

	for d in _drips:
		var gx := start_x + text_w * float(d[0])
		var top := baseline + 1.0
		var ln: float = float(d[1])
		draw_line(Vector2(gx, top), Vector2(gx, top + ln), _streak_colour, 2.0)
		draw_rect(Rect2(Vector2(gx - 1.8, top + ln - 1.8), Vector2(3.6, 3.6)), _blood_colour)
		if d[4] > 0.0:
			var dy := top + float(d[4])
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
