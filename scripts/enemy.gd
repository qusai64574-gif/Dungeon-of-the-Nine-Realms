class_name Enemy
extends Actor
## A monster. Deliberately slow — it telegraphs, then commits.

signal died(enemy: Enemy)

var id: String = "goblin"
var data: Dictionary = {}
var hp: int = 10
var max_hp: int = 10
var speed: float = 30.0
var damage: int = 5
var xp_reward: int = 5
var gold_reward: int = 3
var behaviour: String = "chase"
var attack_range: float = 24.0
var attack_cd: float = 1.2
var is_boss: bool = false
var boss_title: String = ""

var _cd := 0.0
var _flash := 0.0
var _anim := ""
var _stun := 0.0
var _wander_dir := Vector2.ZERO
var _wander_t := 0.0
var _player: Node2D = null

@onready var sprite: AnimSprite = $Sprite
@onready var shadow: Sprite2D = $Shadow


func setup(type_id: String, depth: int, hp_mult: float = 1.0, dmg_mult: float = 1.0) -> void:
	id = type_id
	data = EnemyDB.stats(type_id, depth, hp_mult, dmg_mult)
	hp = int(data["hp"])
	max_hp = hp
	speed = float(data["speed"])
	damage = int(data["damage"])
	xp_reward = int(data["xp"])
	gold_reward = int(data["gold"])
	behaviour = String(data["behaviour"])
	attack_range = float(data["attack_range"])
	attack_cd = float(data["attack_cd"])
	var target_px: float = float(data.get("size_px", 22))
	if sprite:
		sprite.set_sheet_key(String(data["key"]))
		sprite.setup(String(data["key"]))
		var sc := Player.scale_for_height(String(data["key"]), target_px)
		sprite.scale = Vector2(sc, sc)
		# anchor the feet to the collision point
		var a := Assets.char_anim(String(data["key"]), "idle")
		var sh := float(a.get("sh", 16))
		var h := sh * sc
		sprite.offset = Vector2(0, -h * 0.5 + h * 0.10)
		sprite.modulate = data.get("tint", Color.WHITE)
		sprite.z_index = 4
	if shadow:
		shadow.z_index = 1
		shadow.scale = Vector2(0.45, 0.22)
	radius = float(data.get("radius", 5.0))


func make_boss(title: String, scale_mult: float) -> void:
	is_boss = true
	boss_title = title
	if sprite:
		# bosses read ~40px tall; scale_mult is a per-boss multiplier on that
		var base_px := 40.0 * (scale_mult / 3.2)
		var sc := Player.scale_for_height(String(data["key"]), base_px)
		sprite.scale = Vector2(sc, sc)
		var a := Assets.char_anim(String(data["key"]), "idle")
		var h := float(a.get("sh", 16)) * sc
		sprite.offset = Vector2(0, -h * 0.5 + h * 0.10)
		sprite.z_index = 6
	radius = 8.0


func _ready() -> void:
	_play("idle")


func _play(a: String) -> void:
	if a == _anim or not sprite:
		return
	_anim = a
	sprite.play(a)


## Called by the Level each visibility update. Hides anything the player
## cannot currently see — without this, entities render through walls because
## fog only affects the TILE layer.
func apply_visibility() -> void:
	if is_dead:
		return
	var lvl := get_parent()
	while lvl != null and lvl.get("vis_map") == null:
		lvl = lvl.get_parent()
	if lvl == null:
		return
	var c: Vector2i = DungeonGen.cell_from_pos(global_position, 16)
	var vm: Array = lvl.vis_map
	if c.y < 0 or c.y >= vm.size() or c.x < 0 or c.x >= vm[0].size():
		visible = false
		return
	visible = bool(vm[c.y][c.x])


func _process(delta: float) -> void:
	if is_dead:
		return
	if data.is_empty():
		return
	_cd = maxf(0.0, _cd - delta)
	_stun = maxf(0.0, _stun - delta)
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 4.0)
		if sprite:
			var base: Color = data.get("tint", Color.WHITE)
			sprite.modulate = base.lerp(Color(2.2, 0.7, 0.7), _flash)

	if GameState.freeze_enemies or _stun > 0.0:
		_play("idle")
		return

	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return

	var to_player: Vector2 = _player.global_position - global_position
	var dist := to_player.length()
	var dir := to_player.normalized() if dist > 0.001 else Vector2.ZERO

	# --- movement ---------------------------------------------------------
	var move := Vector2.ZERO
	match behaviour:
		"caster":
			# keep distance, strafe, still very slow
			if dist < 90.0:
				move = -dir
			elif dist > 150.0:
				move = dir
			else:
				move = dir.rotated(PI * 0.5) * 0.6
		"wander":
			_wander_t -= delta
			if _wander_t <= 0.0:
				_wander_t = randf_range(0.8, 1.8)
				_wander_dir = Vector2.RIGHT.rotated(randf() * TAU)
			move = dir * 0.55 + _wander_dir * 0.45
		_:
			move = dir

	# only close in while outside attack range — stops the jitter-shoving
	if dist <= attack_range and behaviour != "caster":
		move = Vector2.ZERO

	var spd := speed * GameState.enemy_speed_mult
	if move != Vector2.ZERO:
		facing = move.normalized()
		move_resolved(move.normalized() * spd * delta)
		_play("run")
	else:
		_play("idle")

	# --- attack -----------------------------------------------------------
	if _cd <= 0.0:
		if behaviour == "caster" and dist <= attack_range:
			_cd = attack_cd
			_fire_at(_player.global_position)
		elif dist <= attack_range + 6.0:
			_cd = attack_cd
			_melee_player()


func _melee_player() -> void:
	if not is_instance_valid(_player):
		return
	if _player.has_method("hurt"):
		_player.hurt(damage, global_position)


func _fire_at(target: Vector2) -> void:
	var proj := preload("res://scripts/projectile.gd").new()
	proj.setup(global_position, (target - global_position).normalized(),
		maxi(3, int(damage * 0.7)), false, 190.0, Color(1.0, 0.45, 0.25))
	get_parent().add_child(proj)


# --- Damage ----------------------------------------------------------------
func hurt(amount: int, from: Vector2 = Vector2.ZERO, knockback: float = 0.0) -> void:
	if is_dead:
		return
	var dmg := amount
	if GameState.one_hit_kill:
		dmg = maxi(dmg, hp)
	hp -= dmg
	_flash = 1.0
	EventBus.damage_number.emit(global_position + Vector2(0, -18), dmg, 0)
	if knockback > 0.0 and from != Vector2.ZERO:
		move_resolved((global_position - from).normalized() * knockback)
	if GameState.lifesteal > 0.0:
		GameState.heal(int(ceil(dmg * GameState.lifesteal)))
	if hp <= 0:
		_die()
	else:
		_stun = 0.10
	if is_boss:
		EventBus.boss_hp_changed.emit(hp, max_hp)


func _die() -> void:
	is_dead = true
	GameState.kills += 1
	GameState.add_xp(xp_reward)
	if not is_boss:
		GameState.add_gold(gold_reward)
	EventBus.enemy_killed.emit(String(data.get("name", "Monster")), global_position, xp_reward)
	died.emit(self)
	# fade out then free
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.28)
	tw.tween_callback(queue_free)


func freeze_forever() -> void:
	GameState.freeze_enemies = true
