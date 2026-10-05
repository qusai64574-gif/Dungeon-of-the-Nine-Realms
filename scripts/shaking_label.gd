class_name ShakingLabel
extends Label
## Label where each letter shakes on its own.

var _t: float = 0.0
var _shake_amount: float = 2.0
var _shake_speed: float = 8.0


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if text.is_empty():
		return
	var font: Font = get_theme_font("font")
	var font_size: int = get_theme_font_size("font_size")
	var lines := text.split("\n")
	var line_height := font.get_height(font_size)
	var total_h := line_height * lines.size()
	var start_y := (size.y - total_h) * 0.5 + font_size * 0.8

	for li in lines.size():
		var line_text: String = lines[li]
		if line_text.is_empty():
			continue
		var line_w := font.get_string_size(line_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var start_x := (size.x - line_w) * 0.5
		var baseline := start_y + li * line_height

		# Draw each letter with its own shake offset
		var x := start_x
		for ci in line_text.length():
			var ch := line_text[ci]
			if ch == " ":
				x += font.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
				continue
			var ch_w := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			# Each letter shakes independently
			var phase := _t * _shake_speed + float(ci) * 1.7 + float(li) * 3.1
			var ox := sin(phase) * _shake_amount
			var oy := cos(phase * 1.3) * _shake_amount * 0.5
			draw_string(font, Vector2(x + ox, baseline + oy), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
			x += ch_w


func set_shake_amount(a: float) -> void:
	_shake_amount = a


func set_shake_speed(s: float) -> void:
	_shake_speed = s
