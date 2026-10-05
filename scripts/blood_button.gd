class_name BloodButton
extends Button
## Black button with blood-red text. Blood drips from the text baseline and
## pools on the button below. Hover: text brightens, drips speed up, sparks
## fly, and a light band sweeps across. Press: punch down then spring back.

var _label: Label
var _drips: Array = []          # [x_off, len, target_len, speed, drop_y, drop_vy, delay]
var _t: float = 0.0
var _hovered := false
var _base_y: float = 0.0
var _accent: Color = Color("#c8161e")

# blood pool drawn on the button below
var _pool_target: Control = null

# pizza-game juice
var _particles: UIParticles
var _clip: Control
var _sweep: TextureRect
var _glow: ColorRect
var _tween: Tween
var _sweep_tween: Tween
var _hover_scale: float = 1.075
var _punch_scale: float = 0.94
var _ready_done := false


func _init() -> void:
	custom_minimum_size = Vector2(0, 52)


func _ready() -> void:
	_ready_done = true
	_build()


func _build() -> void:
	# black stylebox
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#0d0508")
	sb.border_color = Color("#7a1016")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	add_theme_stylebox_override("normal", sb)

	var sbh := sb.duplicate()
	sbh.bg_color = Color("#1a0a10")
	sbh.border_color = Color("#7a1016")
	add_theme_stylebox_override("hover", sbh)

	var sbp := sb.duplicate()
	sbp.bg_color = Color("#050203")
	sbp.border_color = Color("#4a0000")
	add_theme_stylebox_override("pressed", sbp)

	var sbd := sb.duplicate()
	sbd.bg_color = Color("#080406")
	sbd.border_color = Color("#2a0a0e")
	add_theme_stylebox_override("disabled", sbd)

	# the label
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_override("font", DarkStyle.font_display())
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", _accent)
	_label.add_theme_color_override("font_hover_color", _accent.lightened(0.3))
	_label.add_theme_color_override("font_pressed_color", _accent.darkened(0.3))
	_label.add_theme_color_override("font_outline_color", Color("#000000"))
	_label.add_theme_color_override("font_shadow_color", Color("#4a0000"))
	_label.add_theme_constant_override("outline_size", 2)
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 2)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

	# blood drips
	_spawn_drips()

	# --- pizza-game juice: particles, sweep band, glow ---------------------
	_particles = UIParticles.new()
	_particles.name = "UIParticles"
	_particles.set_anchors_preset(Control.PRESET_FULL_RECT)
	_particles.offset_left = -40
	_particles.offset_right = 40
	_particles.offset_top = -30
	_particles.offset_bottom = 30
	add_child(_particles)

	_clip = Control.new()
	_clip.name = "Clip"
	_clip.set_anchors_preset(Control.PRESET_FULL_RECT)
	_clip.clip_contents = true
	_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_clip)

	_sweep = TextureRect.new()
	_sweep.name = "Sweep"
	_sweep.texture = _sheen_texture()
	_sweep.stretch_mode = TextureRect.STRETCH_SCALE
	_sweep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sweep.position = Vector2(-90, -8)
	_sweep.size = Vector2(56, 80)
	_sweep.rotation = 0.30
	_sweep.modulate = Color(1, 1, 1, 0.0)
	_sweep.visible = false
	_clip.add_child(_sweep)

	_glow = ColorRect.new()
	_glow.name = "Glow"
	_glow.color = Color(_accent.r, _accent.g, _accent.b, 0.0)
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_glow.visible = false
	_clip.add_child(_glow)
	_clip.move_child(_glow, 0)

	pivot_offset = size * 0.5
	mouse_entered.connect(_on_enter)
	mouse_exited.connect(_on_exit)
	button_down.connect(_on_down)
	button_up.connect(_on_up)
	pressed.connect(_on_pressed)
	resized.connect(_sync_geometry)
	_sync_geometry()
	_base_y = position.y


func _sheen_texture() -> Texture2D:
	var w := 16
	var h := 4
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for x in w:
		var f := float(x) / float(w - 1)
		var a := sin(f * PI)
		a = pow(a, 1.7)
		for y in h:
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


func _sync_geometry() -> void:
	if not _ready_done:
		return
	pivot_offset = size * 0.5
	if _sweep:
		_sweep.size = Vector2(56, size.y + 40)


func _spawn_drips() -> void:
	_drips.clear()
	var n := randi_range(4, 7)
	for _i in n:
		_drips.append(_new_drip())


