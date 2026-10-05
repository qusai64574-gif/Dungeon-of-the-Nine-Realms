class_name Pickup
extends Node2D
## Loot on the floor: coins, potions, keys, gear. Bobs, then gets hoovered up.

var kind: String = "gold"
var amount: int = 1
var payload: Dictionary = {}
var _t: float = 0.0
var _home: Vector2
var _collected := false
var grid: Array = []

var sprite: Sprite2D = null


func setup(k: String, amt: int = 1, data: Dictionary = {}) -> void:
	kind = k
	amount = amt
	payload = data


func _ready() -> void:
	_home = position
	# build the visual here — @onready would resolve before this node's
	# children exist, since callers add the Sprite lazily.
	sprite = Sprite2D.new()
	sprite.name = "Sprite"
	add_child(sprite)
	var path := Assets.item(kind)
	var tex: Texture2D = load(path)
	if tex == null:
		tex = load(Assets.item("gold"))
	sprite.texture = tex
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var native := tex.get_size()
	# Items sit SMALLER than the character (26px) so loot never competes with
	# the hero for attention. Chests are the one prop allowed to read big.
	var target := 24.0 if kind == "chest" else 13.0
	var sc: float = target / maxf(native.x, native.y)
	sprite.scale = Vector2(sc, sc)
	sprite.z_index = 3
	_t = randf() * TAU


func _process(delta: float) -> void:
	if _collected:
		return
	_t += delta * 3.0
	position.y = _home.y + sin(_t) * 2.0
	# magnet
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var p: Node2D = players[0]
	var d := p.global_position.distance_to(global_position)
	var pr := GameState.stat_pickup_radius
	if d < pr:
		position += (p.global_position - position).normalized() * (260.0 * (1.0 - d / maxf(1.0, pr))) * delta
	if d < 14.0:
		_collect(p)


func _collect(p: Node2D) -> void:
	if _collected:
		return
	_collected = true
	match kind:
		"gold":
			GameState.add_gold(amount)
		"heart":
			GameState.heal(amount)
			EventBus.damage_number.emit(global_position, amount, 2)
		"fairy":
			GameState.heal(amount)
			EventBus.damage_number.emit(global_position, amount, 2)
		"health_potion":
			GameState.heal(amount)
			EventBus.damage_number.emit(global_position, amount, 2)
		"mana_potion", "antidote":
			GameState.add_xp(amount)
		"gem":
			GameState.add_gold(amount * 5)
			GameState.add_xp(2)
		"sword", "fire_sword", "ice_sword", "lightning_sword", "rainbow_sword":
			GameState.base_damage += amount
			EventBus.toast_msg("+%d ATTACK" % amount, Color(1, 0.6, 0.5))
		"armor":
			GameState.armour += amount
			EventBus.toast_msg("+%d ARMOUR" % amount, Color(0.6, 0.8, 1.0))
		"helmet":
			GameState.add_max_hp(amount)
			EventBus.toast_msg("+%d MAX HP" % amount, Color(0.7, 1.0, 0.7))
		"shield":
			GameState.armour += amount
		"ring":
			GameState.crit_chance = minf(0.85, GameState.crit_chance + 0.03 * amount)
			EventBus.toast_msg("+CRIT CHANCE", Color(1, 0.9, 0.4))
		"necklace":
			GameState.lifesteal = minf(0.5, GameState.lifesteal + 0.02 * amount)
			EventBus.toast_msg("+LIFESTEAL", Color(0.9, 0.4, 0.6))
		"scroll", "spell_book":
			GameState.add_xp(amount * 4)
		"chest":
			_open_chest()
		_:
			GameState.add_gold(1)
	EventBus.stats_changed.emit()
	var fx := HitFX.new()
	fx.setup(global_position, Color(1.0, 0.85, 0.35), 6, 60.0, 2.0)
	get_parent().add_child(fx)
	queue_free()


func _open_chest() -> void:
	# chests spill a small pile of loot around themselves
	var parent := get_parent()
	var table := [
		{"k": "gold", "a": randi_range(12, 34)},
		{"k": "gold", "a": randi_range(8, 20)},
		{"k": "health_potion", "a": 25},
		{"k": "gem", "a": 1},
	]
	if randf() < 0.45:
		table.append({"k": ["sword", "armor", "helmet", "ring", "shield"].pick_random(), "a": 2})
	if randf() < 0.25:
		table.append({"k": "necklace", "a": 1})
	for entry in table:
		var pk := Pickup.new()
		pk.setup(String(entry["k"]), int(entry["a"]))
		pk.position = global_position + Vector2(randf_range(-16, 16), randf_range(-14, 14))
		parent.add_child(pk)
	EventBus.toast_msg("CHEST OPENED", Color(1.0, 0.85, 0.35))
