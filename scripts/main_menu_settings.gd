class_name MainMenuSettings
extends CanvasLayer
## Main menu settings — animated panel with sliders and toggles.

signal closed

var _root: Control
var _t: float = 0.0
var _visible := false
var _sliders: Array = []
var _toggles: Array = []


func _ready() -> void:
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.size = Vector2(1280, 720)
	add_child(_root)

	# Dark background
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.01, 0.03, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)

	# Title
	var title := ShakingLabel.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(440, 30)
	title.size = Vector2(400, 60)
	title.add_theme_font_override("font", DarkStyle.font_display())
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color("#c93a3a"))
	title.add_theme_color_override("font_outline_color", Color("#000000"))
	title.add_theme_constant_override("outline_size", 4)
	title.set_shake_amount(2.0)
	title.set_shake_speed(6.0)
	_root.add_child(title)

	# Close button
	var close_btn := BleedingButton.new()
	close_btn.text = "CLOSE"
	close_btn.custom_minimum_size = Vector2(120, 40)
	close_btn.size = Vector2(120, 40)
	close_btn.position = Vector2(1120, 30)
	close_btn.pressed.connect(func(): close())
	_root.add_child(close_btn)

	# Settings panel
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", DarkStyle.panel())
	panel.custom_minimum_size = Vector2(600, 500)
	panel.position = Vector2(340, 120)
	_root.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	panel.add_child(vb)

	var sm := get_node("/root/SaveManager")

	# Sliders
	_add_slider(vb, "Master Volume", 0.0, 1.0, 0.05, sm.master_volume, func(v): sm.master_volume = v)
	_add_slider(vb, "Brightness", 0.5, 1.5, 0.05, sm.brightness, func(v): sm.brightness = v)
	_add_slider(vb, "Camera Zoom", 1.5, 5.0, 0.1, sm.camera_zoom, func(v): sm.camera_zoom = v)

	# Toggles
	_add_toggle(vb, "Damage Numbers", sm.show_damage_numbers, func(v): sm.show_damage_numbers = v)
	_add_toggle(vb, "Screen Shake", sm.screen_shake, func(v): sm.screen_shake = v)

	# Save button
	var save_btn := BleedingButton.new()
	save_btn.text = "SAVE SETTINGS"
	save_btn.custom_minimum_size = Vector2(0, 50)
	save_btn.size = Vector2(0, 50)
	save_btn.pressed.connect(func():
		sm.save_settings()
		EventBus.settings_applied.emit())
	vb.add_child(save_btn)


func _add_slider(parent: Node, label: String, mn: float, mx: float, step: float, value: float, setter: Callable) -> void:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)

	var head := HBoxContainer.new()
	row.add_child(head)

	var l := Label.new()
	l.text = label
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_override("font", DarkStyle.font_display())
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Color("#c93a3a"))
	l.add_theme_color_override("font_outline_color", Color("#000000"))
	l.add_theme_constant_override("outline_size", 2)
	head.add_child(l)

	var v := Label.new()
	v.text = "%.2f" % value
	v.add_theme_font_override("font", DarkStyle.font_display())
	v.add_theme_font_size_override("font_size", 18)
	v.add_theme_color_override("font_color", Color("#8a6068"))
	v.add_theme_color_override("font_outline_color", Color("#000000"))
	v.add_theme_constant_override("outline_size", 2)
	head.add_child(v)

	var sl := HSlider.new()
	sl.min_value = mn
	sl.max_value = mx
	sl.step = step
	sl.value = value
	sl.custom_minimum_size = Vector2(0, 30)
	sl.value_changed.connect(func(nv: float):
		setter.call(nv)
		v.text = "%.2f" % nv
		EventBus.settings_applied.emit())
	row.add_child(sl)

	_sliders.append({"slider": sl, "label": v})


func _add_toggle(parent: Node, label: String, value: bool, setter: Callable) -> void:
	var cb := CheckButton.new()
	cb.text = label
	cb.button_pressed = value
	cb.add_theme_font_override("font", DarkStyle.font_display())
	cb.add_theme_font_size_override("font_size", 18)
	cb.add_theme_color_override("font_color", Color("#c93a3a"))
	cb.add_theme_color_override("font_outline_color", Color("#000000"))
	cb.add_theme_constant_override("outline_size", 2)
	cb.toggled.connect(func(v: bool):
		setter.call(v)
		EventBus.settings_applied.emit())
	parent.add_child(cb)
	_toggles.append(cb)


func open_panel() -> void:
	_visible = true
	visible = true
	_t = 0.0
	# Entrance animation — panel slides in
	_root.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_root, "modulate:a", 1.0, 0.3) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func close() -> void:
	_visible = false
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 0.0, 0.25) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		visible = false
		closed.emit())


func _process(delta: float) -> void:
	if not _visible:
		return
	_t += delta
	# Animate sliders with a subtle pulse
	for i in _sliders.size():
		var s: Dictionary = _sliders[i]
		var phase := _t * 3.0 + float(i) * 1.5
		var pulse := 1.0 + sin(phase) * 0.02
		s["slider"].scale = Vector2(pulse, pulse)


func _unhandled_input(event: InputEvent) -> void:
	if not _visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
