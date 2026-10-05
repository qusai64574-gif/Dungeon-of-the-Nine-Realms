class_name Hud
extends CanvasLayer
## The heads-up display.
##
## Layout follows the conventions from the UI research: persistent info pinned
## to the edges (vitals bottom-left, run info top-left, minimap top-right),
## the centre kept clear, and every glyph carrying its own contrast guarantee.

var level: Level = null

# --- nodes -----------------------------------------------------------------
var root: Control
var vignette: TextureRect
var hurt_flash: ColorRect
var depth_label: Label
var biome_label: Label
var depth_icon: TextureRect

var hp_bar: ProgressBar
var hp_text: Label
var xp_bar: ProgressBar
var level_badge: Label
var heart_icon: TextureRect

var gold_label: Label
var kills_label: Label
var time_label: Label
var enemies_label: Label

var minimap: Control
var boss_box: PanelContainer
var boss_name: Label
var boss_bar: ProgressBar

var toast_box: VBoxContainer
var ability_row: HBoxContainer
var _ability_slots: Array[Dictionary] = []

var _time := 0.0
var _pulse := 0.0
var _hurt_alpha := 0.0
var _toasts: Array = []

const TOAST_LIFE := 3.2


func _ready() -> void:
	layer = 10
	_build()
	EventBus.hp_changed.connect(_on_hp)
	EventBus.xp_changed.connect(_on_xp)
	EventBus.gold_changed.connect(_on_gold)
	EventBus.player_leveled.connect(_on_level)
	EventBus.floor_changed.connect(_on_floor)
	EventBus.toast.connect(_on_toast)
	EventBus.player_damaged.connect(_on_damaged)
	EventBus.enemy_killed.connect(_on_kill)
	EventBus.boss_spawned.connect(_on_boss)
	EventBus.boss_hp_changed.connect(_on_boss_hp)
	EventBus.stats_changed.connect(_refresh_stats)
	EventBus.run_started.connect(func(): _time = 0.0)
	_on_hp(GameState.hp, GameState.max_hp)
	_on_xp(GameState.xp, GameState.xp_needed, GameState.level)
	_on_gold(GameState.gold)
	_on_floor(GameState.depth)
	_refresh_stats()


# ---------------------------------------------------------------------------
# Construction
# ---------------------------------------------------------------------------
func _build() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- vignette + damage flash (drawn under everything else) ------------
	vignette = TextureRect.new()
	vignette.texture = _vignette_texture()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.modulate = Color(1, 1, 1, 0.45)
	root.add_child(vignette)

	hurt_flash = ColorRect.new()
	hurt_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	hurt_flash.color = Color(0.85, 0.08, 0.12, 0.0)
	hurt_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hurt_flash)

	_build_top_left()
	_build_top_right()
	_build_bottom_left()
	_build_bottom_right()
	_build_bottom_center()
	_build_boss()


func _build_top_left() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel(Color(0.07, 0.055, 0.11, 0.86), UITheme.GOLD_DIM, 1, 6))
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(16, 16)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	panel.add_child(hb)

	depth_icon = TextureRect.new()
	depth_icon.texture = load(Assets.UI_SKULL)
	depth_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	depth_icon.custom_minimum_size = Vector2(30, 30)
	depth_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	depth_icon.modulate = UITheme.GOLD
	hb.add_child(depth_icon)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	hb.add_child(vb)

	depth_label = BleedingLabel.new()
	depth_label.text = "DEPTH 1"
	UITheme.heading(depth_label, 20)
	vb.add_child(depth_label)

	biome_label = BleedingLabel.new()
	biome_label.text = "Stone Halls"
	UITheme.text_with_shadow(biome_label, UITheme.TEXT_DIM, 12, 2)
	vb.add_child(biome_label)


