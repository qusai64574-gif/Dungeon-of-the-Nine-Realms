class_name MainMenuBackup
extends CanvasLayer
## Main menu matching the HTML reference design.
## Bleeding sword logo above buttons on the right.
## 3D perspective, staggered entrance, idle float.

signal start_new_run
signal continue_run
signal quit_game
signal give_up

var _root: Control
var _continue_btn: PixelButton
var _panels: Dictionary = {}
var _t: float = 0.0
var _pool_layer: Control
var _pool_drips: Array = []
var _entrance_done := false
var _exiting := false
var _state := "initializing"
var _buttons: Array[PixelButton] = []
var _btn_base_y: Array[float] = []
var _sword_logo: BloodySwordLogo
var _perspective: Node2D

# 3D perspective constants (from HTML reference)
const ROTATE_Z := -11.0 * PI / 180.0
const ROTATE_Y_SCALE := 0.927
const ENTRANCE_DELAY := 0.2
const ENTRANCE_DUR := 0.95
const IDLE_CYCLE := 9.0


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = true
	_state = "entering"
	_play_entrance()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	# --- bloody background ---
	var bg := TextureRect.new()
	bg.texture = _bloody_background_texture()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_root.add_child(bg)

	# --- blood pool layer ---
	_pool_layer = Control.new()
	_pool_layer.name = "PoolLayer"
	_pool_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pool_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pool_layer.draw.connect(_draw_pool)
	_root.add_child(_pool_layer)

	# --- 3D perspective container (LEFT side) ---
	_perspective = Node2D.new()
	_perspective.name = "Perspective"
	_perspective.position = Vector2(330, 360)
	_perspective.rotation = ROTATE_Z
	_perspective.scale = Vector2(ROTATE_Y_SCALE, 1.0)
	_root.add_child(_perspective)

	# --- sword logo ABOVE buttons ---
	_sword_logo = BloodySwordLogo.new()
	_sword_logo.name = "SwordLogo"
	_sword_logo.custom_minimum_size = Vector2(220, 220)
	_sword_logo.position = Vector2(-110, -320)
	_perspective.add_child(_sword_logo)

	# --- button stack (manual positioning for animation control) ---
	var stack := Control.new()
	stack.name = "Stack"
	stack.position = Vector2(-200, -120)
	stack.custom_minimum_size = Vector2(400, 0)
	_perspective.add_child(stack)

	var btn_y := 0.0
	_continue_btn = _stack_button(stack, "CONTINUE", DarkStyle.ACCENTS["info"], btn_y)
	_continue_btn.pressed.connect(func(): continue_run.emit())
	btn_y += 76.0

	var newb := _stack_button(stack, "NEW RUN", DarkStyle.ACCENTS["go"], btn_y)
	newb.pressed.connect(func(): start_new_run.emit())
	btn_y += 76.0

	_stack_button(stack, "SETTINGS", DarkStyle.ACCENTS["warn"], btn_y).pressed.connect(
		func(): _show("settings"))
	btn_y += 76.0
	_stack_button(stack, "BESTIARY", DarkStyle.ACCENTS["magic"], btn_y).pressed.connect(
		func(): _show("bestiary"))
	btn_y += 76.0
	_stack_button(stack, "GIVE UP", DarkStyle.ACCENTS["danger"], btn_y).pressed.connect(
		func(): give_up.emit())

	# --- stats footer ---
	var foot := BleedingLabel.new()
	foot.name = "Foot"
	DarkStyle.body(foot, 13, Color("#c93a3a"))
	foot.set_blood_colour(Color("#c93a3a"))
	foot.set_streak_colour(Color("#3a0000"))
	foot.add_theme_color_override("font_outline_color", Color("#000000"))
	foot.add_theme_constant_override("outline_size", 3)
	foot.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	foot.position = Vector2(40, -25)
	_root.add_child(foot)

	_build_settings()
	_build_bestiary()
	for k in _panels:
		_panels[k].visible = false
	_refresh()


func _stack_button(parent: Node, label: String, accent: Color, y_pos: float) -> PixelButton:
	var b := PixelButton.new()
	b.set_label(label)
	b.set_accent(accent)
	b.custom_minimum_size = Vector2(400, 64)
	b.position = Vector2(0, y_pos)
	parent.add_child(b)
	_buttons.append(b)
	_btn_base_y.append(y_pos)
	return b


# ---------------------------------------------------------------------------
# Entrance animation — staggered, smooth, no overshoot
# ---------------------------------------------------------------------------
func _play_entrance() -> void:
	_entrance_done = false
	_exiting = false
	_state = "entering"

	for b in _buttons:
		b.modulate.a = 0.0
		b.position.x += 40
		b.position.y -= 20
		b.rotation = 7.0 * PI / 180.0

	for i in _buttons.size():
		var btn: PixelButton = _buttons[i]
		var delay := float(i) * ENTRANCE_DELAY
		var tw := create_tween()
		tw.tween_interval(delay)
		tw.tween_property(btn, "modulate:a", 1.0, ENTRANCE_DUR) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(btn, "position:x", btn.position.x - 40.0, ENTRANCE_DUR) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(btn, "position:y", btn.position.y + 20.0, ENTRANCE_DUR) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(btn, "rotation", 0.0, ENTRANCE_DUR) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	var t_done := create_tween()
	t_done.tween_interval(ENTRANCE_DELAY * _buttons.size() + ENTRANCE_DUR)
	t_done.tween_callback(func():
		_entrance_done = true
		_state = "idle")


