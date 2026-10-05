class_name LoadingScreen
extends CanvasLayer
## Loading screen — shows for 5 seconds, then transitions to the game.

signal finished

var _root: Control
var _t: float = 0.0
var _duration := 5.0
var _done := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = true


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.size = Vector2(1280, 720)
	add_child(_root)

	# Black background
	var bg := ColorRect.new()
	bg.color = Color("#0a0205")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)

	# Title
	var title := ShakingLabel.new()
	title.text = "DUNGEON OF THE NINE REALMS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(240, 250)
	title.size = Vector2(800, 60)
	title.add_theme_font_override("font", DarkStyle.font_display())
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color("#c93a3a"))
	title.add_theme_color_override("font_outline_color", Color("#000000"))
	title.add_theme_constant_override("outline_size", 4)
	title.set_shake_amount(1.5)
	title.set_shake_speed(8.0)
	_root.add_child(title)

	# Loading text
	var loading := ShakingLabel.new()
	loading.text = "LOADING..."
	loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading.position = Vector2(440, 340)
	loading.size = Vector2(400, 40)
	loading.add_theme_font_override("font", DarkStyle.font_display())
	loading.add_theme_font_size_override("font_size", 24)
	loading.add_theme_color_override("font_color", Color("#8a6068"))
	loading.add_theme_color_override("font_outline_color", Color("#000000"))
	loading.add_theme_constant_override("outline_size", 2)
	loading.set_shake_amount(1.0)
	loading.set_shake_speed(6.0)
	_root.add_child(loading)

	# Progress bar background
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.1, 0.05, 0.08, 1.0)
	bar_bg.position = Vector2(340, 420)
	bar_bg.size = Vector2(600, 20)
	_root.add_child(bar_bg)

	# Progress bar fill
	var bar_fill := ColorRect.new()
	bar_fill.name = "BarFill"
	bar_fill.color = Color("#c93a3a")
	bar_fill.position = Vector2(340, 420)
	bar_fill.size = Vector2(0, 20)
	_root.add_child(bar_fill)

	# Percentage
	var pct := ShakingLabel.new()
	pct.name = "Percent"
	pct.text = "0%"
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pct.position = Vector2(540, 450)
	pct.size = Vector2(200, 30)
	pct.add_theme_font_override("font", DarkStyle.font_display())
	pct.add_theme_font_size_override("font_size", 18)
	pct.add_theme_color_override("font_color", Color("#8a6068"))
	pct.add_theme_color_override("font_outline_color", Color("#000000"))
	pct.add_theme_constant_override("outline_size", 2)
	pct.set_shake_amount(0.5)
	pct.set_shake_speed(4.0)
	_root.add_child(pct)


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	var progress := clampf(_t / _duration, 0.0, 1.0)

	# Update progress bar
	var bar_fill: ColorRect = _root.get_node_or_null("BarFill")
	if bar_fill:
		bar_fill.size.x = 600.0 * progress

	# Update percentage
	var pct: ShakingLabel = _root.get_node_or_null("Percent")
	if pct:
		pct.text = "%d%%" % int(progress * 100.0)

	if _t >= _duration:
		_done = true
		finished.emit()