func _build_top_right() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel(Color(0.07, 0.055, 0.11, 0.86), UITheme.GOLD_DIM, 1, 6))
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.position = Vector2(-16, 16)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	panel.add_child(vb)

	var hdr := BleedingLabel.new()
	hdr.text = "MAP"
	UITheme.heading(hdr, 12)
	vb.add_child(hdr)

	minimap = Control.new()
	minimap.custom_minimum_size = Vector2(184, 122)
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	minimap.draw.connect(_draw_minimap)
	vb.add_child(minimap)


func _build_bottom_left() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel(Color(0.07, 0.055, 0.11, 0.86), UITheme.GOLD_DIM, 1, 6))
	panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	panel.position = Vector2(16, -16)
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	panel.add_child(hb)

	heart_icon = TextureRect.new()
	heart_icon.texture = load(Assets.HEART_FULL)
	heart_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	heart_icon.custom_minimum_size = Vector2(44, 44)
	heart_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hb.add_child(heart_icon)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	vb.custom_minimum_size = Vector2(300, 0)
	hb.add_child(vb)

	# HP row
	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 8)
	vb.add_child(hp_row)
	var hp_tag := BleedingLabel.new(); hp_tag.text = "HP"
	UITheme.text_with_shadow(hp_tag, UITheme.HP_RED, 12, 2)
	hp_tag.custom_minimum_size = Vector2(26, 0)
	hp_row.add_child(hp_tag)
	hp_bar = ProgressBar.new()
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(268, 20)
	hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_bar.add_theme_stylebox_override("background", UITheme.bar_bg())
	hp_bar.add_theme_stylebox_override("fill", UITheme.bar_fill(UITheme.HP_RED))
	hp_row.add_child(hp_bar)
	hp_text = BleedingLabel.new(); hp_text.text = "100 / 100"
	UITheme.text_with_shadow(hp_text, UITheme.TEXT, 12, 2)
	hp_text.custom_minimum_size = Vector2(84, 0)
	hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hp_row.add_child(hp_text)

	# XP row
	var xp_row := HBoxContainer.new()
	xp_row.add_theme_constant_override("separation", 8)
	vb.add_child(xp_row)
	var xp_tag := BleedingLabel.new(); xp_tag.text = "XP"
	UITheme.text_with_shadow(xp_tag, UITheme.XP_CYAN, 12, 2)
	xp_tag.custom_minimum_size = Vector2(26, 0)
	xp_row.add_child(xp_tag)
	xp_bar = ProgressBar.new()
	xp_bar.show_percentage = false
	xp_bar.custom_minimum_size = Vector2(268, 10)
	xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	xp_bar.add_theme_stylebox_override("background", UITheme.bar_bg())
	xp_bar.add_theme_stylebox_override("fill", UITheme.bar_fill(UITheme.XP_BLUE))
	xp_row.add_child(xp_bar)
	level_badge = BleedingLabel.new(); level_badge.text = "Lv 1"
	UITheme.text_with_shadow(level_badge, UITheme.GOLD, 12, 2)
	level_badge.custom_minimum_size = Vector2(84, 0)
	level_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	xp_row.add_child(level_badge)


func _build_bottom_right() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel(Color(0.07, 0.055, 0.11, 0.86), UITheme.GOLD_DIM, 1, 6))
	panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	panel.position = Vector2(-16, -16)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	panel.add_child(vb)

	gold_label = _stat_row(vb, Assets.item("gold"), "0", UITheme.GOLD_COIN)
	kills_label = _stat_row(vb, Assets.UI_SKULL, "0", UITheme.TEXT)
	enemies_label = _stat_row(vb, Assets.emote("alert"), "0", Color(1.0, 0.55, 0.55))
	time_label = _stat_row(vb, Assets.item("scroll"), "0:00", UITheme.TEXT_DIM)


