class_name DarkStyle
## Dark torture-chamber UI theme.
## Black panels, black buttons, blood-red text, dripping blood effects.

# --- palette ---------------------------------------------------------------
const BG_DEEP := Color("#0a0608")
const BG_MID := Color("#160d12")
const PANEL := Color("#120a0e")
const PANEL_HI := Color("#1e1218")
const OUTLINE := Color("#3d1520")
const INK := Color("#c8161e")
const INK_BRIGHT := Color("#ff2a30")
const INK_DIM := Color("#7a1016")
const BLOOD := Color("#8b0000")
const BLOOD_DARK := Color("#4a0000")
const SHADOW := Color("#000000")
const SHADOW_OFF := Vector2(5, 5)
const CREAM := Color("#2a1518")
const GOLD_DEEP := Color("#8b6914")

const ACCENTS := {
	"danger": Color("#ff2a30"),
	"warn": Color("#ff9040"),
	"go": Color("#4aba5a"),
	"info": Color("#4a9ab8"),
	"magic": Color("#9a4aba"),
	"neutral": Color("#8a6068"),
}

# --- fonts -----------------------------------------------------------------
static func font_display() -> Font:
	return load("res://assets/fonts/PixelifySans.ttf")

static func font_ui() -> Font:
	return load("res://assets/fonts/PixelifySans.ttf")

static func font_body() -> Font:
	return load("res://assets/fonts/PixelifySans.ttf")

# --- panels ----------------------------------------------------------------
static func panel(bg: Color = PANEL) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = OUTLINE
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb

static func well() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = BG_DEEP
	sb.border_color = OUTLINE.darkened(0.3)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	return sb

static func block(bg: Color, border_w: int = 3, radius: int = 4, border: Color = OUTLINE) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	return sb

# --- buttons ---------------------------------------------------------------
static func button_normal() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#0d0508")
	sb.border_color = OUTLINE
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

static func button_hover() -> StyleBoxFlat:
	var sb := button_normal()
	sb.bg_color = Color("#1a0a10")
	sb.border_color = INK_DIM
	return sb

static func button_pressed() -> StyleBoxFlat:
	var sb := button_normal()
	sb.bg_color = Color("#050203")
	sb.border_color = BLOOD_DARK
	return sb

# --- text ------------------------------------------------------------------
static func heading(lbl: Label, size: int = 30, colour: Color = INK) -> void:
	lbl.add_theme_font_override("font", font_display())
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", colour)
	lbl.add_theme_color_override("font_outline_color", SHADOW)
	lbl.add_theme_constant_override("outline_size", clampi(int(size * 0.10), 2, 6))
	lbl.add_theme_color_override("font_shadow_color", BLOOD_DARK)
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)

static func body(lbl: Label, size: int = 14, colour: Color = Color("#c93a3a")) -> void:
	lbl.add_theme_font_override("font", font_ui())
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", colour)
	lbl.add_theme_color_override("font_outline_color", SHADOW)
	lbl.add_theme_constant_override("outline_size", 2)

# --- backdrop: torture chamber --------------------------------------------
static func backdrop_texture(w: int = 64, h: int = 36) -> Texture2D:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var p := Vector2(float(x) / w, float(y) / h)
			# dark stone gradient: near-black at top, dark red-brown at bottom
			var t := p.y
			var col := BG_DEEP.lerp(BG_MID, t)
			# subtle stone block pattern
			var bx := int(x) % 16
			var by := int(y) % 16
			if bx == 0 or by == 0:
				col = col.darkened(0.15)
			# occasional dark red "blood stain" blotches
			var stain := sin(p.x * 12.7 + p.y * 7.3) * sin(p.x * 5.1 - p.y * 9.7)
			if stain > 0.85:
				col = col.lerp(BLOOD_DARK, 0.3)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

# --- vignette --------------------------------------------------------------
static func vignette_tex() -> Texture2D:
	var s := 128
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	var c := Vector2(s * 0.5, s * 0.5)
	var maxd := c.length()
	for y in s:
		for x in s:
			var d := Vector2(x - c.x, y - c.y).length() / maxd
			var a := clampf(pow(d, 1.8) * 1.3, 0.0, 1.0)
			img.set_pixel(x, y, Color(0, 0, 0, a))
	return ImageTexture.create_from_image(img)

# --- theme -----------------------------------------------------------------
static func build_theme() -> Theme:
	var t := Theme.new()
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", INK_BRIGHT)
	t.set_color("font_pressed_color", "Button", INK_DIM)
	t.set_color("font_color", "Label", Color("#c93a3a"))
	t.set_color("font_color", "CheckButton", Color("#c93a3a"))
	t.set_color("font_hover_color", "CheckButton", INK_BRIGHT)
	t.set_color("font_pressed_color", "CheckButton", Color("#c93a3a"))
	t.set_color("font_color", "CheckBox", Color("#c93a3a"))
	t.set_color("font_pressed_color", "CheckBox", Color("#c93a3a"))
	t.set_color("font_color", "HSlider", INK)
	t.set_color("font_color", "ScrollContainer", Color("#c93a3a"))
	return t
