class_name PauseMenuBackup
extends CanvasLayer
## Pause menu matching the HTML reference design.
## Bleeding sword logo above buttons on the right.
## 3D perspective, staggered entrance, idle float.

signal give_up

var is_open: bool = false
var _root: Control
var _panels: Dictionary = {}
var _t: float = 0.0
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
	layer = 45
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false
	_state = "idle"


func toggle() -> void:
	set_open(not is_open)


func set_open(v: bool) -> void:
	is_open = v
	visible = v
	get_tree().paused = v
	if v:
		_entrance_done = false
		_exiting = false
		_state = "entering"
		_play_entrance()
	else:
		_state = "idle"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and is_open:
		set_open(false)
		get_viewport().set_input_as_handled()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_root)

	# --- bloody background ---
	var bg := TextureRect.new()
	bg.texture = _bloody_background_texture()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_root.add_child(bg)

	# --- dim the frozen world ---
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.01, 0.03, 0.72)
	_root.add_child(dim)

	# --- 3D perspective container (right side) ---
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
	_pbtn(stack, "RESUME", func(): set_open(false), DarkStyle.ACCENTS["go"], btn_y)
	btn_y += 74.0
	_pbtn(stack, "SAVE NOW", func():
		var sm := get_node("/root/SaveManager")
		sm.save_run()
		EventBus.toast_msg("RUN SAVED", Color("#8fe0a0")), DarkStyle.ACCENTS["info"], btn_y)
	btn_y += 74.0
	_pbtn(stack, "SETTINGS", func(): _show("settings"), DarkStyle.ACCENTS["warn"], btn_y)
	btn_y += 74.0
	_pbtn(stack, "SAVE & QUIT TO MENU", func():
		get_node("/root/SaveManager").save_run()
		EventBus.request_to_menu.emit(), DarkStyle.ACCENTS["magic"], btn_y)
	btn_y += 74.0
	_pbtn(stack, "GIVE UP", func(): give_up.emit(), DarkStyle.ACCENTS["danger"], btn_y)

	_build_settings()


func _pbtn(parent: Node, text: String, cb: Callable, accent: Color, y_pos: float) -> PixelButton:
	var b := PixelButton.new()
	b.set_label(text)
	b.set_accent(accent)
	b.custom_minimum_size = Vector2(0, 60)
	b.position = Vector2(0, y_pos)
	b.pressed.connect(cb)
	parent.add_child(b)
	_buttons.append(b)
	_btn_base_y.append(y_pos)
	return b


# ---------------------------------------------------------------------------
# Entrance animation — 3D staggered, smooth, no overshoot
# ---------------------------------------------------------------------------
func _play_entrance() -> void:
	_entrance_done = false
	_exiting = false
	_state = "entering"

	for i in _buttons.size():
		var btn: PixelButton = _buttons[i]
		btn.modulate.a = 0.0
		btn.position = Vector2(40, -20)
		btn.rotation = 7.0 * PI / 180.0

	for i in _buttons.size():
		var btn: PixelButton = _buttons[i]
		var delay := float(i) * ENTRANCE_DELAY
		var tw := create_tween()
		tw.tween_interval(delay)
		tw.tween_property(btn, "modulate:a", 1.0, ENTRANCE_DUR) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(btn, "position", Vector2.ZERO, ENTRANCE_DUR) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(btn, "rotation", 0.0, ENTRANCE_DUR) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	var t_done := create_tween()
	t_done.tween_interval(ENTRANCE_DELAY * _buttons.size() + ENTRANCE_DUR)
	t_done.tween_callback(func():
		_entrance_done = true
		_state = "idle")


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


func _show(which: String) -> void:
	for k in _panels:
		_panels[k].visible = (k == which)


func _build_settings() -> void:
	var wrap := PanelContainer.new()
	wrap.add_theme_stylebox_override("panel", DarkStyle.panel(DarkStyle.PANEL_HI))
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
	DarkStyle.body(l, 16, Color("#8a6068"))
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(l)
	var v := BleedingLabel.new(); v.text = "%.2f" % value
	DarkStyle.body(v, 16, DarkStyle.INK)
	head.add_child(v)
	var sl := HSlider.new()
	sl.min_value = mn; sl.max_value = mx; sl.step = step; sl.value = value
	sl.custom_minimum_size = Vector2(0, 24)
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
	cb.add_theme_font_size_override("font_size", 16)
	cb.add_theme_color_override("font_color", Color("#8a6068"))
	cb.toggled.connect(func(v: bool):
		setter.call(v)
		EventBus.settings_applied.emit())
	parent.add_child(cb)
