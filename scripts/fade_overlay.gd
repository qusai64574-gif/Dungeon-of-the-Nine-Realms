class_name FadeOverlay
extends CanvasLayer
## Full-screen fade used for scene-ish transitions (menu -> run, run -> menu,
## death -> restart). Owns a black plate plus an optional accent flash so
## transitions feel like a cut rather than a blink.

var _plate: ColorRect
var _accent: ColorRect
var _busy := false
var _tween: Tween


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_plate = ColorRect.new()
	_plate.set_anchors_preset(Control.PRESET_FULL_RECT)
	_plate.color = Color(0.02, 0.015, 0.04, 0.0)
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_plate)

	_accent = ColorRect.new()
	_accent.set_anchors_preset(Control.PRESET_FULL_RECT)
	_accent.color = Color(1, 1, 1, 0.0)
	_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_accent)


## Fade to opaque, run `mid` (a Callable), then fade back in.
func transition(mid: Callable, accent: Color = Color(1, 1, 1), dur: float = 0.20) -> void:
	if _busy:
		# never swallow an input during a transition — just run it
		mid.call()
		return
	_busy = true
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_plate, "color:a", 1.0, dur).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(_accent, "color:a", 0.55, dur * 0.6)
	await _tween.finished
	mid.call()
	await get_tree().process_frame
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_plate, "color:a", 0.0, dur * 1.35).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(_accent, "color:a", 0.0, dur * 0.9)
	await _tween.finished
	_busy = false


## Quick accent-only flash, no blackout. Good for the lightning impact.
func flash(colour: Color = Color(1, 1, 1), strength: float = 0.5, dur: float = 0.22) -> void:
	var tw := create_tween()
	tw.tween_property(_accent, "color:a", strength, 0.05)
	tw.tween_property(_accent, "color:a", 0.0, dur)


func set_accent(colour: Color) -> void:
	_accent.color = Color(colour.r, colour.g, colour.b, _accent.color.a)

## Stop any running transition and clear the screen immediately.
func stop() -> void:
	_busy = false
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null
	_plate.color.a = 0.0
	_accent.color.a = 0.0
