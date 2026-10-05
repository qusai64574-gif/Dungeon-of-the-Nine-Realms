extends Node
## Persistence: settings, run progress (auto-saved), and meta stats.
##
##   user://settings.cfg   — audio/visual prefs + control hints
##   user://save_run.cfg   — the in-progress run (auto-saved continuously)
##   user://meta.cfg       — best depth, total kills, cheats

const SETTINGS := "user://settings.cfg"
const RUN := "user://save_run.cfg"
const META := "user://meta.cfg"

signal run_saved
signal run_loaded
signal settings_changed

# --- settings -------------------------------------------------------------
var master_volume: float = 1.0
var brightness: float = 1.0
var show_damage_numbers: bool = true
var screen_shake: bool = true
var camera_zoom: float = 2.4
var sfx_enabled: bool = true

# --- meta -----------------------------------------------------------------
var best_depth: int = 0
var total_kills: int = 0
var total_runs: int = 0

var _autosave_timer: float = 0.0
const AUTOSAVE_EVERY := 20.0     # seconds
var _dirty: bool = false


func _ready() -> void:
	load_settings()
	load_meta()


func _process(delta: float) -> void:
	if not has_save():
		return
	_autosave_timer += delta
	if _autosave_timer >= AUTOSAVE_EVERY:
		_autosave_timer = 0.0
		save_run()


func mark_dirty() -> void:
	_dirty = true
	_autosave_timer = 0.0


# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------
func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS) != OK:
		return
	master_volume = float(cfg.get_value("audio", "master_volume", 1.0))
	sfx_enabled = bool(cfg.get_value("audio", "sfx_enabled", true))
	brightness = float(cfg.get_value("video", "brightness", 1.0))
	show_damage_numbers = bool(cfg.get_value("video", "show_damage_numbers", true))
	screen_shake = bool(cfg.get_value("video", "screen_shake", true))
	camera_zoom = float(cfg.get_value("video", "camera_zoom", 2.4))
	_apply_audio()
	settings_changed.emit()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "sfx_enabled", sfx_enabled)
	cfg.set_value("video", "brightness", brightness)
	cfg.set_value("video", "show_damage_numbers", show_damage_numbers)
	cfg.set_value("video", "screen_shake", screen_shake)
	cfg.set_value("video", "camera_zoom", camera_zoom)
	cfg.save(SETTINGS)
	_apply_audio()
	settings_changed.emit()


func _apply_audio() -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(clampf(master_volume, 0.0001, 1.0)))
		AudioServer.set_bus_mute(bus, master_volume <= 0.001)


# ---------------------------------------------------------------------------
# Meta
# ---------------------------------------------------------------------------
func load_meta() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(META) != OK:
		return
	best_depth = int(cfg.get_value("meta", "best_depth", 0))
	total_kills = int(cfg.get_value("meta", "total_kills", 0))
	total_runs = int(cfg.get_value("meta", "total_runs", 0))


func save_meta() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "best_depth", best_depth)
	cfg.set_value("meta", "total_kills", total_kills)
	cfg.set_value("meta", "total_runs", total_runs)
	cfg.save(META)


func record_run_end(victory: bool) -> void:
	best_depth = maxi(best_depth, GameState.depth)
	total_kills += GameState.kills
	total_runs += 1
	save_meta()
	clear_run()


# ---------------------------------------------------------------------------
# Run save / load
# ---------------------------------------------------------------------------
func has_save() -> bool:
	return FileAccess.file_exists(RUN)


func save_run() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("run", "depth", GameState.depth)
	cfg.set_value("run", "gold", GameState.gold)
	cfg.set_value("run", "kills", GameState.kills)
	cfg.set_value("run", "run_time", GameState.run_time)
	cfg.set_value("run", "hp", GameState.hp)
	cfg.set_value("run", "max_hp", GameState.max_hp)
	cfg.set_value("run", "level", GameState.level)
	cfg.set_value("run", "xp", GameState.xp)
	cfg.set_value("run", "xp_needed", GameState.xp_needed)
	cfg.set_value("run", "base_damage", GameState.base_damage)
	cfg.set_value("run", "armour", GameState.armour)
	cfg.set_value("run", "crit_chance", GameState.crit_chance)
	cfg.set_value("run", "crit_mult", GameState.crit_mult)
	cfg.set_value("run", "lifesteal", GameState.lifesteal)
	cfg.set_value("run", "biome", GameState.biome)
	cfg.set_value("run", "seed", GameState.run_seed)
	cfg.set_value("run", "valid", true)
	cfg.save(RUN)
	_dirty = false
	run_saved.emit()


func load_run() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(RUN) != OK:
		return false
	if not bool(cfg.get_value("run", "valid", false)):
		return false
	GameState.depth = int(cfg.get_value("run", "depth", 1))
	GameState.gold = int(cfg.get_value("run", "gold", 0))
	GameState.kills = int(cfg.get_value("run", "kills", 0))
	GameState.run_time = float(cfg.get_value("run", "run_time", 0.0))
	GameState.max_hp = int(cfg.get_value("run", "max_hp", 100))
	GameState.hp = int(cfg.get_value("run", "hp", GameState.max_hp))
	GameState.level = int(cfg.get_value("run", "level", 1))
	GameState.xp = int(cfg.get_value("run", "xp", 0))
	GameState.xp_needed = int(cfg.get_value("run", "xp_needed", 12))
	GameState.base_damage = int(cfg.get_value("run", "base_damage", 12))
	GameState.armour = int(cfg.get_value("run", "armour", 0))
	GameState.crit_chance = float(cfg.get_value("run", "crit_chance", 0.12))
	GameState.crit_mult = float(cfg.get_value("run", "crit_mult", 2.0))
	GameState.lifesteal = float(cfg.get_value("run", "lifesteal", 0.0))
	GameState.biome = String(cfg.get_value("run", "biome", "auto"))
	GameState.run_seed = int(cfg.get_value("run", "seed", 0))
	run_loaded.emit()
	return true


func clear_run() -> void:
	if FileAccess.file_exists(RUN):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUN))


func save_summary() -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(RUN) != OK:
		return {}
	return {
		"depth": int(cfg.get_value("run", "depth", 1)),
		"gold": int(cfg.get_value("run", "gold", 0)),
		"kills": int(cfg.get_value("run", "kills", 0)),
		"level": int(cfg.get_value("run", "level", 1)),
		"time": float(cfg.get_value("run", "run_time", 0.0)),
		"biome": String(cfg.get_value("run", "biome", "auto")),
	}
