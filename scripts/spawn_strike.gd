class_name SpawnStrike
extends Node2D
## "Struck by lightning": a bolt slams down from the sky onto the player, a
## shockwave ring expands, sparks fly, and the player drops in and lands.
##
## Runs in three beats so it reads as an impact rather than a fade-in:
##   1. strike   — bolt drawn downward, hard white flash, screen kick
##   2. impact   — ring + sparks + brief white-out on the player
##   3. recover  — player lands with a small squash, dust settles

var target: Node2D = null
var accent: Color = Color(1.0, 0.95, 0.72)

var _t: float = 0.0
var _phase := 0
var _bolt: Array[Vector2] = []
var _ring_r := 0.0
var _flash := 0.0
var _sparks: Array = []          # [pos, vel, life, max_life, size]
var _drop_from := 120.0
var _landed := false
var _cam: Node = null

const T_STRIKE := 0.16
const T_IMPACT := 0.42
const T_TOTAL := 0.95


func _ready() -> void:
	z_index = 40
	# build a jagged bolt from above the player down to their feet
	var top := Vector2(0, -_drop_from - 70.0)
	var bottom := Vector2.ZERO
	var steps := 9
	_bolt.append(top)
	for i in range(1, steps):
		var f := float(i) / float(steps)
		var p := top.lerp(bottom, f)
		p.x += randf_range(-7.0, 7.0)
		_bolt.append(p)
	_bolt.append(bottom)


func set_target(t: Node2D, cam: Node = null) -> void:
	target = t
	_cam = cam
	if target:
		global_position = target.global_position
		# hold the player above, invisible, until the bolt lands
		target.modulate.a = 0.0
		target.position.y -= _drop_from


func _process(delta: float) -> void:
	_t += delta

	# --- beat 1: the bolt descends and the flash builds -------------------
	if _phase == 0:
		if _t >= T_STRIKE:
			_phase = 1
			_impact()
		queue_redraw()
		return

	# --- beat 2: impact -> shockwave + sparks ----------------------------
	if _phase == 1:
		_ring_r += delta * 620.0
		_flash = maxf(0.0, _flash - delta * 3.4)
		if target and not _landed:
			# ease the player down and land them
			var f := clampf((_t - T_STRIKE) / 0.20, 0.0, 1.0)
			var ease_f := 1.0 - pow(1.0 - f, 3.0)      # cubic ease-out = fast fall
			target.position.y = global_position.y - _drop_from * (1.0 - ease_f)
			target.modulate.a = clampf(f * 2.2, 0.0, 1.0)
			if f >= 1.0:
				_landed = true
				target.position.y = global_position.y
				target.modulate.a = 1.0
				_squash()
		if _t >= T_IMPACT:
			_phase = 2
		_update_sparks(delta)
		queue_redraw()
		return

	# --- beat 3: settle ---------------------------------------------------
	if _t >= T_TOTAL:
		if target and is_instance_valid(target):
			target.modulate = Color(1, 1, 1, 1)
		queue_free()
		return
	_update_sparks(delta)
	_flash = maxf(0.0, _flash - delta * 2.0)
	queue_redraw()


func _impact() -> void:
	_flash = 1.0
	if _cam and _cam.has_method("kick"):
		_cam.kick(9.0, Vector2.DOWN)
	# shockwave sparks
	for _i in 26:
		var a := randf() * TAU
		_sparks.append([
			Vector2.ZERO,
			Vector2.RIGHT.rotated(a) * randf_range(90.0, 300.0),
			randf_range(0.35, 0.75), 0.75,
			randf_range(1.5, 4.0),
		])
	# a few embers shooting up
	for _i in 12:
		_sparks.append([
			Vector2(randf_range(-10, 10), 0),
			Vector2(randf_range(-70, 70), randf_range(-260, -120)),
			randf_range(0.4, 0.9), 0.9,
			randf_range(1.5, 3.5),
		])


func _squash() -> void:
	if target == null or not is_instance_valid(target):
		return
	var spr = target.get("sprite")
	if spr == null:
		return
	var base: Vector2 = spr.scale
	var tw := target.create_tween()
	tw.tween_property(spr, "scale", Vector2(base.x * 1.28, base.y * 0.72), 0.07)
	tw.tween_property(spr, "scale", Vector2(base.x * 0.94, base.y * 1.06), 0.10) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(spr, "scale", base, 0.12)


func _update_sparks(delta: float) -> void:
	for i in range(_sparks.size() - 1, -1, -1):
		var s = _sparks[i]
		s[2] -= delta
		if s[2] <= 0.0:
			_sparks.remove_at(i)
			continue
		s[1].y += 900.0 * delta
		s[1] *= 0.94
		s[0] += s[1] * delta


func _draw() -> void:
	# --- the bolt itself, only during beat 1 ------------------------------
	if _phase == 0:
		var f := clampf(_t / T_STRIKE, 0.0, 1.0)
		var reveal := 1.0 - pow(1.0 - f, 2.0)
		# outer glow
		for i in range(_bolt.size() - 1):
			var a := _bolt[i]
			var b := _bolt[i + 1]
			var bb := a.lerp(b, reveal)
			draw_line(a, bb, Color(accent.r, accent.g, accent.b, 0.30), 11.0)
		# core
		for i in range(_bolt.size() - 1):
			var a := _bolt[i]
			var b := _bolt[i + 1]
			var bb := a.lerp(b, reveal)
			draw_line(a, bb, Color(1, 1, 1, 0.95), 3.4)
		# impact bloom
		if reveal > 0.75:
			var r := (reveal - 0.75) / 0.25
			draw_circle(Vector2.ZERO, 26.0 * r, Color(1, 1, 1, 0.55 * r))

	# --- shockwave ring ---------------------------------------------------
	if _phase >= 1:
		var a := clampf(1.0 - (_ring_r / 300.0), 0.0, 1.0)
		if a > 0.0:
			draw_arc(Vector2.ZERO, _ring_r, 0, TAU, 48,
				Color(accent.r, accent.g, accent.b, a * 0.85), 3.0)
			draw_arc(Vector2.ZERO, _ring_r * 0.72, 0, TAU, 40,
				Color(1, 1, 1, a * 0.4), 1.6)

	# --- white flash ------------------------------------------------------
	if _flash > 0.0:
		draw_circle(Vector2.ZERO, 40.0 * _flash, Color(1, 1, 1, _flash * 0.7))

	# --- sparks -----------------------------------------------------------
	for s in _sparks:
		var t: float = clampf(float(s[2]) / float(s[3]), 0.0, 1.0)
		var c := Color(accent.r, accent.g, accent.b, t)
		var sz: float = float(s[4])
		draw_rect(Rect2(Vector2(s[0]) - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), c, true)