func _stat_row(parent: Node, icon_path: String, initial: String, colour: Color) -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var ic := TextureRect.new()
	ic.texture = load(icon_path)
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ic.custom_minimum_size = Vector2(18, 18)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(ic)
	var lbl := BleedingLabel.new()
	lbl.text = initial
	UITheme.text_with_shadow(lbl, colour, 13, 2)
	lbl.custom_minimum_size = Vector2(74, 0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(lbl)
	return lbl


func _build_bottom_center() -> void:
	var holder := VBoxContainer.new()
	holder.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	holder.position = Vector2(0, -22)
	holder.grow_horizontal = Control.GROW_DIRECTION_BOTH
	holder.grow_vertical = Control.GROW_DIRECTION_BEGIN
	holder.alignment = BoxContainer.ALIGNMENT_END
	holder.add_theme_constant_override("separation", 8)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(holder)

	toast_box = VBoxContainer.new()
	toast_box.alignment = BoxContainer.ALIGNMENT_END
	toast_box.add_theme_constant_override("separation", 4)
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(toast_box)

	ability_row = HBoxContainer.new()
	ability_row.alignment = BoxContainer.ALIGNMENT_CENTER
	ability_row.add_theme_constant_override("separation", 10)
	ability_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(ability_row)

	_add_ability("melee", "LMB", "Slash", UITheme.HP_LOW)
	_add_ability("fireball", "RMB", "Bolt", UITheme.GOLD)


func _add_ability(icon_id: String, key: String, name: String, accent: Color) -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.panel(Color(0.07, 0.055, 0.11, 0.9), accent.darkened(0.35), 1, 6))
	ability_row.add_child(p)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	p.add_child(hb)

	var ic := TextureRect.new()
	ic.texture = load(Assets.skill_icon(icon_id))
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ic.custom_minimum_size = Vector2(26, 26)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hb.add_child(ic)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	hb.add_child(vb)
	var nm := BleedingLabel.new(); nm.text = name
	UITheme.text_with_shadow(nm, accent, 12, 2)
	vb.add_child(nm)
	var kd := BleedingLabel.new(); kd.text = key
	UITheme.text_with_shadow(kd, UITheme.TEXT_FAINT, 10, 2)
	vb.add_child(kd)

	_ability_slots.append({"panel": p, "accent": accent, "cooldown": 0.0, "base": p.get_theme_stylebox("panel")})


func _build_boss() -> void:
	boss_box = PanelContainer.new()
	boss_box.add_theme_stylebox_override("panel", UITheme.panel(Color(0.12, 0.03, 0.06, 0.92), UITheme.DANGER, 2, 6))
	boss_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_box.position = Vector2(0, 22)
	boss_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	boss_box.custom_minimum_size = Vector2(560, 0)
	boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_box.visible = false
	root.add_child(boss_box)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	boss_box.add_child(vb)

	boss_name = BleedingLabel.new()
	boss_name.text = "BOSS"
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.heading(boss_name, 17)
	boss_name.add_theme_color_override("font_color", Color(1.0, 0.55, 0.55))
	vb.add_child(boss_name)

	boss_bar = ProgressBar.new()
	boss_bar.show_percentage = false
	boss_bar.custom_minimum_size = Vector2(540, 16)
	boss_bar.max_value = 100.0
	boss_bar.value = 100.0
	boss_bar.add_theme_stylebox_override("background", UITheme.bar_bg())
	boss_bar.add_theme_stylebox_override("fill", UITheme.bar_fill(UITheme.DANGER))
	vb.add_child(boss_bar)


# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------
func _on_hp(cur: int, mx: int) -> void:
	if hp_bar == null:
		return
	hp_bar.max_value = maxf(1.0, float(mx))
	hp_bar.value = float(cur)
	hp_text.text = "%d / %d" % [cur, mx]
	var frac := float(cur) / maxf(1.0, float(mx))
	var col := UITheme.HP_RED
	if frac < 0.25:
		col = UITheme.HP_LOW
	elif frac < 0.5:
		col = Color("#e8863d")
	hp_bar.add_theme_stylebox_override("fill", UITheme.bar_fill(col))
	heart_icon.texture = load(Assets.HEART_FULL if frac > 0.66 else
		(Assets.HEART_HALF if frac > 0.33 else Assets.HEART_EMPTY))