func _new_drip() -> Array:
	return [
		randf_range(0.1, 0.9),       # x offset (0..1 across button width)
		randf_range(1.0, 4.0),       # current streak length
		randf_range(6.0, 20.0),      # target streak length
		randf_range(4.0, 12.0),      # growth speed px/s
		-1.0,                         # droplet y (-1 = attached)
		randf_range(20.0, 60.0),     # droplet fall speed
		randf_range(0.0, 3.0),       # delay before droplet detaches
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

	# subtle press animation
	if _base_y == 0.0:
		_base_y = position.y
	var target_y := _base_y
	if is_pressed():
		target_y = _base_y + 3.0
	position.y = lerp(position.y, target_y, 0.3)


func _draw() -> void:
	if _label == null:
		return
	var text := _label.text
	if text.is_empty():
		return
	var font: Font = _label.get_theme_font("font")
	var font_size: int = _label.get_theme_font_size("font_size")
	var text_w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var start_x := (size.x - text_w) * 0.5
	var baseline := size.y * 0.5 + font_size * 0.35

	# draw blood streaks under each character
	for d in _drips:
		var gx := start_x + text_w * float(d[0])
		var top := baseline + 1.0
		var ln: float = float(d[1])
		# streak
		draw_line(Vector2(gx, top), Vector2(gx, top + ln), Color("#4a0000"), 2.0)
		draw_rect(Rect2(Vector2(gx - 1.8, top + ln - 1.8), Vector2(3.6, 3.6)), Color("#8b0000"))
		# detached droplet
		if d[4] > 0.0:
			var dy := top + float(d[4])
			draw_line(Vector2(gx, top + ln), Vector2(gx, dy),
				Color("#4a0000", 0.5), 1.2)
			draw_rect(Rect2(Vector2(gx - 2.2, dy - 2.2), Vector2(4.4, 4.4)), Color("#8b0000"))
			draw_rect(Rect2(Vector2(gx - 3.4, dy - 3.4), Vector2(6.8, 6.8)), Color("#8b0000", 0.25))


# ---------------------------------------------------------------------------
# Pizza-game juice: hover sparks + sweep, press punch + spring
# ---------------------------------------------------------------------------
func _on_enter() -> void:
	_hovered = true
	_animate_to(_hover_scale, 0.13)
	if _particles:
		_particles.burst(10, _accent, 150.0, Vector2(0, size.y * 0.5), 2.0)
		_particles.burst(10, _accent.lightened(0.35), 150.0, Vector2(size.x, size.y * 0.5), 2.0)
	_sweep_band()


func _on_exit() -> void:
	_hovered = false
	_animate_to(1.0, 0.16)
	if _sweep_tween:
		_sweep_tween.kill()
	var tw := create_tween()
	tw.tween_property(_sweep, "modulate:a", 0.0, 0.14)
	tw.parallel().tween_property(_glow, "color:a", 0.0, 0.16)
	tw.chain().tween_callback(func():
		_sweep.visible = false
		_glow.visible = false)


func _on_down() -> void:
	# collapse: punch down
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2(_punch_scale, _punch_scale), 0.06)


func _on_up() -> void:
	if _hovered:
		_on_enter()
	else:
		_on_exit()


func _animate_to(s: float, dur: float) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2(s, s), dur)


func _sweep_band() -> void:
	if _sweep_tween and _sweep_tween.is_valid():
		_sweep_tween.kill()
	_sweep.visible = true
	_glow.visible = true
	_sweep.position.x = -90.0
	_sweep.modulate = Color(1, 1, 1, 0.0)
	_sweep_tween = create_tween()
	_sweep_tween.set_parallel(true)
	_sweep_tween.tween_property(_sweep, "position:x", size.x + 70.0, 0.34) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_sweep_tween.tween_property(_sweep, "modulate:a", 0.30, 0.09)
	_sweep_tween.chain().tween_property(_sweep, "modulate:a", 0.0, 0.22)
	# glow bloom
	var g := create_tween()
	g.tween_property(_glow, "color:a", 0.10, 0.10)
	g.tween_property(_glow, "color:a", 0.03, 0.28)


func _on_pressed() -> void:
	# punch down then spring back
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2(_punch_scale, _punch_scale), 0.06)
	_tween.tween_property(self, "scale", Vector2(_hover_scale, _hover_scale), 0.16) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _particles:
		_particles.burst(18, _accent, 210.0, size * 0.5, 0.0)
		_particles.ring(_accent.lightened(0.4), size * 0.5, minf(size.x, size.y) * 0.45, 14)
	# spawn blood pool on the button below
	if _pool_target != null and _pool_target.has_method("add_drip"):
		for d in _drips:
			var gx := size.x * float(d[0])
			_pool_target.add_drip(gx, size.y + 2.0, randf_range(2.0, 5.0), 0.6)
		_pool_target.queue_redraw()


func set_pool_target(ctrl: Control) -> void:
	_pool_target = ctrl


func set_label(t: String) -> void:
	text = t
	if _label:
		_label.text = t


func set_accent(c: Color) -> void:
	_accent = c
	if _label:
		_label.add_theme_color_override("font_color", c)
	if _glow:
		_glow.color = Color(c.r, c.g, c.b, 0.0)
