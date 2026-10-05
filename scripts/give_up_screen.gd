class_name GiveUpScreen
extends CanvasLayer
## The quit confirmation, played as a horror beat.
## Randomized threatening messages, violent fear shaking on ALL letters,
## blood red slam, crack lines, heartbeat, and bleeding text.

signal confirmed_quit
signal cancelled

var is_open: bool = false

var _root: Control
var _red: ColorRect
var _dark: ColorRect
var _vignette: TextureRect
var _cracks: Control
var _heart: ColorRect
var _big: BleedingLabel
var _sub: BloodText
var _row: HBoxContainer
var _yes: BloodButton
var _no: BloodButton
var _flash: ColorRect
var _shake_targets: Array[Control] = []
var _t: float = 0.0
var _beat: float = 0.0
var _crack_lines: Array = []

# Randomized threatening messages
const THREATENING_MESSAGES := [
	"ARE YOU SURE YOU WANT TO QUIT\nAND GIVE UP?",
	"YOU CAN'T LEAVE\nTHE DUNGEON REMEMBERS YOU",
	"GIVE UP AND JOIN\nTHE WALLS?",
	"THE DUNGEON IS HUNGRY\nARE YOU SURE?",
	"YOUR SOUL BELONGS\nTO THE NINE REALMS",
	"THERE IS NO ESCAPE\nONLY SUFFERING",
	"THE CHESTS ARE EMPTY\nLIKE YOUR FUTURE",
	"EVERY STEP FORWARD\nIS A STEP DEEPER",
	"THE DARKNESS IS WAITING\nARE YOU SURE YOU WANT TO QUIT?",
	"GIVE UP AND BECOME\nONE OF THEM?",
	"THE MONSTERS ARE HUNGRY\nDON'T GO YET",
	"YOU'LL NEVER ESCAPE\nTHE NINE REALMS",
	"THE BLOOD ON YOUR HANDS\nWILL NEVER WASH OFF",
	"QUIT NOW AND FOREVER\nWONDER WHAT WAS DOWN THERE",
	"THE DUNGEON GROWS STRONGER\nWITH EVERY SOUL IT TAKES",
]


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false


func open() -> void:
	is_open = true
	visible = true
	_pick_random_message()
	_play_intro()


func close() -> void:
	is_open = false
	visible = false


func _pick_random_message() -> void:
	var msg: String = THREATENING_MESSAGES[randi() % THREATENING_MESSAGES.size()]
	_big.text = msg


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed("ui_cancel"):
		_on_no()
		get_viewport().set_input_as_handled()


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

	_vignette = TextureRect.new()
	_vignette.texture = _vignette_tex()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vignette.modulate = Color(0, 0, 0, 0.0)
	_root.add_child(_vignette)

	_dark = ColorRect.new()
	_dark.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dark.color = Color(0.02, 0.0, 0.0, 0.0)
	_root.add_child(_dark)

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

	_big = BleedingLabel.new()
	_big.text = "ARE YOU SURE YOU WANT TO QUIT\nAND GIVE UP?"
	_big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_big.add_theme_font_override("font", DarkStyle.font_display())
	_big.add_theme_font_size_override("font_size", 62)
	_big.add_theme_color_override("font_color", Color("#e0141c"))
	_big.add_theme_color_override("font_outline_color", Color("#2a0306"))
	_big.add_theme_constant_override("outline_size", 14)
	_big.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_big.add_theme_constant_override("shadow_offset_x", 3)
	_big.add_theme_constant_override("shadow_offset_y", 5)
	_big.set_blood_colour(Color("#e0141c"))
	_big.set_streak_colour(Color("#7a0a10"))
	_big.set_drip_density(2.0)
	col.add_child(_big)
	_shake_targets.append(_big)

	_sub = BloodText.new()
	_sub.message = "every action has consequences"
	_sub.font_size = 26
	_sub.colour = Color("#c8161e")
	_sub.streak_colour = Color("#7d0a10")
	_sub.letter_spacing = 2.5
	var sub_wrap := CenterContainer.new()
	sub_wrap.add_child(_sub)
	col.add_child(sub_wrap)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 26)
	col.add_child(spacer)

	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 34)
	col.add_child(_row)

	_yes = BloodButton.new()
	_yes.set_label("GIVE UP")
	_yes.set_accent(Color("#e0141c"))
	_yes.custom_minimum_size = Vector2(260, 62)
	_yes.pressed.connect(_on_yes)
	_row.add_child(_yes)
	_shake_targets.append(_yes)

	_no = BloodButton.new()
	_no.set_label("KEEP SUFFERING")
	_no.set_accent(DarkStyle.ACCENTS["go"])
	_no.custom_minimum_size = Vector2(300, 62)
	_no.pressed.connect(_on_no)
	_row.add_child(_no)

	# Bleeding pixelated skull on KEEP SUFFERING button
	var skull := BleedingSkull.new()
	skull.custom_minimum_size = Vector2(40, 40)
	skull.size = Vector2(40, 40)
	skull.position = Vector2(10, 11)
	_no.add_child(skull)

	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(1, 1, 1, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_flash)


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


func _on_yes() -> void:
	var tw := create_tween()
	tw.tween_property(_flash, "color", Color(1, 0.9, 0.9, 1.0), 0.10)
	tw.tween_property(_flash, "color:a", 0.0, 0.30)
	confirmed_quit.emit()


func _on_no() -> void:
	cancelled.emit()
	close()


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

	# VIOLENT fear shaking on ALL letters - much more intense
	var amp := 4.0 + thump * 6.0
	_big.position = Vector2(randf_range(-amp, amp), randf_range(-amp, amp))
	_yes.position = Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))

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
