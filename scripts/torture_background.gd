class_name TortureBackground
extends Control
## Procedural torture chamber background with hanging bodies, blood, and chains.
## Uses a generated texture for reliable rendering.

var _t: float = 0.0
var _tex_rect: TextureRect
var _bodies: Array = []
var _blood_stains: Array = []
var _chains: Array = []


func _ready() -> void:
	custom_minimum_size = Vector2(1280, 720)
	_generate()
	_build_texture()
	set_process(true)


func _generate() -> void:
	_bodies.clear()
	for i in 8:
		_bodies.append([
			randf_range(80, 1200),
			randf_range(150, 400),
			randf_range(0.6, 1.2),
			randf_range(0, TAU),
			randi() % 3,
		])
	_blood_stains.clear()
	for i in 15:
		_blood_stains.append([
			randf_range(0, 1280),
			randf_range(300, 720),
			randf_range(10, 50),
			randf_range(0.2, 0.5),
		])
	_chains.clear()
	for i in 10:
		_chains.append([
			randf_range(50, 1230),
			randf_range(80, 200),
		])


func _build_texture() -> void:
	var w := 1280
	var h := 720
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	
	# Dark gradient background
	for y in h:
		for x in w:
			var t := float(y) / h
			var col := Color("#080408").lerp(Color("#1a0a0e"), t)
			var bx := x % 32
			var by := y % 32
			if bx == 0 or by == 0:
				col = col.darkened(0.15)
			for stain in _blood_stains:
				var dx: int = x - int(stain[0])
				var dy: int = y - int(stain[1])
				var dist: float = sqrt(dx*dx + dy*dy)
				if dist < float(stain[2]):
					var a: float = float(stain[3]) * (1.0 - dist / float(stain[2]))
					col = col.lerp(Color("#4a0000"), a)
			img.set_pixel(x, y, col)
	
	# Load and paste torture figures
	var torture_tex := load("res://assets/characters/torture_hanging.png")
	if torture_tex:
		# Draw the torture figures texture
		var torture_img: Image = torture_tex.get_image()
		for y in mini(h, torture_img.get_height()):
			for x in min(w, torture_img.get_width()):
				var pixel_col: Color = torture_img.get_pixel(x, y)
				if pixel_col.a > 0:
					# Blend with background
					var bg_col: Color = img.get_pixel(x, y)
					var alpha := pixel_col.a
					var blended := bg_col.lerp(Color(pixel_col.r, pixel_col.g, pixel_col.b), alpha)
					img.set_pixel(x, y, blended)
	
	# Chains
	for chain in _chains:
		var cx: int = int(chain[0])
		var clen: int = int(chain[1])
		for i in clen:
			var ly := i
			if ly >= h:
				break
			var link_size := 4
			for dy in link_size:
				for dx in link_size:
					if cx + dx < w and ly + dy < h:
						var col := Color("#2a1518") if (i / link_size) % 2 == 0 else Color("#1a0d12")
						img.set_pixel(cx + dx, ly + dy, col)
	
	# Spikes on floor
	for i in 12:
		var sx := 40 + i * 100
		var sy := 640
		for dy in 25:
			for dx in 6:
				if sx + dx < w and sy - dy >= 0:
					var shrink := int(float(dy) / 25.0 * 3.0)
					if dx >= shrink and dx < 6 - shrink:
						img.set_pixel(sx + dx, sy - dy, Color("#120a0e"))
	
	# Vignette
	for y in h:
		for x in w:
			var dx := (x - w/2) / (w/2)
			var dy := (y - h/2) / (h/2)
			var d := sqrt(dx*dx + dy*dy)
			var a := clampf(pow(d, 1.8) * 0.8, 0.0, 0.8)
			var col := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(col.r * (1.0 - a), col.g * (1.0 - a), col.b * (1.0 - a)))
	
	var tex := ImageTexture.create_from_image(img)
	_tex_rect = TextureRect.new()
	_tex_rect.texture = tex
	_tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tex_rect)


func _process(delta: float) -> void:
	_t += delta
