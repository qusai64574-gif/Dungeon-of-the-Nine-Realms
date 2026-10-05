class_name PixelButton
extends Button
## HTML reference button style.
## Gradient background, thick border, box shadow, inner border, bottom bar.

var _label: Label
var _t: float = 0.0
var _hovered := false
var _accent: Color = Color("#e0262e")
var _ready_done := false
var _label_text: String = ""
var _base_pos := Vector2.ZERO
var _glow: ColorRect

# HTML reference values
const BORDER_W := 7
const BORDER_RADIUS := 15
const FONT_SIZE := 28

func _init() -> void:
	custom_minimum_size = Vector2(558, 80)

func _ready() -> void:
	_ready_done = true
	_build()
	_base_pos = position

func _build() -> void:
	for c in get_children():
		c.queue_free()

	# Glow behind button
	_glow = ColorRect.new()
	_glow.name = "Glow"
	_glow.color = Color(170/255.0, 10/255.0, 20/255.0, 0.0)
	_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow.position = Vector2(-20, -20)
	_glow.size = Vector2(40, 40)
	add_child(_glow)

	# Button face
	var face := PanelContainer.new()
	face.name = "Face"
	face.set_anchors_preset(Control.PRESET_FULL_RECT)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#2e0d10")
	sb.border_color = Color("#8f1219")
	sb.set_border_width_all(BORDER_W)
	sb.set_corner_radius_all(BORDER_RADIUS)
	sb.shadow_color = Color("#3a0508")
	sb.shadow_offset = Vector2(-7, 11)
	sb.shadow_size = 0
	face.add_theme_stylebox_override("panel", sb)
	add_child(face)

	# Inner border
	var inner := PanelContainer.new()
	inner.name = "Inner"
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.position = Vector2(7, 7)
	inner.size = Vector2(size.x - 14, size.y - 14)

	var isb := StyleBoxFlat.new()
	isb.bg_color = Color("#160607")
	isb.border_color = Color("#661a20")
	isb.set_border_width_all(2)
	isb.set_corner_radius_all(11)
	inner.add_theme_stylebox_override("panel", isb)
	face.add_child(inner)

	# Bottom bar
	var bar := ColorRect.new()
	bar.name = "Bar"
	bar.color = Color("#8f1219")
	bar.color.a = 0.65
	bar.position = Vector2(32, size.y - 12)
	bar.size = Vector2(size.x * 0.44, 3)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.add_child(bar)

	# Label
	_label = Label.new()
	_label.name = "Label"
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_override("font", DarkStyle.font_display())
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_label.add_theme_color_override("font_color", _accent)
	_label.add_theme_color_override("font_outline_color", Color("#0b0203"))
	_label.add_theme_constant_override("outline_size", 2)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.text = _label_text
	add_child(_label)

	mouse_entered.connect(_on_enter)
	mouse_exited.connect(_on_exit)
	button_down.connect(_on_down)
	button_up.connect(_on_up)

func _process(delta: float) -> void:
	_t += delta

func _on_enter() -> void:
	if not _ready_done:
		return
	_hovered = true
	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2(1.035, 1.035), 0.15)
	tw.tween_property(self, "modulate", Color(1.35, 1.35, 1.35), 0.15)
	tw.tween_property(_glow, "color:a", 0.3, 0.15)

func _on_exit() -> void:
	if not _ready_done:
		return
	_hovered = false
	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.15)
	tw.tween_property(self, "modulate", Color(1, 1, 1), 0.15)
	tw.tween_property(_glow, "color:a", 0.0, 0.15)

func _on_down() -> void:
	if not _ready_done:
		return
	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position", _base_pos + Vector2(0, 6), 0.08)
	tw.tween_property(self, "modulate", Color(0.8, 0.8, 0.8), 0.08)

func _on_up() -> void:
	if not _ready_done:
		return
	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position", _base_pos, 0.08)
	if _hovered:
		tw.tween_property(self, "modulate", Color(1.35, 1.35, 1.35), 0.08)
	else:
		tw.tween_property(self, "modulate", Color(1, 1, 1), 0.08)

func set_label(t: String) -> void:
	_label_text = t
	text = t
	if _label:
		_label.text = t

func set_accent(c: Color) -> void:
	_accent = c
	if _label:
		_label.add_theme_color_override("font_color", Color("#e0262e"))
