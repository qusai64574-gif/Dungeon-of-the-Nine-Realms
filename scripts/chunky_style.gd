class_name ChunkyStyle
extends RefCounted
## The menu look: thick outlined "toy block" panels and buttons with hard,
## unblurred drop shadows, a warm parchment palette over a cool backdrop, and
## a storybook display face.
##
## Rules that define the style (do not soften them):
##   1. Thick, fully-opaque dark outline on every panel and button.
##   2. HARD offset shadow — no blur, no feather. A second offset block.
##   3. Flat warm fill. No gloss, no gradient on the button face.
##   4. Slight per-item rotation so the stack looks hand-placed, not aligned.
##   5. No glows. Contrast comes from the outline and the hard shadow.

# --- palette (warm UI over a cool backdrop) --------------------------------
const PARCHMENT      := Color("#f0e0bd")   # button / panel face
const PARCHMENT_HI   := Color("#fbf1d6")   # hover face
const PARCHMENT_LO   := Color("#d8c396")   # pressed face
const OUTLINE        := Color("#3b2414")   # the thick dark border
const SHADOW         := Color("#2a180c")   # hard drop shadow
const INK            := Color("#8a3a1e")   # text / logo
const INK_BRIGHT     := Color("#c0562c")
const CREAM          := Color("#fff6e0")   # text outline
const GOLD           := Color("#e0a63a")
const GOLD_DEEP      := Color("#a86f18")

# --- backdrop --------------------------------------------------------------
const SKY_TOP        := Color("#6fbfe0")
const SKY_BOT        := Color("#a9d8ea")
const GROUND_TOP     := Color("#9b7cb6")
const GROUND_BOT     := Color("#6d5286")

# accent colours for menu entries (kept warm/earthy so they sit in the palette)
const ACCENTS := {
	"primary": Color("#c0562c"),
	"go":      Color("#4f9d5d"),
	"info":    Color("#3f7fa8"),
	"magic":   Color("#8a5aa8"),
	"warn":    Color("#c98a1e"),
	"danger":  Color("#a8322a"),
	"neutral": Color("#8a7358"),
}

const BORDER := 4
const SHADOW_OFF := Vector2(5, 5)


# --- styleboxes ------------------------------------------------------------
## A thick-outlined block with a hard shadow. `face` is the flat fill.
static func block(face: Color, radius: int = 5, border: int = BORDER,
		outline: Color = OUTLINE, shadow: bool = true) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = face
	sb.border_color = outline
	sb.set_border_width_all(border)
	sb.set_corner_radius_all(radius)
	if shadow:
		sb.shadow_color = SHADOW
		sb.shadow_size = 0            # size 0 + offset = a HARD shadow
		sb.shadow_offset = SHADOW_OFF
	return sb


static func panel(face: Color = PARCHMENT, radius: int = 8) -> StyleBoxFlat:
	var sb := block(face, radius, BORDER + 1)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	return sb


## Dark inner well, used for scroll areas and settings insets.
static func well() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#e2cfa6")
	sb.border_color = Color("#b9a077")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb


static func button_normal(accent: Color = INK) -> StyleBoxFlat:
	var sb := block(PARCHMENT, 5)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


static func button_hover(accent: Color = INK) -> StyleBoxFlat:
	var sb := block(PARCHMENT_HI, 5, BORDER, OUTLINE, true)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


## Pressed: the shadow collapses and the block shifts onto it — a real press.
static func button_pressed() -> StyleBoxFlat:
	var sb := block(PARCHMENT_LO, 5, BORDER, OUTLINE, false)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


static func button_disabled() -> StyleBoxFlat:
	var sb := block(Color("#cbb894"), 5, BORDER, Color("#8f7c5e"), true)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


# --- fonts -----------------------------------------------------------------
static var _display: Font
static var _ui: Font

static func font_display() -> Font:
	if _display == null:
		_display = load("res://assets/fonts/GrenzeGotisch.ttf")
		if _display == null:
			_display = load(Assets.FONT_TITLE)
	return _display


static func font_ui() -> Font:
	if _ui == null:
		_ui = load(Assets.FONT_UI)
	return _ui


# --- text helpers ----------------------------------------------------------
## Storybook heading: display face, ink fill, cream outline, hard shadow.
## The outline must stay thin relative to the glyph size — at 0.22x the cream
## halo swallows small letters and the word reads as a smudge.
static func heading(lbl: Label, size: int = 30, colour: Color = INK) -> void:
	lbl.add_theme_font_override("font", font_display())
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", colour)
	lbl.add_theme_color_override("font_outline_color", CREAM)
	lbl.add_theme_constant_override("outline_size", clampi(int(size * 0.13), 2, 8))
	lbl.add_theme_color_override("font_shadow_color", SHADOW)
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)


static func body(lbl: Label, size: int = 15, colour: Color = Color("#4a3320")) -> void:
	lbl.add_theme_font_override("font", font_ui())
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", colour)


## Button label styling shared by every chunky button.
static func style_button_text(b: Button, size: int = 20) -> void:
	b.add_theme_font_override("font", font_display())
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK_BRIGHT)
	b.add_theme_color_override("font_pressed_color", OUTLINE)
	b.add_theme_color_override("font_focus_color", INK_BRIGHT)
	b.add_theme_color_override("font_disabled_color", Color("#9a8768"))
	b.add_theme_color_override("font_outline_color", CREAM)
	b.add_theme_constant_override("outline_size", maxi(3, int(size * 0.18)))
	b.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.28))
	b.add_theme_constant_override("shadow_offset_x", 1)
	b.add_theme_constant_override("shadow_offset_y", 2)


