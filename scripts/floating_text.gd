class_name FloatingText
extends Node2D
## Damage / heal / pickup numbers that rise and fade.

var text: String = ""
var colour: Color = Color.WHITE
var life: float = 0.85
var _max: float = 0.85
var rise: float = 34.0
var _vel: Vector2 = Vector2.ZERO
var font: Font
var size: int = 12
var _outline: bool = true


func setup(txt: String, col: Color, at: Vector2, sz: int = 12, rise_speed: float = 34.0) -> void:
	text = txt
	colour = col
	position = at
	size = sz
	rise = rise_speed
	_vel = Vector2(randf_range(-16, 16), -rise)
	z_index = 30


func _ready() -> void:
	_max = life
	font = load(Assets.FONT_UI)


func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	_vel.y += 46.0 * delta          # slight gravity so it arcs
	position += _vel * delta
	queue_redraw()


func _draw() -> void:
	if font == null:
		return
	var t := clampf(life / _max, 0.0, 1.0)
	# pop in: scale up fast at the start
	var scale_up := 1.0 + 0.35 * clampf((1.0 - t) * 3.0, 0.0, 1.0)
	var col := Color(colour.r, colour.g, colour.b, clampf(t * 1.6, 0.0, 1.0))
	var sz := int(float(size) * scale_up)
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	if _outline:
		for ox in [-1, 0, 1]:
			for oy in [-1, 0, 1]:
				if ox == 0 and oy == 0:
					continue
				draw_string(font, Vector2(-w * 0.5 + ox, oy), text,
					HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color(0, 0, 0, col.a * 0.85))
	draw_string(font, Vector2(-w * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
