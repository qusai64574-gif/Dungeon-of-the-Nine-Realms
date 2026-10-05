class_name GameOverScreen
extends CanvasLayer
## Game over screen — scary red theme, webs, violent letter shaking.
## When GIVE UP is clicked, opens the GiveUpScreen.

signal restart_requested
signal give_up_requested

var is_open: bool = false

var _root: Control
var _red: ColorRect
var _dark: ColorRect
var _vignette: TextureRect
var _webs: Control
var _cracks: Control
var _heart: ColorRect
var _big: ShakingLabel
var _sub: ShakingLabel
var _stats: ShakingLabel
var _row: HBoxContainer
var _yes: BleedingButton
var _keep_suffering: BleedingButton
var _giveup_btn: BleedingButton
var _flash: ColorRect
var _t: float = 0.0
var _beat: float = 0.0
var _crack_lines: Array = []


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false


func open() -> void:
	is_open = true
	visible = true
	_play_intro()


func close() -> void:
	is_open = false
	visible = false


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	_red = ColorRect.new()
	_red.set_anchors_preset(Control.PRESET_FULL_RECT)
	_red.color = Color(0.42, 0.03, 0.05, 0.0)
	_root.add_child(_red)

	_dark = ColorRect.new()
	_dark.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dark.color = Color(0.02, 0.0, 0.0, 0.0)
	_root.add_child(_dark)

	_vignette = TextureRect.new()
	_vignette.texture = _vignette_tex()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vignette.modulate = Color(0, 0, 0, 0.0)
	_root.add_child(_vignette)

	# Spider webs in corners
	_webs = Control.new()
	_webs.name = "Webs"
	_webs.set_anchors_preset(Control.PRESET_FULL_RECT)
	_webs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_webs.draw.connect(_draw_webs)
	_root.add_child(_webs)

	_cracks = Control.new()
	_cracks.name = "Cracks"
	_cracks.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cracks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cracks.draw.connect(_draw_cracks)
	_root.add_child(_cracks)

	_heart = ColorRect.new()
	_heart.set_anchors_preset(Control.PRESET_FULL_RECT)
	_heart.color = Color(0.6, 0.0, 0.03, 0.0)
	_heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_heart)

	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(centre)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	centre.add_child(col)

	# Title — every letter shakes violently
	_big = ShakingLabel.new()
	_big.text = "SUFFER AGAIN????"
	_big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_big.add_theme_font_override("font", DarkStyle.font_display())
	_big.add_theme_font_size_override("font_size", 56)
	_big.add_theme_color_override("font_color", Color("#e0141c"))
	_big.add_theme_color_override("font_outline_color", Color("#2a0306"))
	_big.add_theme_constant_override("outline_size", 12)
	_big.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_big.add_theme_constant_override("shadow_offset_x", 3)
	_big.add_theme_constant_override("shadow_offset_y", 5)
	_big.set_shake_amount(2.5)
	_big.set_shake_speed(18.0)
	col.add_child(_big)

	_sub = ShakingLabel.new()
	_sub.text = "The dungeon keeps what it takes."
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.add_theme_font_override("font", DarkStyle.font_display())
	_sub.add_theme_font_size_override("font_size", 22)
	_sub.add_theme_color_override("font_color", Color("#c8161e"))
	_sub.add_theme_color_override("font_outline_color", Color("#000000"))
	_sub.add_theme_constant_override("outline_size", 4)
	_sub.set_shake_amount(1.5)
	_sub.set_shake_speed(14.0)
	col.add_child(_sub)

	_stats = ShakingLabel.new()
	_stats.text = ""
	_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stats.custom_minimum_size = Vector2(500, 0)
	_stats.add_theme_font_override("font", DarkStyle.font_display())
	_stats.add_theme_font_size_override("font_size", 16)
	_stats.add_theme_color_override("font_color", Color("#8a6068"))
	_stats.add_theme_color_override("font_outline_color", Color("#000000"))
	_stats.add_theme_constant_override("outline_size", 2)
	_stats.set_shake_amount(1.0)
	_stats.set_shake_speed(10.0)
	col.add_child(_stats)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	col.add_child(spacer)

	_row = HBoxContainer.new()
	_row.name = "ButtonRow"
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 30)
	col.add_child(_row)

	_yes = BleedingButton.new()
	_yes.text = "YES"
	_yes.custom_minimum_size = Vector2(220, 56)
	_yes.size = Vector2(220, 56)
	_yes.pressed.connect(func(): restart_requested.emit())
	_row.add_child(_yes)

	_keep_suffering = BleedingButton.new()
	_keep_suffering.text = "KEEP SUFFERING"
	_keep_suffering.custom_minimum_size = Vector2(280, 56)
	_keep_suffering.size = Vector2(280, 56)
	_keep_suffering.pressed.connect(func(): restart_requested.emit())
	_row.add_child(_keep_suffering)

	# Black bleeding skull on KEEP SUFFERING
	var skull := BleedingSkull.new()
	skull.custom_minimum_size = Vector2(36, 36)
	skull.size = Vector2(36, 36)
	skull.position = Vector2(8, 10)
	skull.set_black(true)
	_keep_suffering.add_child(skull)

	_giveup_btn = BleedingButton.new()
	_giveup_btn.text = "GIVE UP"
	_giveup_btn.custom_minimum_size = Vector2(220, 56)
	_giveup_btn.size = Vector2(220, 56)
	_giveup_btn.pressed.connect(func(): give_up_requested.emit())
	_row.add_child(_giveup_btn)

	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(1, 1, 1, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_flash)


