class_name AnimSprite
extends Sprite2D
## Plays a named animation out of a packed character sheet by driving
## hframes/vframes over a region_rect. The frame geometry comes from the
## asset pack's own JSON descriptors (see assets/sprite_manifest.json).

var _anim: String = ""
var _cfg: Dictionary = {}
var _t: float = 0.0
var _idx: int = 0
var _finished: bool = false
var loop: bool = true


func setup(sheet_key: String) -> void:
	texture = load(Assets.char_sheet(sheet_key))
	centered = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func play(anim: String, restart: bool = false) -> void:
	if anim == _anim and not restart:
		return
	var cfg := Assets.char_anim(_sheet_key(), anim)
	if cfg.is_empty():
		return
	_anim = anim
	_cfg = cfg
	region_enabled = true
	var sw: int = cfg["sw"]
	var sh: int = cfg["sh"]
	var cols: int = maxi(1, cfg["cols"])
	var rows: int = maxi(1, cfg["rows"])
	region_rect = Rect2(cfg["x"], cfg["y"], sw * cols, sh * rows)
	hframes = cols
	vframes = rows
	loop = bool(cfg.get("loop", true))
	_t = 0.0
	_idx = 0
	_finished = false
	frame = 0


var _key_cache: String = ""

func set_sheet_key(k: String) -> void:
	_key_cache = k


func _sheet_key() -> String:
	return _key_cache


func is_finished() -> bool:
	return _finished


## Animation playback rate, by animation family.
## The asset pack's `framesPerSprite` is in MILLISECONDS, so 1000/ms yields
## 33-100 fps — far too fast for a walk cycle and it reads as a blur.
## Map the family to a hand-tuned rate instead of trusting the descriptor.
const ANIM_FPS := {
	"idle": 5.0,
	"run": 9.0,
	"fight": 12.0,
	"sword": 12.0,
	"die": 8.0,
	"attack": 12.0,
	"hit": 10.0,
}

const FPS_FALLBACK := 8.0


static func fps_for(anim: String) -> float:
	# anim names look like "run_down", "idle_left", "idle", "fight_up"
	for prefix in ANIM_FPS:
		if anim.begins_with(prefix):
			return float(ANIM_FPS[prefix])
	return FPS_FALLBACK


func _process(delta: float) -> void:
	if _cfg.is_empty():
		return
	var fps: float = maxf(1.0, fps_for(_anim))
	var total := hframes * vframes
	if total <= 1:
		return
	_t += delta
	var step := 1.0 / fps
	while _t >= step:
		_t -= step
		_idx += 1
		if _idx >= total:
			if loop:
				_idx = 0
			else:
				_idx = total - 1
				_finished = true
				break
		frame = _idx
