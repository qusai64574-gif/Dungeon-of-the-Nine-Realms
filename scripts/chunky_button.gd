class_name ChunkyButton
extends Button
## A chunky "toy block" menu button.
##
## Idle it bobs and rocks gently so the stack never looks frozen. On hover it
## lifts, tilts toward the viewer, and brightens. On press the hard shadow
## collapses and the block shifts down onto it — a physical press.
##
## Built as: [Shadow] [Face] [Label]. The Face is a separate Panel so its own
## stylebox can hold the hard shadow while the Button's is empty.

var accent: Color = DarkStyle.INK
var base_rotation: float = 0.0
var tilt_amount: float = 0.045          # radians of hover rock
var lift: float = 7.0                   # px the block rises on hover

var _shadow: Panel
var _face: Panel
var _label: Label
var _tilt_pivot: Control

var _bob_t: float = 0.0
var _bob_amp: float = 2.2
var _hovering := false
var _tween: Tween
var _base_pos := Vector2.ZERO
var _ready_done := false
var _pressed_offset := 0.0


func _ready() -> void:
	_ready_done = true
	custom_minimum_size = Vector2(0, 54)
	flat = true
	clip_contents = false

	# everything lives inside a pivot node so rotation pivots on the centre
	_tilt_pivot = Control.new()
	_tilt_pivot.name = "TiltPivot"
	_tilt_pivot.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tilt_pivot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tilt_pivot.pivot_offset = size * 0.5
	add_child(_tilt_pivot)

	# hard drop shadow (an offset block behind the face)
	_shadow = Panel.new()
	_shadow.name = "Shadow"
	_shadow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := StyleBoxFlat.new()
	sh.bg_color = DarkStyle.SHADOW
	sh.set_corner_radius_all(5)
	_shadow.add_theme_stylebox_override("panel", sh)
	_tilt_pivot.add_child(_shadow)

	# the face
	_face = Panel.new()
	_face.name = "Face"
	_face.set_anchors_preset(Control.PRESET_FULL_RECT)
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_face(DarkStyle.PANEL_HI)
	_tilt_pivot.add_child(_face)

	# the label sits on top, centred, with a chunky outlined display face
	_label = Label.new()
	_label.name = "FaceLabel"
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.text = text
	_style_label(_label, accent)
	_tilt_pivot.add_child(_label)

	rotation = base_rotation
	_tilt_pivot.rotation = base_rotation
	mouse_entered.connect(_on_enter)
	mouse_exited.connect(_on_exit)
	button_down.connect(_on_down)
	button_up.connect(_on_up)
	resized.connect(_sync)
	_sync()
	_base_pos = position


func _sync() -> void:
	if not _ready_done:
		return
	_tilt_pivot.pivot_offset = size * 0.5
	_shadow.position = DarkStyle.SHADOW_OFF
	_shadow.size = size
	_face.size = size
	_label.size = size


func _apply_face(face: Color) -> void:
	var sb := DarkStyle.block(face, 5)
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	_face.add_theme_stylebox_override("panel", sb)


func _style_label(lbl: Label, col: Color) -> void:
	lbl.add_theme_font_override("font", DarkStyle.font_display())
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_color_override("font_outline_color", DarkStyle.CREAM)
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 2)


func set_label(t: String) -> void:
	text = t
	if _label:
		_label.text = t


func _process(delta: float) -> void:
	if not _ready_done:
		return
	_bob_t += delta
	# gentle idle bob; hovered blocks settle so the lift reads clearly
	var amp := _bob_amp * (0.25 if _hovering else 1.0)
	_shadow.position.y = DarkStyle.SHADOW_OFF.y + sin(_bob_t * 1.7 + position.y * 0.01) * amp
	_face.position.y = _shadow.position.y - DarkStyle.SHADOW_OFF.y
	# idle rock, reduced while hovered
	var rock := sin(_bob_t * 0.9 + position.x * 0.02) * 0.006
	_tilt_pivot.rotation = base_rotation + rock


func _on_enter() -> void:
	_hovering = true
	_animate(1.06, 1.0, -tilt_amount, DarkStyle.PANEL_HI, 0.16)
	_apply_face(DarkStyle.PANEL_HI)
	_style_label(_label, accent.lightened(0.18))


func _on_exit() -> void:
	_hovering = false
	_animate(1.0, 0.0, 0.0, DarkStyle.PANEL_HI, 0.20)
	_apply_face(DarkStyle.PANEL_HI)
	_style_label(_label, accent)


func _on_down() -> void:
	# collapse the shadow: the block drops onto its own shadow
	_apply_face(DarkStyle.PANEL)
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_shadow, "position:y", 1.0, 0.06)
	_tween.tween_property(_face, "position:y", 1.0, 0.06)
	_tween.tween_property(_tilt_pivot, "scale", Vector2(0.985, 0.985), 0.06)


func _on_up() -> void:
	if _hovering:
		_on_enter()
	else:
		_on_exit()


func _animate(scale_to: float, shadow_y: float, tilt: float, face: Color, dur: float) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_tilt_pivot, "scale", Vector2(scale_to, scale_to), dur)
	_tween.tween_property(_tilt_pivot, "rotation", base_rotation + tilt, dur)
	_tween.tween_property(_shadow, "position:y", DarkStyle.SHADOW_OFF.y + shadow_y, dur)
	_tween.tween_property(_face, "position:y", shadow_y, dur)