# ---------------------------------------------------------------------------
# Exit animation — bottom button exits first
# ---------------------------------------------------------------------------
func _play_exit() -> void:
	if _exiting:
		return
	_exiting = true
	_state = "exiting"

	for i in range(_buttons.size() - 1, -1, -1):
		var btn: PixelButton = _buttons[i]
		var delay := float(_buttons.size() - 1 - i) * 0.07
		var tw := create_tween()
		tw.tween_interval(delay)
		tw.tween_property(btn, "modulate:a", 0.0, 0.25) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(btn, "position:y", btn.position.y + 40.0, 0.25) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(btn, "scale", Vector2(0.9, 0.9), 0.25) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _process(delta: float) -> void:
	_t += delta
	if _state == "idle":
		for i in _buttons.size():
			var btn: PixelButton = _buttons[i]
			var phase := _t * TAU / IDLE_CYCLE + float(i) * -1.9
			btn.position.y = _btn_base_y[i] + sin(phase) * 2.5
			btn.rotation = sin(phase) * 0.01


func _bloody_background_texture() -> Texture2D:
	var w := 64
	var h := 36
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var p := Vector2(float(x) / w, float(y) / h)
			var t := p.y
			var col := Color("#0a0205").lerp(Color("#1a0508"), t)
			var stain := sin(p.x * 15.7 + p.y * 8.3) * sin(p.x * 7.1 - p.y * 11.7)
			if stain > 0.82:
				col = col.lerp(Color("#4a0000"), 0.35)
			elif stain > 0.70:
				col = col.lerp(Color("#2a0000"), 0.2)
			var bx := int(x) % 16
			var by := int(y) % 16
			if bx == 0 or by == 0:
				col = col.darkened(0.12)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


func _draw_pool() -> void:
	if _pool_layer == null:
		return
	for d in _pool_drips:
		_pool_layer.draw_rect(Rect2(Vector2(d[0] - d[2], d[1] - d[2]), Vector2(d[2] * 2, d[2] * 2)), Color("#4a0000", d[3]))


func add_drip(x: float, y: float, r: float, alpha: float) -> void:
	_pool_drips.append([x, y, r, alpha])
	if _pool_layer:
		_pool_layer.queue_redraw()


func _refresh() -> void:
	var foot: Label = _root.find_child("Foot", true, false)
	if foot:
		var sm := get_node_or_null("/root/SaveManager")
		if sm:
			foot.text = "Best depth %d     %d kills     %d runs" % [
				sm.best_depth, sm.total_kills, sm.total_runs]
	var sm2 := get_node_or_null("/root/SaveManager")
	var can_continue: bool = sm2 != null and sm2.has_save()
	_continue_btn.disabled = not can_continue
	_continue_btn.modulate = Color(1, 1, 1, 1.0) if can_continue else Color(0.5, 0.5, 0.5, 0.6)


func refresh() -> void:
	_refresh()


func _show(which: String) -> void:
	for k in _panels:
		_panels[k].visible = (k == which)


# ---------------------------------------------------------------------------
# Settings — categories on left, options on right
# ---------------------------------------------------------------------------
func _build_settings() -> void:
	var wrap := PanelContainer.new()
	wrap.add_theme_stylebox_override("panel", DarkStyle.panel())
	wrap.set_anchors_preset(Control.PRESET_CENTER)
	wrap.grow_horizontal = Control.GROW_DIRECTION_BOTH
	wrap.grow_vertical = Control.GROW_DIRECTION_BOTH
	wrap.custom_minimum_size = Vector2(700, 500)
	wrap.visible = false
	_root.add_child(wrap)
	_panels["settings"] = wrap

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	wrap.add_child(hb)

	# --- Left sidebar: categories ---
	var sidebar := VBoxContainer.new()
	sidebar.name = "Sidebar"
	sidebar.custom_minimum_size = Vector2(180, 0)
	sidebar.add_theme_constant_override("separation", 8)
	hb.add_child(sidebar)

	var categories := ["General", "Graphics", "Audio", "Controls", "Back"]
	for cat in categories:
		var cb := PixelButton.new()
		cb.set_label(cat.to_upper())
		cb.set_accent(Color("#c93a3a"))
		cb.custom_minimum_size = Vector2(0, 44)
		sidebar.add_child(cb)

	# --- Right content area ---
	var content := VBoxContainer.new()
	content.name = "Content"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	hb.add_child(content)

	var title := BleedingLabel.new()
	title.text = "SETTINGS"
	DarkStyle.heading(title, 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)

	var sm := get_node("/root/SaveManager")
	_slider_row(content, "Master volume", 0.0, 1.0, 0.05, sm.master_volume, func(v): sm.master_volume = v)
	_slider_row(content, "Brightness", 0.5, 1.5, 0.05, sm.brightness, func(v): sm.brightness = v)
	_slider_row(content, "Camera zoom", 1.5, 5.0, 0.1, sm.camera_zoom, func(v): sm.camera_zoom = v)
	_toggle_row(content, "Damage numbers", sm.show_damage_numbers, func(v): sm.show_damage_numbers = v)
	_toggle_row(content, "Screen shake", sm.screen_shake, func(v): sm.screen_shake = v)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	content.add_child(row)
	var save_b := PixelButton.new()
	save_b.set_label("SAVE")
	save_b.set_accent(DarkStyle.ACCENTS["go"])
	save_b.custom_minimum_size = Vector2(0, 48)
	save_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_b.pressed.connect(func():
		sm.save_settings()
		EventBus.settings_applied.emit()
		EventBus.toast_msg("SETTINGS SAVED", Color("#8fe0a0")))
	row.add_child(save_b)

	var back := PixelButton.new()
	back.set_label("BACK")
	back.set_accent(DarkStyle.ACCENTS["neutral"])
	back.custom_minimum_size = Vector2(140, 48)
	back.pressed.connect(func(): _show(""))
	row.add_child(back)