# --- whole-app theme (admin panel + pause + settings all inherit) ----------
static func build_theme() -> Theme:
	var t := Theme.new()
	var disp := font_display()
	var ui := font_ui()

	t.default_font = ui
	t.default_font_size = 15

	# Label — ink on parchment
	t.set_font("font", "Label", ui)
	t.set_font_size("font_size", "Label", 15)
	t.set_color("font_color", "Label", Color("#4a3320"))
	t.set_color("font_outline_color", "Label", CREAM)
	t.set_constant("outline_size", "Label", 0)

	t.set_font("normal_font", "RichTextLabel", ui)
	t.set_font("bold_font", "RichTextLabel", disp)
	t.set_font_size("normal_font_size", "RichTextLabel", 15)
	t.set_color("default_color", "RichTextLabel", Color("#4a3320"))

	# Button — the chunky block
	t.set_font("font", "Button", disp)
	t.set_font_size("font_size", "Button", 20)
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", INK_BRIGHT)
	t.set_color("font_pressed_color", "Button", OUTLINE)
	t.set_color("font_focus_color", "Button", INK_BRIGHT)
	t.set_color("font_disabled_color", "Button", Color("#9a8768"))
	t.set_color("font_outline_color", "Button", CREAM)
	t.set_constant("outline_size", "Button", 4)
	t.set_stylebox("normal", "Button", button_normal())
	t.set_stylebox("hover", "Button", button_hover())
	t.set_stylebox("pressed", "Button", button_pressed())
	t.set_stylebox("focus", "Button", button_hover())
	t.set_stylebox("disabled", "Button", button_disabled())

	# Panel — the parchment slab
	t.set_stylebox("panel", "Panel", panel())
	t.set_stylebox("panel", "PanelContainer", panel())

	# ProgressBar — carved channel with a filled bar
	t.set_stylebox("background", "ProgressBar", _bar_track())
	t.set_stylebox("fill", "ProgressBar", _bar_fill(Color("#c0562c")))
	t.set_color("font_color", "ProgressBar", OUTLINE)

	# CheckBox / CheckButton
	t.set_font("font", "CheckBox", ui)
	t.set_font_size("font_size", "CheckBox", 15)
	t.set_color("font_color", "CheckBox", Color("#3a2414"))
	t.set_color("font_pressed_color", "CheckBox", Color("#3a2414"))
	t.set_color("font_hover_color", "CheckBox", INK_BRIGHT)
	t.set_stylebox("normal", "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("hover", "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("pressed", "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("focus", "CheckBox", StyleBoxEmpty.new())

	t.set_font("font", "CheckButton", ui)
	t.set_font_size("font_size", "CheckButton", 15)
	t.set_color("font_color", "CheckButton", Color("#3a2414"))
	t.set_color("font_hover_color", "CheckButton", INK_BRIGHT)
	t.set_color("font_pressed_color", "CheckButton", Color("#3a2414"))
	t.set_color("font_hover_color", "CheckButton", INK_BRIGHT)

	# Slider — carved groove with a chunky knob
	t.set_stylebox("slider", "HSlider", _bar_track())
	t.set_stylebox("grabber_area", "HSlider", _bar_fill(GOLD_DEEP))
	t.set_stylebox("grabber_area_highlight", "HSlider", _bar_fill(GOLD))

	# Scroll
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	t.set_stylebox("scroll", "VScrollBar", block(Color("#cbb894"), 5, 3, Color("#8f7c5e"), false))
	t.set_stylebox("grabber", "VScrollBar", block(Color("#8f7c5e"), 5, 2, OUTLINE, false))
	t.set_stylebox("grabber_highlight", "VScrollBar", block(GOLD_DEEP, 5, 2, OUTLINE, false))

	# LineEdit — a well
	t.set_stylebox("normal", "LineEdit", well())
	t.set_stylebox("focus", "LineEdit", well())
	t.set_font("font", "LineEdit", ui)
	t.set_color("font_color", "LineEdit", Color("#4a3320"))
	t.set_color("caret_color", "LineEdit", INK)

	# Tabs
	t.set_stylebox("panel", "TabContainer", panel())
	t.set_stylebox("tab_selected", "TabContainer", block(PARCHMENT_HI, 6, 3))
	t.set_stylebox("tab_unselected", "TabContainer", block(Color("#d8c396"), 6, 3, Color("#8f7c5e")))
	t.set_stylebox("tab_hovered", "TabContainer", block(PARCHMENT_HI, 6, 3))
	t.set_color("font_selected_color", "TabContainer", INK_BRIGHT)
	t.set_color("font_unselected_color", "TabContainer", Color("#8a7358"))
	t.set_font("font", "TabContainer", disp)
	t.set_font_size("font_size", "TabContainer", 20)

	# Tooltip
	t.set_stylebox("panel", "TooltipPanel", panel(Color("#fbf1d6"), 5))
	t.set_font("font", "TooltipLabel", ui)
	t.set_font_size("font_size", "TooltipLabel", 14)
	t.set_color("font_color", "TooltipLabel", Color("#4a3320"))

	return t


static func _bar_track() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#c9b48c")
	sb.border_color = Color("#8f7c5e")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	return sb


static func _bar_fill(col: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.border_color = OUTLINE
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	return sb


# --- backdrop art ----------------------------------------------------------
## Sky-over-ground gradient, painted once and reused by every menu screen.
static func backdrop_texture(w: int = 320, h: int = 180) -> Texture2D:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var horizon := 0.46
	for y in h:
		var f := float(y) / float(h - 1)
		var c: Color
		if f < horizon:
			c = SKY_TOP.lerp(SKY_BOT, f / horizon)
		else:
			var g := (f - horizon) / (1.0 - horizon)
			c = GROUND_TOP.lerp(GROUND_BOT, g)
		for x in w:
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)
