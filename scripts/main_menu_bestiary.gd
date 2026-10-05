class_name MainMenuBestiary
extends CanvasLayer
## Main menu bestiary — panel with 3D-style monster cards and scary hover shakes.

signal closed

var _root: Control
var _t: float = 0.0
var _visible := false
var _monster_cards: Array = []


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

	# Main panel
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", DarkStyle.panel())
	panel.custom_minimum_size = Vector2(1100, 620)
	panel.position = Vector2(90, 50)
	_root.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	panel.add_child(vb)

	# Title row
	var title_row := HBoxContainer.new()
	vb.add_child(title_row)

	var title := ShakingLabel.new()
	title.text = "BESTIARY"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_override("font", DarkStyle.font_display())
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color("#c93a3a"))
	title.add_theme_color_override("font_outline_color", Color("#000000"))
	title.add_theme_constant_override("outline_size", 4)
	title.set_shake_amount(2.0)
	title.set_shake_speed(6.0)
	title_row.add_child(title)

	var close_btn := BleedingButton.new()
	close_btn.text = "CLOSE"
	close_btn.custom_minimum_size = Vector2(120, 40)
	close_btn.size = Vector2(120, 40)
	close_btn.pressed.connect(func(): close())
	title_row.add_child(close_btn)

	# Monster grid
	var grid := HBoxContainer.new()
	grid.add_theme_constant_override("separation", 20)
	grid.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(grid)

	var monsters := [
		{"name": "CRAWLER", "color": Color("#4a6741"), "desc": "Fast and numerous"},
		{"name": "BRUTE", "color": Color("#6b4423"), "desc": "Slow but deadly"},
		{"name": "WRAITH", "color": Color("#4a4a6b"), "desc": "Phases through walls"},
		{"name": "SPITTER", "color": Color("#6b6b4a"), "desc": "Ranged attacker"},
		{"name": "BOSS", "color": Color("#8b0000"), "desc": "Depth guardian"},
	]

	for i in monsters.size():
		var m: Dictionary = monsters[i]
		var card := _create_monster_card(m, i)
		grid.add_child(card)
		_monster_cards.append(card)


func _create_monster_card(m: Dictionary, idx: int) -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", DarkStyle.block(DarkStyle.PANEL_HI, 8, 2))
	card.custom_minimum_size = Vector2(190, 480)
	card.size = Vector2(190, 480)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	card.add_child(vb)

	# Monster name
	var name_lbl := ShakingLabel.new()
	name_lbl.text = m["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_override("font", DarkStyle.font_display())
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", m["color"].lightened(0.3))
	name_lbl.add_theme_color_override("font_outline_color", Color("#000000"))
	name_lbl.add_theme_constant_override("outline_size", 2)
	name_lbl.set_shake_amount(1.0)
	name_lbl.set_shake_speed(4.0)
	vb.add_child(name_lbl)

	# Monster visual
	var visual := _MonsterVisual.new()
	visual.color = m["color"]
	visual.custom_minimum_size = Vector2(150, 200)
	visual.size = Vector2(150, 200)
	vb.add_child(visual)

	# Description
	var desc := Label.new()
	desc.text = m["desc"]
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_override("font", DarkStyle.font_display())
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color("#8a6068"))
	desc.add_theme_color_override("font_outline_color", Color("#000000"))
	desc.add_theme_constant_override("outline_size", 1)
	vb.add_child(desc)

	# Hover detection
	card.mouse_entered.connect(func():
		visual.set_hovered(true)
		name_lbl.set_shake_amount(4.0)
		name_lbl.set_shake_speed(15.0))
	card.mouse_exited.connect(func():
		visual.set_hovered(false)
		name_lbl.set_shake_amount(1.0)
		name_lbl.set_shake_speed(4.0))

	card.set_meta("visual", visual)
	card.set_meta("base_pos", card.position)
	card.set_meta("index", idx)

	return card


func open_panel() -> void:
	_visible = true
	visible = true
	_t = 0.0
	for i in _monster_cards.size():
		var card: Control = _monster_cards[i]
		card.modulate.a = 0.0
		card.scale = Vector2(0.5, 0.5)
		var tw := create_tween()
		tw.tween_interval(i * 0.1)
		tw.set_parallel(true)
		tw.tween_property(card, "modulate:a", 1.0, 0.4) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(card, "scale", Vector2.ONE, 0.5) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func close() -> void:
	_visible = false
	for i in _monster_cards.size():
		var card: Control = _monster_cards[i]
		var tw := create_tween()
		tw.tween_interval(i * 0.05)
		tw.set_parallel(true)
		tw.tween_property(card, "modulate:a", 0.0, 0.3) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.tween_property(card, "scale", Vector2(0.8, 0.8), 0.3) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	var tw_done := create_tween()
	tw_done.tween_interval(0.5)
	tw_done.tween_callback(func():
		visible = false
		closed.emit())


func _process(delta: float) -> void:
	if not _visible:
		return
	_t += delta
	for i in _monster_cards.size():
		var card: Control = _monster_cards[i]
		var phase := _t * 2.0 + float(i) * 0.8
		card.rotation = sin(phase * 0.7) * 0.02


func _unhandled_input(event: InputEvent) -> void:
	if not _visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()


class _MonsterVisual:
	extends Control
	var color: Color = Color("#4a6741")
	var _t := 0.0
	var _hovered := false
	var _shake_amount := 0.0

	func set_hovered(v: bool) -> void:
		_hovered = v

	func _process(delta: float) -> void:
		_t += delta
		_shake_amount = lerp(_shake_amount, 8.0 if _hovered else 0.0, 0.2)
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var cx := w * 0.5
		var cy := h * 0.5

		var ox := sin(_t * 30.0) * _shake_amount
		var oy := cos(_t * 25.0) * _shake_amount * 0.5

		var body_w := w * 0.5
		var body_h := h * 0.5
		draw_rect(Rect2(cx - body_w / 2 + ox, cy - body_h / 2 + oy, body_w, body_h), color)

		var eye_y := cy - body_h * 0.2 + oy
		var eye_size := 6.0
		draw_circle(Vector2(cx - 12 + ox, eye_y), eye_size, Color(1, 0, 0))
		draw_circle(Vector2(cx + 12 + ox, eye_y), eye_size, Color(1, 0, 0))
		draw_circle(Vector2(cx - 12 + ox, eye_y), eye_size * 1.5, Color(1, 0, 0, 0.3))
		draw_circle(Vector2(cx + 12 + ox, eye_y), eye_size * 1.5, Color(1, 0, 0, 0.3))

		var mouth_y := cy + body_h * 0.15 + oy
		for i in 5:
			var mx := cx - 15 + i * 7 + ox
			var mh := 4.0 + sin(_t * 10.0 + i) * 3.0
			draw_rect(Rect2(mx, mouth_y, 4, mh), Color(0.8, 0, 0))

		var arm_w := 8.0
		var arm_h := h * 0.3
		draw_rect(Rect2(cx - body_w / 2 - arm_w + ox, cy - arm_h / 2 + oy, arm_w, arm_h), color.darkened(0.2))
		draw_rect(Rect2(cx + body_w / 2 + ox, cy - arm_h / 2 + oy, arm_w, arm_h), color.darkened(0.2))

		var leg_w := 10.0
		var leg_h := h * 0.2
		draw_rect(Rect2(cx - 15 + ox, cy + body_h / 2 + oy, leg_w, leg_h), color.darkened(0.3))
		draw_rect(Rect2(cx + 5 + ox, cy + body_h / 2 + oy, leg_w, leg_h), color.darkened(0.3))