func _on_xp(cur: int, need: int, lv: int) -> void:
	if xp_bar == null:
		return
	xp_bar.max_value = maxf(1.0, float(need))
	xp_bar.value = float(cur)
	level_badge.text = "Lv %d" % lv


func _on_gold(amount: int) -> void:
	if gold_label:
		gold_label.text = str(amount)


func _on_level(lv: int) -> void:
	if level_badge:
		level_badge.text = "Lv %d" % lv


func _on_floor(depth: int) -> void:
	if depth_label:
		depth_label.text = "DEPTH %d" % depth
	if biome_label:
		biome_label.text = Assets.BIOME_NAMES.get(GameState.biome if GameState.biome != "auto" else "default", "")
		if level:
			biome_label.text = Assets.BIOME_NAMES.get(level.biome, "")
			biome_label.add_theme_color_override("font_color",
				Assets.BIOME_ACCENT.get(level.biome, UITheme.TEXT_DIM))


func _on_kill(_n: String, _p: Vector2, _x: int) -> void:
	if kills_label:
		kills_label.text = str(GameState.kills)


func _on_damaged(_amount: int, _src: Vector2) -> void:
	_hurt_alpha = 0.42


func _on_boss(boss: Node, title: String, hp: int, max_hp: int) -> void:
	if boss_box == null:
		return
	boss_box.visible = true
	boss_name.text = title
	boss_bar.max_value = maxf(1.0, float(max_hp))
	boss_bar.value = float(hp)
	# auto-hide when the boss dies
	if boss is Node:
		boss.tree_exiting.connect(func(): if boss_box: boss_box.visible = false)


func _on_boss_hp(hp: int, max_hp: int) -> void:
	if boss_box == null or not boss_box.visible:
		return
	boss_bar.max_value = maxf(1.0, float(max_hp))
	boss_bar.value = float(hp)


func _refresh_stats() -> void:
	pass


func _on_toast(text: String, colour: Color) -> void:
	_push_toast(text, colour)


# ---------------------------------------------------------------------------
# Toasts
# ---------------------------------------------------------------------------
func _push_toast(text: String, colour: Color) -> void:
	if toast_box == null:
		return
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.panel(Color(0.05, 0.04, 0.09, 0.88), colour.darkened(0.4), 1, 5))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lbl := BleedingLabel.new()
	lbl.text = text
	UITheme.text_with_shadow(lbl, colour, 13, 2)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(lbl)
	toast_box.add_child(p)
	var entry := {"node": p, "t": TOAST_LIFE}
	_toasts.append(entry)
	# cap the stack
	while _toasts.size() > 5:
		var old: Dictionary = _toasts.pop_front()
		if is_instance_valid(old["node"]):
			old["node"].queue_free()
	# animate in
	p.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.14)


func _process_toasts(delta: float) -> void:
	for i in range(_toasts.size() - 1, -1, -1):
		var entry: Dictionary = _toasts[i]
		entry["t"] = float(entry["t"]) - delta
		var node: Node = entry["node"]
		if not is_instance_valid(node):
			_toasts.remove_at(i)
			continue
		if float(entry["t"]) < 0.6:
			node.modulate.a = clampf(float(entry["t"]) / 0.6, 0.0, 1.0)
		if float(entry["t"]) <= 0.0:
			node.queue_free()
			_toasts.remove_at(i)


