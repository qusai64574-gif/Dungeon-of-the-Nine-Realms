class_name JumpScare
extends Node2D
## A full-screen jump scare that slams onto the screen.
## Shows a scary face/image with violent shaking, loud flash, and a scream-like
## sound effect. Used randomly during gameplay for horror moments.

var _face: TextureRect
var _flash: ColorRect
var _vignette: TextureRect
var _t: float = 0.0
var _duration: float = 0.8
var _shaking := false
var _on_done: Callable = Callable()

# Scary faces - using available sprites
const SCARY_FACES := [
	"res://assets/dungeon_pack/character/monster/zombie/zombie.png",
	"res://assets/dungeon_pack/character/monster/big_zombie/big_zombie.png",
	"res://assets/dungeon_pack/character/monster/big_daemon/big_daemon.png",
	"res://assets/dungeon_pack/character/monster/imp/imp.png",
]


func _ready() -> void:
	z_index = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func trigger(duration: float = 0.8, on_done: Callable = Callable()) -> void:
	_duration = duration
	_on_done = on_done
	_t = 0.0
	_shaking = true
	visible = true
	_build()


func _build() -> void:
	# dark background
	var bg := ColorRect.new()
	bg.name = "BG"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.95)
	add_child(bg)

	# scary face
	_face = TextureRect.new()
	_face.name = "Face"
	var tex_path: String = SCARY_FACES[randi() % SCARY_FACES.size()]
	var tex := load(tex_path)
	if tex:
		_face.texture = tex
	_face.set_anchors_preset(Control.PRESET_CENTER)
	_face.custom_minimum_size = Vector2(400, 400)
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_face.modulate = Color(1, 0.3, 0.3, 1)
	add_child(_face)

	# red flash
	_flash = ColorRect.new()
	_flash.name = "Flash"
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(0.8, 0, 0, 0.0)
	add_child(_flash)

	# vignette
	_vignette = TextureRect.new()
	_vignette.name = "Vignette"
	_vignette.texture = _vignette_tex()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vignette.modulate = Color(0, 0, 0, 0.8)
	add_child(_vignette)


func _vignette_tex() -> Texture2D:
	var s := 128
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	var c := Vector2(s * 0.5, s * 0.5)
	var maxd := c.length()
	for y in s:
		for x in s:
			var d := Vector2(x - c.x, y - c.y).length() / maxd
			var a := clampf(pow(d, 1.5) * 1.5, 0.0, 1.0)
			img.set_pixel(x, y, Color(0, 0, 0, a))
	return ImageTexture.create_from_image(img)


func _process(delta: float) -> void:
	if not _shaking:
		return
	_t += delta

	# violent shaking
	var amp := 15.0 * (1.0 - _t / _duration)
	_face.position = Vector2(randf_range(-amp, amp), randf_range(-amp, amp))
	_face.rotation = randf_range(-0.1, 0.1)

	# red flash pulsing
	_flash.color = Color(0.8, 0, 0, 0.3 + 0.3 * sin(_t * 30.0))

	# scale pulsing
	var sc := 1.0 + 0.2 * sin(_t * 20.0)
	_face.scale = Vector2(sc, sc)

	if _t >= _duration:
		_shaking = false
		visible = false
		if _on_done.is_valid():
			_on_done.call()
		queue_free()
