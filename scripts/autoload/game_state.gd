extends Node
## Persistent run state: player stats, progression, cheats, settings.
## Everything the admin panel can mutate lives here.

const SAVE_PATH := "user://dungeon_run.cfg"

# --- Run state -------------------------------------------------------------
var depth: int = 1
var gold: int = 0
var kills: int = 0
var turns: int = 0
var run_time: float = 0.0
var biome: String = "auto"
var admin_open: bool = false
var run_seed: int = 0

# --- Player stats (base + cheats) -----------------------------------------
var max_hp: int = 100
var hp: int = 100
var level: int = 1
var xp: int = 0
var xp_needed: int = 12

var base_damage: int = 12
var attack_speed: float = 0.42      # seconds between swings
var move_speed: float = 132.0
var crit_chance: float = 0.12
var crit_mult: float = 2.0
var armour: int = 0
var lifesteal: float = 0.0
var pickup_radius: float = 46.0
var projectile_count: int = 1
var projectile_speed: float = 420.0

# --- Cheat flags -----------------------------------------------------------
var god_mode: bool = false
var one_hit_kill: bool = false
var infinite_gold: bool = false
var no_cooldown: bool = false
var speed_mult: float = 1.0
var damage_mult: float = 1.0
var xp_mult: float = 1.0
var enemy_speed_mult: float = 1.0
var map_revealed: bool = false
var freeze_enemies: bool = false
var auto_heal: bool = false
var magnet_all: bool = false

# --- Derived (cheats folded in) -------------------------------------------
var stat_damage: int:
	get: return int(round(base_damage * damage_mult))
var stat_move_speed: float:
	get: return move_speed * speed_mult
var stat_attack_speed: float:
	get: return 0.06 if no_cooldown else attack_speed
var stat_pickup_radius: float:
	get: return 99999.0 if magnet_all else pickup_radius
var stat_crit: float:
	get: return 1.0 if one_hit_kill else crit_chance


func reset_run() -> void:
	depth = 1
	gold = 0
	kills = 0
	turns = 0
	run_time = 0.0
	biome = "auto"
	max_hp = 100
	hp = max_hp
	level = 1
	xp = 0
	xp_needed = 12
	base_damage = 12
	attack_speed = 0.42
	move_speed = 132.0
	crit_chance = 0.12
	crit_mult = 2.0
	armour = 0
	lifesteal = 0.0
	pickup_radius = 46.0
	projectile_count = 1
	# cheats are deliberately NOT reset — the admin keeps their toys
	EventBus.run_started.emit()
	EventBus.stats_changed.emit()


# --- Damage / heal ---------------------------------------------------------
func take_damage(amount: int, source: Vector2 = Vector2.ZERO) -> void:
	if god_mode or amount <= 0:
		return
	var reduced := maxi(1, amount - armour)
	hp = maxi(0, hp - reduced)
	EventBus.hp_changed.emit(hp, max_hp)
	EventBus.player_damaged.emit(reduced, source)
	EventBus.damage_number.emit(source, reduced, 3)
	if hp <= 0:
		EventBus.player_died.emit()


func heal(amount: int) -> void:
	if amount <= 0:
		return
	var before := hp
	hp = mini(max_hp, hp + amount)
	var gained := hp - before
	if gained > 0:
		EventBus.player_healed.emit(gained)
		EventBus.hp_changed.emit(hp, max_hp)


func add_gold(amount: int) -> void:
	gold = maxi(0, gold + amount)
	EventBus.gold_changed.emit(gold)


func add_xp(amount: int) -> void:
	xp += int(round(amount * xp_mult))
	while xp >= xp_needed:
		xp -= xp_needed
		level += 1
		xp_needed = int(round(xp_needed * 1.45 + 4))
		max_hp += 12
		hp = max_hp
		base_damage += 3
		EventBus.player_leveled.emit(level)
		EventBus.toast_msg("LEVEL %d  —  stronger." % level, Color(1.0, 0.86, 0.4))
	EventBus.xp_changed.emit(xp, xp_needed, level)
	EventBus.hp_changed.emit(hp, max_hp)


func add_max_hp(amount: int) -> void:
	max_hp += amount
	hp += amount
	EventBus.hp_changed.emit(hp, max_hp)
	EventBus.stats_changed.emit()


func descend() -> void:
	depth += 1
	EventBus.floor_changed.emit(depth)
	EventBus.stats_changed.emit()


# --- Save / load (meta only; runs are permadeath) --------------------------
func save_meta() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "best_depth", maxi(depth, cfg.get_value("meta", "best_depth", 0)))
	cfg.set_value("meta", "total_kills", kills)
	cfg.set_value("cheats", "god_mode", god_mode)
	cfg.set_value("cheats", "one_hit_kill", one_hit_kill)
	cfg.set_value("cheats", "speed_mult", speed_mult)
	cfg.set_value("cheats", "damage_mult", damage_mult)
	cfg.save(SAVE_PATH)


func load_meta() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	god_mode = cfg.get_value("cheats", "god_mode", false)
	one_hit_kill = cfg.get_value("cheats", "one_hit_kill", false)
	speed_mult = cfg.get_value("cheats", "speed_mult", 1.0)
	damage_mult = cfg.get_value("cheats", "damage_mult", 1.0)
