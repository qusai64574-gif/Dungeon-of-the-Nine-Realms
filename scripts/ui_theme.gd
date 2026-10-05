class_name UITheme
extends RefCounted
## The look of the game. One place to change every colour, radius and font.
##
## Design decisions (from the HUD research):
##  - Anchored to screen edges, centre stays clear for the action.
##  - Every text element carries its own contrast guarantee (dark scrim +
##    outline) so it survives the brightest and darkest dungeon rooms.
##  - Colour never carries meaning alone — bars also change length, and icons
##    have distinct silhouettes.
##  - Health cluster bottom-left, run info top-left, minimap top-right.

# --- Palette ---------------------------------------------------------------
const BG_DEEP     := Color("#0b0912")
const PANEL_BG    := Color("#151120")
const PANEL_BG_2  := Color("#1d1830")
const PANEL_EDGE  := Color("#3a3050")
const GOLD        := Color("#e8c168")
const GOLD_DIM    := Color("#8a6d33")
const GOLD_BRIGHT := Color("#ffe6a3")
const TEXT        := Color("#ece7f5")
const TEXT_DIM    := Color("#9d95b3")
const TEXT_FAINT  := Color("#6b6480")
const HP_RED      := Color("#e0454a")
const HP_LOW      := Color("#ff6b3d")
const XP_BLUE     := Color("#5b8cff")
const XP_CYAN     := Color("#66e0ff")
const GOLD_COIN   := Color("#ffcc4d")
const DANGER      := Color("#ff4444")
const SUCCESS     := Color("#5fd68a")
const MAGIC       := Color("#b06bff")

const R := 6    # corner radius
const PAD := 12

static var _font_title: Font
static var _font_ui: Font
static var _font_pixel: Font


static func font_title() -> Font:
	if _font_title == null:
		_font_title = load(Assets.FONT_TITLE)
	return _font_title


static func font_ui() -> Font:
	if _font_ui == null:
		_font_ui = load(Assets.FONT_UI)
	return _font_ui


static func font_pixel() -> Font:
	if _font_pixel == null:
		_font_pixel = load(Assets.FONT_PIXEL)
	return _font_pixel


# --- Style boxes -----------------------------------------------------------
static func panel(bg: Color = PANEL_BG, edge: Color = PANEL_EDGE, border: int = 1,
		radius: int = R, shadow: bool = true) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = edge
	sb.set_border_width_all(border)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = PAD
	sb.content_margin_right = PAD
	sb.content_margin_top = PAD
	sb.content_margin_bottom = PAD
	if shadow:
		sb.shadow_color = Color(0, 0, 0, 0.55)
		sb.shadow_size = 8
		sb.shadow_offset = Vector2(0, 3)
	return sb


static func panel_gold() -> StyleBoxFlat:
	var sb := panel(PANEL_BG, GOLD_DIM, 2, R + 2)
	sb.content_margin_left = PAD + 4
	sb.content_margin_right = PAD + 4
	sb.content_margin_top = PAD + 4
	sb.content_margin_bottom = PAD + 4
	return sb


static func flat(bg: Color, edge: Color = Color(0, 0, 0, 0), border: int = 0,
		radius: int = R) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = edge
	sb.set_border_width_all(border)
	sb.set_corner_radius_all(radius)
	return sb


static func empty_box() -> StyleBoxEmpty:
	return StyleBoxEmpty.new()


# --- Buttons ---------------------------------------------------------------
static func button_normal() -> StyleBoxFlat:
	var sb := flat(PANEL_BG_2, PANEL_EDGE, 1, R)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 9
	sb.content_margin_bottom = 9
	return sb


static func button_hover() -> StyleBoxFlat:
	var sb := flat(Color("#2a2244"), GOLD_DIM, 1, R)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 9
	sb.content_margin_bottom = 9
	return sb


static func button_pressed() -> StyleBoxFlat:
	var sb := flat(Color("#3a2f5c"), GOLD, 2, R)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 9
	sb.content_margin_bottom = 9
	return sb


static func button_danger() -> StyleBoxFlat:
	var sb := flat(Color("#3a1620"), Color("#a03a44"), 1, R)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 9
	sb.content_margin_bottom = 9
	return sb


# --- Bar styling -----------------------------------------------------------
static func bar_bg() -> StyleBoxFlat:
	return flat(Color(0, 0, 0, 0.65), Color(0, 0, 0, 0.0), 0, 4)


static func bar_fill(colour: Color) -> StyleBoxFlat:
	var sb := flat(colour, Color(1, 1, 1, 0.16), 1, 4)
	return sb


