class_name MainMenu
extends CanvasLayer
## Main menu — dark red bleeding buttons, upside-down bleeding sword.

signal start_new_run
signal continue_run
signal quit_game
signal give_up
signal open_settings
signal open_bestiary

var _root: Control
var _t: float = 0.0
var _state := "initializing"
var _entrance_done := false
var _exiting := false
var _buttons: Dictionary = {}
var _btn_order: Array[String] = ["Btn_NewGame", "Btn_Continue", "Btn_Settings", "Btn_Binary", "Btn_GiveUp"]
var _btn_base_pos: Dictionary = {}
var _sword: BloodySwordLogo


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
	_root.size = Vector2(1280, 720)
	add_child(_root)

	# Background
	var bg := TextureRect.new()
	bg.texture = _menu_background_texture()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_root.add_child(bg)

	# Upside-down bleeding sword in the center
	_sword = BloodySwordLogo.new()
	_sword.name = "Sword"
	_sword.custom_minimum_size = Vector2(200, 200)
	_sword.position = Vector2(540, 80)
	_sword.rotation = PI
	_root.add_child(_sword)

	# Buttons on the left
	var labels := {
		"Btn_NewGame": "NEW GAME",
		"Btn_Continue": "CONTINUE",
		"Btn_Settings": "SETTINGS",
		"Btn_Binary": "BESTIARY",
		"Btn_GiveUp": "GIVE UP",
	}

	var btn_y := 180.0
	for btn_name in _btn_order:
		var btn := _create_bleeding_button(labels[btn_name])
		btn.name = btn_name
		btn.position = Vector2(80, btn_y)
		_root.add_child(btn)
		_buttons[btn_name] = btn
		_btn_base_pos[btn_name] = btn.position
		btn_y += 90.0

	# Stats footer
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

	_refresh()


func _handle_click(screen_pos: Vector2) -> void:
	for btn_name in _btn_order:
		var btn: Control = _buttons.get(btn_name)
		if btn and btn.visible:
			var rect := Rect2(btn.position, btn.size)
			if rect.has_point(screen_pos):
				match btn_name:
					"Btn_NewGame":
						start_new_run.emit()
					"Btn_Continue":
						continue_run.emit()
					"Btn_Settings":
						open_settings.emit()
					"Btn_Binary":
						open_bestiary.emit()
					"Btn_GiveUp":
						give_up.emit()
				return


func _play_entrance() -> void:
	_entrance_done = false
	_exiting = false
	_state = "entering"

	for btn_name in _btn_order:
		var btn: Control = _buttons.get(btn_name)
		if btn:
			btn.visible = false

	for i in _btn_order.size():
		var btn_name: String = _btn_order[i]
		var btn: Control = _buttons.get(btn_name)
		if btn:
			var delay := float(i) * 0.12
			var tw := create_tween()
			tw.tween_interval(delay)
			tw.tween_callback(func(): btn.visible = true)
			tw.tween_property(btn, "position", _btn_base_pos[btn_name], 0.6) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	var t_done := create_tween()
	t_done.tween_interval(0.12 * _btn_order.size() + 0.6)
	t_done.tween_callback(func():
		_entrance_done = true
		_state = "idle")


func _play_exit() -> void:
	if _exiting:
		return
	_exiting = true
	_state = "exiting"

	for i in range(_btn_order.size() - 1, -1, -1):
		var btn_name: String = _btn_order[i]
		var btn: Control = _buttons.get(btn_name)
		if btn:
			var delay := float(_btn_order.size() - 1 - i) * 0.05
			var tw := create_tween()
			tw.tween_interval(delay)
			tw.tween_callback(func(): btn.visible = false)


func _process(delta: float) -> void:
	_t += delta
	if _state == "idle":
		for i in _btn_order.size():
			var btn_name: String = _btn_order[i]
			var btn: Control = _buttons.get(btn_name)
			if btn:
				var phase := _t * TAU / 4.0 + float(i) * -1.2
				btn.position.y = _btn_base_pos[btn_name].y + sin(phase) * 4.0
				btn.rotation = sin(phase) * 0.03
		if _sword:
			var phase := _t * TAU / 4.0
			_sword.position.y = 80.0 + sin(phase) * 4.0
			_sword.rotation = PI + sin(phase) * 0.03


func _create_bleeding_button(label: String) -> Control:
	var btn := BleedingButton.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(380, 70)
	btn.size = Vector2(380, 70)

	btn.pressed.connect(func():
		if btn.name == "Btn_NewGame":
			start_new_run.emit()
		elif btn.name == "Btn_Continue":
			continue_run.emit()
		elif btn.name == "Btn_Settings":
			open_settings.emit()
		elif btn.name == "Btn_Binary":
			open_bestiary.emit()
		elif btn.name == "Btn_GiveUp":
			give_up.emit()
	)

	return btn


func _menu_background_texture() -> Texture2D:
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


func _refresh() -> void:
	var foot: Label = _root.find_child("Foot", true, false)
	if foot:
		var sm := get_node_or_null("/root/SaveManager")
		if sm:
			foot.text = "Best depth %d     %d kills     %d runs" % [
				sm.best_depth, sm.total_kills, sm.total_runs]


func refresh() -> void:
	_refresh()