func _slider_row(parent: Node, label: String, mn: float, mx: float, step: float,
		value: float, setter: Callable) -> void:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	parent.add_child(row)
	var head := HBoxContainer.new()
	row.add_child(head)
	var l := BleedingLabel.new(); l.text = label
	DarkStyle.body(l, 15, Color("#c93a3a"))
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(l)
	var v := BleedingLabel.new(); v.text = "%.2f" % value
	DarkStyle.body(v, 15, Color("#c93a3a"))
	head.add_child(v)
	var sl := HSlider.new()
	sl.min_value = mn; sl.max_value = mx; sl.step = step; sl.value = value
	sl.custom_minimum_size = Vector2(0, 22)
	sl.value_changed.connect(func(nv: float):
		setter.call(nv)
		v.text = "%.2f" % nv
		EventBus.settings_applied.emit())
	row.add_child(sl)


func _toggle_row(parent: Node, label: String, value: bool, setter: Callable) -> void:
	var cb := CheckButton.new()
	cb.text = label
	cb.button_pressed = value
	cb.add_theme_font_override("font", DarkStyle.font_ui())
	cb.add_theme_font_size_override("font_size", 15)
	cb.add_theme_color_override("font_color", Color("#c93a3a"))
	cb.toggled.connect(func(v: bool):
		setter.call(v)
		EventBus.settings_applied.emit())
	parent.add_child(cb)


# ---------------------------------------------------------------------------
# Bestiary
# ---------------------------------------------------------------------------
func _build_bestiary() -> void:
	var wrap := PanelContainer.new()
	wrap.add_theme_stylebox_override("panel", DarkStyle.panel(DarkStyle.PANEL_HI))
	wrap.set_anchors_preset(Control.PRESET_CENTER)
	wrap.grow_horizontal = Control.GROW_DIRECTION_BOTH
	wrap.grow_vertical = Control.GROW_DIRECTION_BOTH
	wrap.custom_minimum_size = Vector2(720, 540)
	wrap.visible = false
	_root.add_child(wrap)
	_panels["bestiary"] = wrap

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	wrap.add_child(vb)

	var t := BleedingLabel.new(); t.text = "BESTIARY"
	DarkStyle.heading(t, 36)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)

	var well_panel := PanelContainer.new()
	well_panel.add_theme_stylebox_override("panel", DarkStyle.well())
	well_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(well_panel)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	well_panel.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)

	for id in EnemyDB.TYPES:
		var d: Dictionary = EnemyDB.TYPES[id]
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", DarkStyle.block(DarkStyle.PANEL_HI, 2, 3))
		list.add_child(row)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)
		row.add_child(hb)
		var ic := TextureRect.new()
		ic.texture = load(Assets.char_sheet(String(d["key"])))
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.custom_minimum_size = Vector2(40, 40)
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hb.add_child(ic)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(col)
		var nm := BleedingLabel.new()
		nm.text = "%s   —   HP %d   DMG %d   SPD %.0f" % [
			String(d["name"]), int(d["hp"]), int(d["damage"]), float(d["speed"])]
		DarkStyle.body(nm, 15, Color("#c93a3a"))
		col.add_child(nm)
		var lo := BleedingLabel.new()
		lo.text = EnemyDB.lore(id)
		lo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lo.custom_minimum_size = Vector2(520, 0)
		DarkStyle.body(lo, 13, Color("#c93a3a"))
		col.add_child(lo)

	var back := PixelButton.new()
	back.set_label("BACK")
	back.set_accent(DarkStyle.ACCENTS["neutral"])
	back.custom_minimum_size = Vector2(0, 48)
	back.pressed.connect(func(): _show(""))
	vb.add_child(back)