static func bar_fill_gradient(a: Color, b: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = a
	sb.border_color = Color(1, 1, 1, 0.18)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	sb.corner_detail = 6
	return sb


# --- Full theme for the app ------------------------------------------------
static func build() -> Theme:
	var t := Theme.new()

	var f_ui := font_ui()
	var f_title := font_title()
	var f_pixel := font_pixel()

	t.default_font = f_ui
	t.default_font_size = 14

	# Label
	t.set_font("font", "Label", f_ui)
	t.set_font_size("font_size", "Label", 14)
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.85))
	t.set_constant("outline_size", "Label", 3)

	# RichTextLabel
	t.set_font("normal_font", "RichTextLabel", f_ui)
	t.set_font("bold_font", "RichTextLabel", f_title)
	t.set_font_size("normal_font_size", "RichTextLabel", 14)
	t.set_color("default_color", "RichTextLabel", TEXT)

	# Button
	t.set_font("font", "Button", f_ui)
	t.set_font_size("font_size", "Button", 14)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", GOLD_BRIGHT)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_focus_color", "Button", GOLD_BRIGHT)
	t.set_color("font_disabled_color", "Button", TEXT_FAINT)
	t.set_color("font_outline_color", "Button", Color(0, 0, 0, 0.8))
	t.set_constant("outline_size", "Button", 2)
	t.set_stylebox("normal", "Button", button_normal())
	t.set_stylebox("hover", "Button", button_hover())
	t.set_stylebox("pressed", "Button", button_pressed())
	t.set_stylebox("focus", "Button", button_hover())
	t.set_stylebox("disabled", "Button", flat(Color(0, 0, 0, 0.3), PANEL_EDGE, 1, R))

	# Panel
	t.set_stylebox("panel", "Panel", panel())
	t.set_stylebox("panel", "PanelContainer", panel())

	# ProgressBar
	t.set_stylebox("background", "ProgressBar", bar_bg())
	t.set_stylebox("fill", "ProgressBar", bar_fill(HP_RED))
	t.set_color("font_color", "ProgressBar", TEXT)

	# CheckBox / CheckButton
	t.set_font("font", "CheckBox", f_ui)
	t.set_font_size("font_size", "CheckBox", 13)
	t.set_color("font_color", "CheckBox", TEXT)
	t.set_color("font_hover_color", "CheckBox", GOLD_BRIGHT)
	t.set_stylebox("normal", "CheckBox", empty_box())
	t.set_stylebox("hover", "CheckBox", empty_box())
	t.set_stylebox("pressed", "CheckBox", empty_box())
	t.set_stylebox("focus", "CheckBox", empty_box())

	t.set_font("font", "CheckButton", f_ui)
	t.set_font_size("font_size", "CheckButton", 13)
	t.set_color("font_color", "CheckButton", TEXT)
	t.set_color("font_hover_color", "CheckButton", GOLD_BRIGHT)

	# Slider
	t.set_stylebox("slider", "HSlider", flat(Color(0, 0, 0, 0.6), PANEL_EDGE, 1, 4))
	t.set_stylebox("grabber_area", "HSlider", flat(GOLD_DIM, Color(0, 0, 0, 0), 0, 4))
	t.set_stylebox("grabber_area_highlight", "HSlider", flat(GOLD, Color(0, 0, 0, 0), 0, 4))

	# ScrollContainer / VScrollBar
	t.set_stylebox("panel", "ScrollContainer", flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0))
	t.set_stylebox("scroll", "VScrollBar", flat(Color(0, 0, 0, 0.4), Color(0, 0, 0, 0), 0, 4))
	t.set_stylebox("grabber", "VScrollBar", flat(PANEL_EDGE, Color(0, 0, 0, 0), 0, 4))
	t.set_stylebox("grabber_highlight", "VScrollBar", flat(GOLD_DIM, Color(0, 0, 0, 0), 0, 4))

	# LineEdit
	t.set_stylebox("normal", "LineEdit", flat(Color(0, 0, 0, 0.5), PANEL_EDGE, 1, R))
	t.set_stylebox("focus", "LineEdit", flat(Color(0, 0, 0, 0.5), GOLD, 1, R))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("caret_color", "LineEdit", GOLD)

	# TabContainer
	t.set_stylebox("panel", "TabContainer", panel())
	t.set_stylebox("tab_selected", "TabContainer", flat(PANEL_BG_2, GOLD_DIM, 1, R))
	t.set_stylebox("tab_unselected", "TabContainer", flat(Color(0, 0, 0, 0.35), PANEL_EDGE, 1, R))
	t.set_stylebox("tab_hovered", "TabContainer", flat(Color("#2a2244"), GOLD_DIM, 1, R))
	t.set_color("font_selected_color", "TabContainer", GOLD_BRIGHT)
	t.set_color("font_unselected_color", "TabContainer", TEXT_DIM)
	t.set_font("font", "TabContainer", f_title)
	t.set_font_size("font_size", "TabContainer", 15)

	# Tooltip
	t.set_stylebox("panel", "TooltipPanel", panel(Color("#0e0b16"), GOLD_DIM, 1, 4))
	t.set_font("font", "TooltipLabel", f_ui)
	t.set_font_size("font_size", "TooltipLabel", 12)
	t.set_color("font_color", "TooltipLabel", TEXT)

	return t


# --- Helpers used by widgets ----------------------------------------------
static func text_with_shadow(lbl: Label, colour: Color, sz: int = 14, outline: int = 3) -> void:
	lbl.add_theme_color_override("font_color", colour)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("outline_size", outline)
	lbl.add_theme_font_size_override("font_size", sz)


static func heading(lbl: Label, sz: int = 16) -> void:
	lbl.add_theme_font_override("font", font_title())
	lbl.add_theme_font_size_override("font_size", sz)
	lbl.add_theme_color_override("font_color", GOLD)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("outline_size", 3)