func set_stats(text: String) -> void:
	_stats.text = text


func _vignette_tex() -> Texture2D:
	var s := 128
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	var c := Vector2(s * 0.5, s * 0.5)
	var maxd := c.length()
	for y in s:
		for x in s:
			var d := Vector2(x - c.x, y - c.y).length() / maxd
			var a := clampf(pow(d, 2.1) * 1.15, 0.0, 1.0)
			img.set_pixel(x, y, Color(0, 0, 0, a))
	return ImageTexture.create_from_image(img)


func _play_intro() -> void:
	_t = 0.0
	_crack_lines.clear()

	_flash.color = Color(1, 1, 1, 0.9)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_flash, "color:a", 0.0, 0.12)
	tw.tween_property(_red, "color:a", 0.93, 0.16).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(_dark, "color:a", 0.35, 0.30)
	tw.tween_property(_vignette, "modulate:a", 0.95, 0.40)

	_big.scale = Vector2(2.4, 2.4)
	_big.modulate.a = 0.0
	var t2 := create_tween()
	t2.tween_property(_big, "scale", Vector2.ONE, 0.26) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	t2.parallel().tween_property(_big, "modulate:a", 1.0, 0.10)

	_row.modulate.a = 1.0

	_spawn_cracks()


func _spawn_cracks() -> void:
	_crack_lines.clear()
	var cx := 640.0
	var cy := 340.0
	for i in 14:
		var a := TAU * float(i) / 14.0 + randf_range(-0.2, 0.2)
		var pts: Array[Vector2] = [Vector2(cx, cy)]
		var p := Vector2(cx, cy)
		var segs := randi_range(3, 6)
		for _s in segs:
			a += randf_range(-0.55, 0.55)
			p += Vector2.RIGHT.rotated(a) * randf_range(34.0, 96.0)
			pts.append(p)
		_crack_lines.append({"pts": pts, "grow": 0.0, "speed": randf_range(1.4, 2.6),
			"delay": randf_range(0.0, 0.30), "w": randf_range(1.4, 3.2)})


func _process(delta: float) -> void:
	if not is_open:
		return
	_t += delta

	# heartbeat
	_beat += delta * 1.15
	var ph := fmod(_beat, 1.0)
	var thump := exp(-ph * 12.0) + 0.55 * exp(-absf(ph - 0.28) * 14.0)
	_heart.color = Color(0.62, 0.0, 0.03, clampf(thump * 0.30, 0.0, 0.42))

	# grow cracks
	for c in _crack_lines:
		if c["delay"] > 0.0:
			c["delay"] -= delta
			continue
		if c["grow"] < 1.0:
			c["grow"] = minf(1.0, float(c["grow"]) + float(c["speed"]) * delta)
	if _cracks:
		_cracks.queue_redraw()

	# VIOLENT fear shaking — heartbeat synced
	var amp := 2.0 + thump * 3.0
	_big.position = Vector2(randf_range(-amp, amp), randf_range(-amp, amp))
	_yes.position = Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))
	_giveup_btn.position = Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))

	# red wash pulses
	if _red:
		_red.color = Color(0.42 + thump * 0.10, 0.03, 0.05, _red.color.a)


