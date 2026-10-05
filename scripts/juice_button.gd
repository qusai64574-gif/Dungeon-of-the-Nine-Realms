class_name JuiceButton
extends Button
## A button that reacts. Hovering makes it grow, fires sparks from its edges,
## and sweeps a bright band across it. Clicking punches it down.

signal juiced_pressed

var accent: Color = DarkStyle.INK
var hover_scale: float = 1.075
var punch_scale: float = 0.94

var _particles: UIParticles
var _clip: Control
var _sweep: TextureRect
var _glow: ColorRect
var _tween: Tween
var _sweep_tween: Tween
var _hovering := false
var _ready_done := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = false
	_ready_done = true

	# accent styling: the button must LOOK different per accent, not just spark
	_apply_accent()

	_particles = UIParticles.new()
	_particles.name = "UIParticles"
	_particles.set_anchors_preset(Control.PRESET_FULL_RECT)
	# let sparks escape the button bounds
	_particles.offset_left = -40
	_particles.offset_right = 40
	_particles.offset_top = -30
	_particles.offset_bottom = 30
	add_child(_particles)

	# bright sweep band, drawn over the face (a light pass, not a cover).
	# Clipped to the button so the sheen never bleeds onto the panel.
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

	# soft accent glow behind the text
	_glow = ColorRect.new()
	_glow.name = "Glow"
	_glow.color = Color(accent.r, accent.g, accent.b, 0.0)
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_glow.visible = false
	_clip.add_child(_glow)
	_clip.move_child(_glow, 0)

	pivot_offset = size * 0.5
	mouse_entered.connect(_on_enter)
	mouse_exited.connect(_on_exit)
	resized.connect(_sync_geometry)
	_sync_geometry()


## Give the button its own accent-tinted text, border and hover states.
func _apply_accent() -> void:
	add_theme_color_override("font_color", accent.lightened(0.15))
	add_theme_color_override("font_hover_color", accent.lightened(0.55))
	add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	add_theme_color_override("font_focus_color", accent.lightened(0.55))
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	add_theme_constant_override("outline_size", 3)

	var normal := DarkStyle.button_normal()
	normal.border_color = accent.darkened(0.45)
	add_theme_stylebox_override("normal", normal)

	var hover := DarkStyle.button_hover()
	hover.border_color = accent
	hover.bg_color = accent.darkened(0.72)
	add_theme_stylebox_override("hover", hover)

	var pressed := DarkStyle.button_pressed()
	pressed.border_color = accent.lightened(0.3)
	pressed.bg_color = accent.darkened(0.55)
	add_theme_stylebox_override("pressed", pressed)
	add_theme_stylebox_override("focus", hover)

	var dis := DarkStyle.block(Color(0, 0, 0, 0.35), 1, 4, DarkStyle.OUTLINE)
	dis.content_margin_left = 14
	dis.content_margin_right = 14
	dis.content_margin_top = 9
	dis.content_margin_bottom = 9
	add_theme_stylebox_override("disabled", dis)
	add_theme_color_override("font_disabled_color", Color("#5a3038"))


func _sync_geometry() -> void:
	if not _ready_done:
		return
	pivot_offset = size * 0.5
	if _sweep:
		_sweep.size = Vector2(56, size.y + 40)


## Soft vertical sheen: transparent -> white -> transparent, so the sweep reads
## as a light pass instead of a hard rectangle.
func _sheen_texture() -> Texture2D:
	var w := 16
	var h := 4
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for x in w:
		var f := float(x) / float(w - 1)
		var a := sin(f * PI)            # 0 at edges, 1 in the middle
		a = pow(a, 1.7)
		for y in h:
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


func _on_enter() -> void:
	_hovering = true
	_animate_to(hover_scale, 0.13)
	# sparks fly in from both edges
	if _particles:
		_particles.burst(10, accent, 150.0, Vector2(0, size.y * 0.5), 2.0)
		_particles.burst(10, accent.lightened(0.35), 150.0, Vector2(size.x, size.y * 0.5), 2.0)
	_sweep_band()


func _on_exit() -> void:
	_hovering = false
	_animate_to(1.0, 0.16)
	if _sweep_tween:
		_sweep_tween.kill()
	var tw := create_tween()
	tw.tween_property(_sweep, "modulate:a", 0.0, 0.14)
	tw.parallel().tween_property(_glow, "color:a", 0.0, 0.16)
	tw.chain().tween_callback(func():
		_sweep.visible = false
		_glow.visible = false)


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


func _pressed() -> void:
	# punch down then spring back
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2(punch_scale, punch_scale), 0.06)
	_tween.tween_property(self, "scale", Vector2(hover_scale, hover_scale), 0.16) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _particles:
		_particles.burst(18, accent, 210.0, size * 0.5, 0.0)
		_particles.ring(accent.lightened(0.4), size * 0.5, minf(size.x, size.y) * 0.45, 14)
	juiced_pressed.emit()
