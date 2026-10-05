class_name Player
extends Actor
## The hero. Walks the grid, swings steel, throws fire.

const SHEET := "knight/knight"

signal attacked(kind: String, origin: Vector2, dir: Vector2, damage: int)

@onready var sprite: AnimSprite = $Sprite
@onready var shadow: Sprite2D = $Shadow

var _anim := "idle_down"
var _attack_cd := 0.0
var _ranged_cd := 0.0
var _invuln := 0.0
var _flash := 0.0
var _swing_timer := 0.0
var _walk_phase := 0.0

const MELEE_RANGE := 30.0
const MELEE_ARC := 1.5      # radians half-width
const RANGED_CD := 0.55


func _ready() -> void:
	radius = 5.0
	if sprite:
		sprite.set_sheet_key(SHEET)
		sprite.setup(SHEET)
		sprite.play("idle_down", true)
	_apply_visual()


func _apply_visual() -> void:
	# Size the knight to ~26px tall (1.6 tiles) rather than by raw sheet
	# dimensions, and anchor the FEET on the collision point.
	var target_px := 26.0
	var sc := scale_for_height(SHEET, target_px)
	if sprite:
		sprite.scale = Vector2(sc, sc)
		sprite.offset = _ground_offset(SHEET, sc)
		sprite.z_index = 5
	if shadow:
		shadow.z_index = 1
		shadow.scale = Vector2(0.55, 0.26)


## Y offset that puts a sprite's bottom edge at the actor's feet.
func _ground_offset(sheet_key: String, sc: float) -> Vector2:
	var a := Assets.char_anim(sheet_key, "idle_down")
	var sh := float(a.get("sh", 16))
	var h := sh * sc
	return Vector2(0, -h * 0.5 + h * 0.10)


## Scale a sheet so the character stands `target_px` tall on screen.
## Sized in pixels rather than by the raw sheet dimensions, so a 16x28 knight
## and a 32x36 ogre both end up a sane size relative to a 16px tile.
static func scale_for_height(sheet_key: String, target_px: float) -> float:
	var a := Assets.char_anim(sheet_key, "idle_down")
	if a.is_empty():
		a = Assets.char_anim(sheet_key, "idle")
	var sh := float(a.get("sh", 16))
	return target_px / maxf(1.0, sh)


func _process(delta: float) -> void:
	if is_dead:
		return
	_attack_cd = maxf(0.0, _attack_cd - delta)
	_ranged_cd = maxf(0.0, _ranged_cd - delta)
	_invuln = maxf(0.0, _invuln - delta)
	_swing_timer = maxf(0.0, _swing_timer - delta)
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 4.0)
		_apply_flash()

	var input := _read_input()
	if input != Vector2.ZERO:
		facing = input.normalized()
	var speed := GameState.stat_move_speed
	move_resolved(input * speed * delta)
	_animate(input, delta)

	if Input.is_action_just_pressed("attack") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_try_melee()
	if Input.is_action_just_pressed("ranged") or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_try_ranged()

	GameState.turns += 1 if input != Vector2.ZERO else 0


func _read_input() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_action_pressed("move_left"): v.x -= 1.0
	if Input.is_action_pressed("move_right"): v.x += 1.0
	if Input.is_action_pressed("move_up"): v.y -= 1.0
	if Input.is_action_pressed("move_down"): v.y += 1.0
	return v.normalized()


func _animate(input: Vector2, delta: float) -> void:
	if _swing_timer > 0.0:
		return
	var d := dir_from_vec(facing if input == Vector2.ZERO else input)
	if input == Vector2.ZERO:
		_play("idle_" + d)
	else:
		_play("run_" + d)


func _play(a: String) -> void:
	if a == _anim:
		return
	_anim = a
	if sprite:
		sprite.play(a)


func _try_melee() -> void:
	if _attack_cd > 0.0:
		return
	_attack_cd = GameState.stat_attack_speed
	_swing_timer = 0.18
	var d := dir_from_vec(facing)
	if sprite:
		sprite.play("fight_" + d, true)
	attacked.emit("melee", global_position, facing, GameState.stat_damage)


func _try_ranged() -> void:
	if _ranged_cd > 0.0:
		return
	_ranged_cd = RANGED_CD
	var d := dir_from_vec(facing)
	if sprite:
		sprite.play("fight_" + d, true)
	_swing_timer = 0.14
	attacked.emit("ranged", global_position, facing, maxi(4, int(GameState.stat_damage * 0.7)))


# --- Damage ----------------------------------------------------------------
func hurt(amount: int, from: Vector2) -> void:
	if is_dead or _invuln > 0.0:
		return
	if GameState.god_mode:
		EventBus.damage_number.emit(global_position + Vector2(0, -20), 0, 2)
		return
	GameState.take_damage(amount, global_position)
	_invuln = 0.55
	_flash = 1.0
	_apply_flash()
	_shake(from)


func _apply_flash() -> void:
	if not sprite:
		return
	var t := _flash
	sprite.modulate = Color(1.0, 1.0 - 0.7 * t, 1.0 - 0.7 * t, 1.0)


func _shake(from: Vector2) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("kick"):
		cam.kick(3.0, (global_position - from).normalized())


func play_death() -> void:
	is_dead = true
	if sprite:
		sprite.play("die_" + dir_from_vec(facing), true)
	set_process(false)


func set_visible_state(v: bool) -> void:
	visible = v
