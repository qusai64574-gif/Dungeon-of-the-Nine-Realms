class_name CameraRig
extends Camera2D
## Smooth follow + screen shake + subtle look-ahead toward the cursor.

var target: Node2D = null
var shake_enabled: bool = true
var _shake := 0.0
var _shake_vec := Vector2.ZERO
var _look := Vector2.ZERO
var _base_zoom := Vector2(2.4, 2.4)

const SMOOTH := 8.0
const LOOK_AHEAD := 0.18
const MAX_LOOK := 44.0


func _ready() -> void:
	zoom = _base_zoom
	position_smoothing_enabled = false
	ignore_rotation = true


func set_target(t: Node2D) -> void:
	target = t
	if t:
		global_position = t.global_position


func kick(amount: float, dir: Vector2 = Vector2.ZERO) -> void:
	if not shake_enabled:
		return
	_shake = maxf(_shake, amount)
	_shake_vec = dir.normalized() if dir != Vector2.ZERO else Vector2.RIGHT.rotated(randf() * TAU)


func set_zoom_level(z: float) -> void:
	_base_zoom = Vector2(z, z)


func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	var goal := target.global_position

	# look-ahead toward the mouse so you can see what you're walking into
	var vp := get_viewport_rect().size * 0.5
	var mouse := get_viewport().get_mouse_position()
	var off := (mouse - vp) * LOOK_AHEAD
	if off.length() > MAX_LOOK:
		off = off.normalized() * MAX_LOOK
	_look = _look.lerp(off, clampf(delta * 3.0, 0.0, 1.0))
	goal += _look

	var t := clampf(delta * SMOOTH, 0.0, 1.0)
	global_position = global_position.lerp(goal, t)

	if _shake > 0.01:
		_shake = lerpf(_shake, 0.0, clampf(delta * 9.0, 0.0, 1.0))
		offset = _shake_vec * _shake * 2.2
	else:
		_shake = 0.0
		offset = offset.lerp(Vector2.ZERO, clampf(delta * 10.0, 0.0, 1.0))

	zoom = zoom.lerp(_base_zoom, clampf(delta * 4.0, 0.0, 1.0))