# ---------------------------------------------------------------------------
# Minimap
# ---------------------------------------------------------------------------
func _draw_minimap() -> void:
	if level == null or level.grid.size() == 0 or minimap == null:
		return
	var size := minimap.size
	var gw: int = level.GW
	var gh: int = level.GH
	var scale: float = minf(size.x / float(gw), size.y / float(gh))
	var ox: float = (size.x - gw * scale) * 0.5
	var oy: float = (size.y - gh * scale) * 0.5

	minimap.draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.55), true)

	for y in gh:
		for x in gw:
			if not level.explored[y][x]:
				continue
			var cell: int = level.grid[y][x]
			var col: Color
			if not level.vis_map[y][x]:
				col = Color(0.24, 0.22, 0.34, 0.9) if cell == DungeonGen.Cell.WALL else Color(0.16, 0.15, 0.24, 0.9)
			else:
				col = Color(0.55, 0.58, 0.75) if cell == DungeonGen.Cell.WALL else Color(0.34, 0.32, 0.5)
			if cell == DungeonGen.Cell.STAIRS:
				col = Color(1.0, 0.85, 0.35)
			minimap.draw_rect(Rect2(ox + x * scale, oy + y * scale, maxf(1.0, scale), maxf(1.0, scale)), col, true)

	# enemies in sight
	if level.vis_map.size() > 0:
		for e in level.entities.get_children():
			if e is Enemy and not e.is_dead:
				var ec: Vector2i = level.cell_of(e.global_position)
				if ec.y >= 0 and ec.y < gh and ec.x >= 0 and ec.x < gw and level.vis_map[ec.y][ec.x]:
					var col := Color(1.0, 0.35, 0.35) if e.is_boss else Color(1.0, 0.6, 0.45)
					minimap.draw_circle(Vector2(ox + (ec.x + 0.5) * scale, oy + (ec.y + 0.5) * scale),
						maxf(1.5, scale * 0.7), col)

	# player
	if level.player and not level.player.is_dead:
		var pc: Vector2i = level.cell_of(level.player.global_position)
		var pp := Vector2(ox + (pc.x + 0.5) * scale, oy + (pc.y + 0.5) * scale)
		minimap.draw_circle(pp, maxf(2.2, scale * 1.0), Color(0.45, 1.0, 0.6))


# ---------------------------------------------------------------------------
# Per-frame
# ---------------------------------------------------------------------------
func _process(delta: float) -> void:
	_time += delta
	_pulse += delta

	# timer
	if time_label:
		var m := int(_time) / 60
		var s := int(_time) % 60
		time_label.text = "%d:%02d" % [m, s]

	# enemy counter
	if enemies_label and level:
		var n := 0
		for e in level.entities.get_children():
			if e is Enemy and not e.is_dead:
				n += 1
		enemies_label.text = str(n)

	# hurt flash
	if _hurt_alpha > 0.0:
		_hurt_alpha = maxf(0.0, _hurt_alpha - delta * 1.6)
		hurt_flash.color = Color(0.85, 0.08, 0.12, _hurt_alpha)

	# low-health pulse on the vignette
	if GameState.hp > 0 and float(GameState.hp) / maxf(1.0, float(GameState.max_hp)) < 0.3:
		var beat := 0.55 + 0.45 * sin(_pulse * 5.0)
		vignette.modulate = Color(1.0, 0.45, 0.45, 0.7 + 0.3 * beat)
	else:
		vignette.modulate = vignette.modulate.lerp(Color(1, 1, 1, 0.85), clampf(delta * 4.0, 0.0, 1.0))

	_process_toasts(delta)
	if minimap:
		minimap.queue_redraw()


func _vignette_texture() -> Texture2D:
	var s := 256
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	var c := Vector2(s * 0.5, s * 0.5)
	var maxd := c.length()
	for y in s:
		for x in s:
			var d := Vector2(x - c.x, y - c.y).length() / maxd
			var a := clampf(pow(d, 2.6) * 0.85, 0.0, 1.0)
			img.set_pixel(x, y, Color(0, 0, 0, a))
	return ImageTexture.create_from_image(img)