func _draw_cracks() -> void:
	if _cracks == null:
		return
	for c in _crack_lines:
		if c["delay"] > 0.0 or c["grow"] <= 0.0:
			continue
		var pts: Array = c["pts"]
		var total := float(pts.size() - 1)
		var upto := float(c["grow"]) * total
		var full := int(floor(upto))
		for i in mini(full, pts.size() - 1):
			_cracks.draw_line(pts[i], pts[i + 1], Color(0.05, 0.0, 0.0, 0.85), float(c["w"]))
		if full < pts.size() - 1:
			var frac := upto - float(full)
			var a: Vector2 = pts[full]
			var b: Vector2 = pts[full + 1]
			_cracks.draw_line(a, a.lerp(b, frac), Color(0.05, 0.0, 0.0, 0.85), float(c["w"]))


func _draw_webs() -> void:
	if _webs == null:
		return
	# Draw spider webs in all 4 corners
	var w := 1280.0
	var h := 720.0
	var web_len := 180.0
	var strands := 8
	var alpha := 0.25

	# Top-left corner
	for i in strands:
		var a := TAU * float(i) / float(strands)
		var pts: Array[Vector2] = [Vector2(0, 0)]
		var p := Vector2(0, 0)
		for s in 4:
			p += Vector2.RIGHT.rotated(a) * (web_len / 4.0)
			pts.append(p)
		for j in pts.size() - 1:
			_webs.draw_line(pts[j], pts[j + 1], Color(0.8, 0.8, 0.8, alpha), 1.0)

	# Top-right corner
	for i in strands:
		var a := TAU * float(i) / float(strands)
		var pts: Array[Vector2] = [Vector2(w, 0)]
		var p := Vector2(w, 0)
		for s in 4:
			p += Vector2.RIGHT.rotated(a) * (web_len / 4.0)
			pts.append(p)
		for j in pts.size() - 1:
			_webs.draw_line(pts[j], pts[j + 1], Color(0.8, 0.8, 0.8, alpha), 1.0)

	# Bottom-left corner
	for i in strands:
		var a := TAU * float(i) / float(strands)
		var pts: Array[Vector2] = [Vector2(0, h)]
		var p := Vector2(0, h)
		for s in 4:
			p += Vector2.RIGHT.rotated(a) * (web_len / 4.0)
			pts.append(p)
		for j in pts.size() - 1:
			_webs.draw_line(pts[j], pts[j + 1], Color(0.8, 0.8, 0.8, alpha), 1.0)

	# Bottom-right corner
	for i in strands:
		var a := TAU * float(i) / float(strands)
		var pts: Array[Vector2] = [Vector2(w, h)]
		var p := Vector2(w, h)
		for s in 4:
			p += Vector2.RIGHT.rotated(a) * (web_len / 4.0)
			pts.append(p)
		for j in pts.size() - 1:
			_webs.draw_line(pts[j], pts[j + 1], Color(0.8, 0.8, 0.8, alpha), 1.0)

	# Web arcs — concentric curves
	for corner in [Vector2(0, 0), Vector2(w, 0), Vector2(0, h), Vector2(w, h)]:
		for r in range(20, int(web_len), 25):
			var pts2: Array[Vector2] = []
			for i in 12:
				var a := TAU * float(i) / 12.0
				var offset := Vector2.RIGHT.rotated(a) * float(r)
				pts2.append(corner + offset)
			for j in pts2.size() - 1:
				_webs.draw_line(pts2[j], pts2[j + 1], Color(0.8, 0.8, 0.8, alpha * 0.5), 0.5)


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
