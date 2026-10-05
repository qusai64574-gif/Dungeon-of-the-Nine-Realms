class_name AdminPanel
extends CanvasLayer
## The Admin Console.
##
## Toggle with the backslash key ( \ ). Rebindable via the "admin_panel"
## input action. While open, gameplay input is suppressed.

const NAV_W := 214

var is_open: bool = false
var level: Level = null

var _dim: ColorRect
var _panel: PanelContainer
var _nav: VBoxContainer
var _content: Control
var _content_scroll: ScrollContainer
var _title: Label
var _status: Label
var _pages: Dictionary = {}      # id -> Control
var _nav_buttons: Dictionary = {}
var _current := ""
var _live: Dictionary = {}       # live-updating labels

# category definitions
const CATS := [
	{"id": "vitals", "name": "Player", "icon": "melee"},
	{"id": "power", "name": "Power", "icon": "fireball"},
	{"id": "enemies", "name": "Enemies", "icon": "alert"},
	{"id": "spawn", "name": "Spawner", "icon": "sparkle"},
	{"id": "world", "name": "World", "icon": "map"},
	{"id": "bestiary", "name": "Bestiary", "icon": "skull"},
	{"id": "telemetry", "name": "Telemetry", "icon": "bars"},
	{"id": "system", "name": "System", "icon": "settings"},
]

const ITEM_LIST := [
	"health_potion", "mana_potion", "antidote", "gold", "gem", "heart", "fairy",
	"sword", "fire_sword", "ice_sword", "lightning_sword", "rainbow_sword", "bow",
	"armor", "helmet", "shield", "ring", "necklace", "scroll", "spell_book",
	"gold_key", "small_key", "big_key", "chest", "torch", "vase", "cauldron", "stone",
]


func _ready() -> void:
	layer = 40
	_build()
	visible = false
	EventBus.admin_toggled.connect(_on_admin_toggled)


func toggle() -> void:
	set_open(not is_open)


func set_open(v: bool) -> void:
	is_open = v
	visible = v
	GameState.admin_open = v
	get_tree().paused = false          # we keep the world alive, just gate input
	EventBus.admin_toggled.emit(v)
	if v:
		_refresh_all()


func _on_admin_toggled(v: bool) -> void:
	if v != is_open:
		set_open(v)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("admin_panel"):
		toggle()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and is_open:
		set_open(false)
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------------------
# Construction
# ---------------------------------------------------------------------------
func _build() -> void:
	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0.02, 0.015, 0.04, 0.72)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)

	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", DarkStyle.panel())
	_panel.custom_minimum_size = Vector2(1040, 660)
	centre.add_child(_panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	_panel.add_child(outer)

	# ---- title bar -------------------------------------------------------
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	outer.add_child(bar)

	var glyph := TextureRect.new()
	glyph.texture = load(Assets.UI_KING)
	glyph.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	glyph.custom_minimum_size = Vector2(34, 34)
	glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glyph.modulate = DarkStyle.INK
	bar.add_child(glyph)

	_title = BleedingLabel.new()
	_title.text = "ADMIN  CONSOLE"
	DarkStyle.heading(_title, 44)
	_title.set_blood_colour(DarkStyle.INK)
	_title.set_streak_colour(Color("#4a0000"))
	bar.add_child(_title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)

	_status = BleedingLabel.new()
	_status.text = "GOD  OFF"
	DarkStyle.body(_status, 12, Color("#8a7358"))
	bar.add_child(_status)

	var close_hint := BleedingLabel.new()
	close_hint.text = "[ Esc ]"
	DarkStyle.body(close_hint, 12, Color("#6b5138"))
	bar.add_child(close_hint)

	outer.add_child(_divider())

	# ---- body: nav rail + content ---------------------------------------
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(body)

	var nav_panel := PanelContainer.new()
	nav_panel.add_theme_stylebox_override("panel", DarkStyle.well())
	nav_panel.custom_minimum_size = Vector2(NAV_W, 0)
	body.add_child(nav_panel)

	_nav = VBoxContainer.new()
	_nav.add_theme_constant_override("separation", 4)
	nav_panel.add_child(_nav)

	for c in CATS:
		var b := Button.new()
		b.text = "   " + String(c["name"])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(NAV_W - 26, 34)
		b.add_theme_font_override("font", DarkStyle.font_display())
		b.add_theme_font_size_override("font_size", 19)
		b.add_theme_color_override("font_outline_color", DarkStyle.CREAM)
		b.add_theme_constant_override("outline_size", 2)
		b.pressed.connect(_show_page.bind(String(c["id"])))
		_nav.add_child(b)
		_nav_buttons[String(c["id"])] = b

	var content_panel := PanelContainer.new()
	content_panel.add_theme_stylebox_override("panel", DarkStyle.well())
	content_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(content_panel)

	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_panel.add_child(_content_scroll)

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 10)
	_content_scroll.add_child(_content)

	# ---- build pages -----------------------------------------------------
	_page_vitals()
	_page_power()
	_page_enemies()
	_page_spawn()
	_page_world()
	_page_bestiary()
	_page_telemetry()
	_page_system()

	_show_page("vitals")


func _divider() -> HSeparator:
	var d := HSeparator.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = DarkStyle.GOLD_DEEP
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	d.add_theme_stylebox_override("separator", sb)
	return d


func _show_page(id: String) -> void:
	_current = id
	for pid in _pages:
		_pages[pid].visible = (pid == id)
	for nid in _nav_buttons:
		var b: Button = _nav_buttons[nid]
		if nid == id:
			b.add_theme_stylebox_override("normal", DarkStyle.button_pressed())
			b.add_theme_color_override("font_color", DarkStyle.OUTLINE)
		else:
			b.add_theme_stylebox_override("normal", DarkStyle.button_normal())
			b.add_theme_color_override("font_color", Color("#6b5138"))
	_refresh_all()


func _new_page(id: String) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(v)
	_pages[id] = v
	return v


func _section(parent: Node, text: String) -> void:
	var s := BleedingLabel.new()
	s.text = text.to_upper()
	s.add_theme_font_override("font", DarkStyle.font_display())
	s.add_theme_font_size_override("font_size", 15)
	s.add_theme_color_override("font_color", DarkStyle.INK)
	s.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	s.add_theme_constant_override("outline_size", 3)
	parent.add_child(s)
	parent.add_child(_divider())


func _grid(cols: int = 3) -> GridContainer:
	var g := GridContainer.new()
	g.columns = cols
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return g


# --- reusable widgets ------------------------------------------------------
func _toggle(parent: Node, label: String, getter: Callable, setter: Callable, tip: String = "") -> CheckButton:
	var cb := CheckButton.new()
	cb.text = label
	cb.button_pressed = bool(getter.call())
	cb.tooltip_text = tip
	cb.add_theme_font_override("font", DarkStyle.font_ui())
	cb.add_theme_font_size_override("font_size", 15)
	cb.add_theme_color_override("font_color", Color("#3a2414"))
	cb.add_theme_color_override("font_hover_color", DarkStyle.INK_BRIGHT)
	cb.add_theme_color_override("font_pressed_color", Color("#3a2414"))
	cb.toggled.connect(func(v: bool):
		setter.call(v)
		EventBus.cheats_changed.emit()
		_refresh_all())
	parent.add_child(cb)
	return cb


func _slider(parent: Node, label: String, mn: float, mx: float, step: float,
		getter: Callable, setter: Callable) -> void:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(row)

	var head := HBoxContainer.new()
	row.add_child(head)
	var l := BleedingLabel.new(); l.text = label
	DarkStyle.body(l, 13, Color("#4a3320"))
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(l)
	var val := BleedingLabel.new()
	val.text = "%.2f" % float(getter.call())
	DarkStyle.body(val, 13, DarkStyle.INK)
	head.add_child(val)

	var sl := HSlider.new()
	sl.min_value = mn
	sl.max_value = mx
	sl.step = step
	sl.value = float(getter.call())
	sl.custom_minimum_size = Vector2(0, 18)
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.value_changed.connect(func(v: float):
		setter.call(v)
		val.text = "%.2f" % v
		EventBus.cheats_changed.emit())
	row.add_child(sl)


func _action_button(parent: Node, text: String, cb: Callable, danger: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 38)
	b.add_theme_stylebox_override("normal", DarkStyle.button_normal())
	if danger:
		b.add_theme_stylebox_override("normal", DarkStyle.block(Color("#e8b9a0"), 5, 4, Color("#7a1d18")))
		b.add_theme_color_override("font_color", Color("#7a1d18"))
	b.add_theme_font_override("font", DarkStyle.font_display())
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", DarkStyle.INK)
	b.add_theme_color_override("font_hover_color", DarkStyle.INK_BRIGHT)
	b.add_theme_color_override("font_pressed_color", DarkStyle.OUTLINE)
	b.add_theme_color_override("font_outline_color", DarkStyle.CREAM)
	b.add_theme_constant_override("outline_size", 2)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _row_label(parent: Node, text: String, colour: Color = Color("#4a3320")) -> Label:
	var l := BleedingLabel.new()
	l.text = text
	DarkStyle.body(l, 13, colour)
	parent.add_child(l)
	return l


# ---------------------------------------------------------------------------
# Pages
# ---------------------------------------------------------------------------
func _page_vitals() -> void:
	var p := _new_page("vitals")
	_section(p, "Survivability")

	var g := _grid(2)
	p.add_child(g)
	_toggle(g, "God mode  (invulnerable)", func(): return GameState.god_mode,
		func(v): GameState.god_mode = v, "Nothing can hurt you.")
	_toggle(g, "Auto-heal  (always full)", func(): return GameState.auto_heal,
		func(v): GameState.auto_heal = v)
	_toggle(g, "Infinite gold", func(): return GameState.infinite_gold,
		func(v): GameState.infinite_gold = v)
	_toggle(g, "Loot magnet  (global pickup)", func(): return GameState.magnet_all,
		func(v): GameState.magnet_all = v)

	_section(p, "Vitals")
	var g2 := _grid(2)
	p.add_child(g2)
	_action_button(g2, "Full heal", func(): EventBus.cheat_full_heal.emit(); EventBus.toast_msg("FULL HEAL", Color("#3f7a4a")))
	_action_button(g2, "+100 max HP", func(): GameState.add_max_hp(100); EventBus.toast_msg("+100 MAX HP", Color("#3f7a4a")))
	_action_button(g2, "+1000 gold", func(): GameState.add_gold(1000); EventBus.toast_msg("+1000 GOLD", DarkStyle.GOLD_DEEP))
	_action_button(g2, "+1 level", func(): GameState.add_xp(GameState.xp_needed); EventBus.toast_msg("+1 LEVEL", DarkStyle.INK))
	_action_button(g2, "Heal to full + clear effects", func():
		GameState.hp = GameState.max_hp
		EventBus.hp_changed.emit(GameState.hp, GameState.max_hp)
		EventBus.toast_msg("RESTORED", Color("#3f7a4a")))
	_action_button(g2, "Kill player  (test death)", func():
		GameState.god_mode = false
		GameState.hp = 1
		GameState.take_damage(9999, Vector2.ZERO), true)

	_section(p, "Live vitals")
	var live := _grid(3)
	p.add_child(live)
	_live["hp"] = _row_label(live, "HP: —")
	_live["level"] = _row_label(live, "Level: —")
	_live["gold"] = _row_label(live, "Gold: —")
	_live["damage"] = _row_label(live, "Attack: —")
	_live["armour"] = _row_label(live, "Armour: —")
	_live["crit"] = _row_label(live, "Crit: —")
	_live["lifesteal"] = _row_label(live, "Lifesteal: —")
	_live["speed"] = _row_label(live, "Move speed: —")
	_live["kills"] = _row_label(live, "Kills: —")


func _page_power() -> void:
	var p := _new_page("power")
	_section(p, "Damage")
	_toggle(p, "One-hit kill  (everything dies instantly)", func(): return GameState.one_hit_kill,
		func(v): GameState.one_hit_kill = v)
	_slider(p, "Damage multiplier", 0.25, 50.0, 0.25,
		func(): return GameState.damage_mult, func(v): GameState.damage_mult = v)
	_slider(p, "Crit chance", 0.0, 1.0, 0.01,
		func(): return GameState.crit_chance, func(v): GameState.crit_chance = v)
	_slider(p, "Crit multiplier", 1.0, 20.0, 0.5,
		func(): return GameState.crit_mult, func(v): GameState.crit_mult = v)
	_slider(p, "Lifesteal", 0.0, 1.0, 0.01,
		func(): return GameState.lifesteal, func(v): GameState.lifesteal = v)
	_slider(p, "Armour", 0.0, 500.0, 1.0,
		func(): return float(GameState.armour), func(v): GameState.armour = int(v))

	_section(p, "Mobility & firepower")
	_toggle(p, "No cooldown  (spam everything)", func(): return GameState.no_cooldown,
		func(v): GameState.no_cooldown = v)
	_slider(p, "Move speed multiplier", 0.25, 6.0, 0.05,
		func(): return GameState.speed_mult, func(v): GameState.speed_mult = v)
	_slider(p, "Projectiles per shot", 1.0, 24.0, 1.0,
		func(): return float(GameState.projectile_count), func(v): GameState.projectile_count = int(v))
	_slider(p, "Projectile speed", 120.0, 1600.0, 10.0,
		func(): return GameState.projectile_speed, func(v): GameState.projectile_speed = v)
	_slider(p, "Base attack", 1.0, 400.0, 1.0,
		func(): return float(GameState.base_damage), func(v): GameState.base_damage = int(v))
	_slider(p, "XP multiplier", 0.25, 100.0, 0.25,
		func(): return GameState.xp_mult, func(v): GameState.xp_mult = v)

	_section(p, "Presets")
	var g := _grid(3)
	p.add_child(g)
	_action_button(g, "GOD BUILD", func(): _preset("god"))
	_action_button(g, "GLASS CANNON", func(): _preset("glass"))
	_action_button(g, "SPEEDRUNNER", func(): _preset("speed"))
	_action_button(g, "NUKE MODE", func(): _preset("nuke"))
	_action_button(g, "Reset cheats", func(): _preset("reset"), true)


func _preset(kind: String) -> void:
	match kind:
		"god":
			GameState.god_mode = true
			GameState.one_hit_kill = true
			GameState.infinite_gold = true
			GameState.no_cooldown = true
			GameState.auto_heal = true
			GameState.magnet_all = true
			GameState.damage_mult = 25.0
			GameState.speed_mult = 2.5
			GameState.xp_mult = 20.0
			GameState.projectile_count = 8
		"glass":
			GameState.god_mode = false
			GameState.one_hit_kill = true
			GameState.damage_mult = 50.0
			GameState.speed_mult = 1.6
			GameState.max_hp = 20
			GameState.hp = 20
			GameState.armour = 0
		"speed":
			GameState.speed_mult = 4.0
			GameState.no_cooldown = true
			GameState.god_mode = true
			GameState.damage_mult = 5.0
		"nuke":
			GameState.damage_mult = 50.0
			GameState.projectile_count = 24
			GameState.no_cooldown = true
			GameState.one_hit_kill = true
		"reset":
			GameState.god_mode = false
			GameState.one_hit_kill = false
			GameState.infinite_gold = false
			GameState.no_cooldown = false
			GameState.auto_heal = false
			GameState.magnet_all = false
			GameState.freeze_enemies = false
			GameState.speed_mult = 1.0
			GameState.damage_mult = 1.0
			GameState.xp_mult = 1.0
			GameState.enemy_speed_mult = 1.0
			GameState.projectile_count = 1
			GameState.map_revealed = false
	EventBus.cheats_changed.emit()
	EventBus.toast_msg("PRESET: " + kind.to_upper(), DarkStyle.ACCENTS["magic"])
	_refresh_all()


func _page_enemies() -> void:
	var p := _new_page("enemies")
	_section(p, "Monster control")
	_toggle(p, "Freeze all monsters", func(): return GameState.freeze_enemies,
		func(v): GameState.freeze_enemies = v, "Monsters stop dead.")
	_slider(p, "Monster speed multiplier", 0.0, 4.0, 0.05,
		func(): return GameState.enemy_speed_mult, func(v): GameState.enemy_speed_mult = v)
	_row_label(p, "Tip: monsters are tuned slow by default (18–34 px/s).", Color("#8a7358"))

	_section(p, "Wipe")
	var g := _grid(2)
	p.add_child(g)
	_action_button(g, "Kill every monster", func(): EventBus.cheat_kill_all.emit(), true)
	_action_button(g, "NUKE  (kill + VFX)", func(): EventBus.cheat_nuke.emit(), true)

	_section(p, "Live monster census")
	var live := _grid(2)
	p.add_child(live)
	_live["census"] = _row_label(live, "—")
	_live["census_total"] = _row_label(live, "—")


func _page_spawn() -> void:
	var p := _new_page("spawn")
	_section(p, "Spawn monster")

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	p.add_child(row)
	var pick := OptionButton.new()
	pick.custom_minimum_size = Vector2(220, 34)
	for id in EnemyDB.TYPES:
		pick.add_item("%s  (%s)" % [String(EnemyDB.TYPES[id]["name"]), id])
	pick.selected = 0
	row.add_child(pick)

	var count := SpinBox.new()
	count.min_value = 1
	count.max_value = 50
	count.value = 5
	count.custom_minimum_size = Vector2(90, 34)
	row.add_child(count)

	var ids: Array = EnemyDB.TYPES.keys()
	_action_button(row, "Spawn", func():
		var idx := pick.selected
		var id := String(ids[idx])
		EventBus.cheat_spawn_enemy.emit(id, int(count.value)))

	_action_button(p, "Spawn a full wave  (10 random)", func():
		for _i in 10:
			EventBus.cheat_spawn_enemy.emit(String(ids[randi() % ids.size()]), 1))

	_action_button(p, "Spawn a boss here", func():
		var boss := EnemyDB.boss_for_depth(GameState.depth)
		var bid := String(boss.get("id", "ogre"))
		EventBus.cheat_spawn_enemy.emit(bid, 1)
		EventBus.toast_msg("BOSS SPAWNED", Color("#a8322a")))

	_section(p, "Spawn item")
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 8)
	p.add_child(row2)
	var ipick := OptionButton.new()
	ipick.custom_minimum_size = Vector2(220, 34)
	for it in ITEM_LIST:
		ipick.add_item(it)
	row2.add_child(ipick)
	var icount := SpinBox.new()
	icount.min_value = 1
	icount.max_value = 99
	icount.value = 1
	icount.custom_minimum_size = Vector2(90, 34)
	row2.add_child(icount)
	_action_button(row2, "Spawn", func():
		EventBus.cheat_spawn_item.emit(ITEM_LIST[ipick.selected], int(icount.value)))

	var g := _grid(3)
	p.add_child(g)
	_action_button(g, "3 treasure chests", func(): EventBus.cheat_spawn_chest.emit())
	_action_button(g, "Every item, x5", func():
		for it in ITEM_LIST:
			EventBus.cheat_spawn_item.emit(it, 5)
		EventBus.toast_msg("EVERYTHING SPAWNED", DarkStyle.INK))
	_action_button(g, "+9999 gold", func(): GameState.add_gold(9999))


func _page_world() -> void:
	var p := _new_page("world")
	_section(p, "Navigation")
	var g := _grid(2)
	p.add_child(g)
	_toggle(g, "Reveal whole map", func(): return GameState.map_revealed,
		func(v):
			GameState.map_revealed = v
			if v: EventBus.cheat_reveal_map.emit())
	_action_button(g, "Teleport to exit", func(): EventBus.cheat_teleport_stairs.emit())
	_action_button(g, "Regenerate this floor", func(): EventBus.request_regenerate.emit())
	_action_button(g, "Descend  (next floor)", func(): EventBus.request_next_floor.emit())

	_section(p, "Depth")
	var drow := HBoxContainer.new()
	drow.add_theme_constant_override("separation", 8)
	p.add_child(drow)
	var spin := SpinBox.new()
	spin.min_value = 1
	spin.max_value = 99
	spin.value = GameState.depth
	spin.custom_minimum_size = Vector2(110, 34)
	drow.add_child(spin)
	_action_button(drow, "Jump to depth", func():
		GameState.depth = int(spin.value) - 1
		EventBus.request_next_floor.emit())
	_action_button(drow, "Depth +10", func():
		GameState.depth += 10
		EventBus.request_next_floor.emit())

	_section(p, "Biome theme")
	var brow := HBoxContainer.new()
	brow.add_theme_constant_override("separation", 8)
	p.add_child(brow)
	var bpick := OptionButton.new()
	bpick.custom_minimum_size = Vector2(200, 34)
	bpick.add_item("auto  (rotate)")
	for b in Assets.BIOMES:
		bpick.add_item("%s  —  %s" % [b, String(Assets.BIOME_NAMES[b])])
	brow.add_child(bpick)
	_action_button(brow, "Apply", func():
		var sel := bpick.selected
		var b := "auto" if sel == 0 else Assets.BIOMES[sel - 1]
		EventBus.cheat_set_biome.emit(b))

	var bgrid := _grid(4)
	p.add_child(bgrid)
	for b in Assets.BIOMES:
		var nm := String(b)
		_action_button(bgrid, nm.capitalize(), func():
			EventBus.cheat_set_biome.emit(nm))


func _page_bestiary() -> void:
	var p := _new_page("bestiary")
	_section(p, "Monster database")
	_row_label(p, "%d creature types. Speeds are deliberately restrained — the player is always faster." % EnemyDB.TYPES.size(),
		Color("#6b5138"))

	var scroll := VBoxContainer.new()
	scroll.add_theme_constant_override("separation", 6)
	p.add_child(scroll)

	for id in EnemyDB.TYPES:
		var t: Dictionary = EnemyDB.TYPES[id]
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", DarkStyle.block(DarkStyle.PANEL_HI, 5, 3))
		scroll.add_child(row)

		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		row.add_child(hb)

		var ic := TextureRect.new()
		ic.texture = load(Assets.char_sheet(String(t["key"])))
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.custom_minimum_size = Vector2(40, 40)
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hb.add_child(ic)

		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vb.add_theme_constant_override("separation", 1)
		hb.add_child(vb)

		var nm := BleedingLabel.new()
		nm.text = "%s  —  %s" % [String(t["name"]), id]
		DarkStyle.body(nm, 14, DarkStyle.INK_BRIGHT)
		vb.add_child(nm)

		var stats := BleedingLabel.new()
		stats.text = "HP %d   DMG %d   SPD %.0f   XP %d   GOLD %d   %s%s" % [
			int(t["hp"]), int(t["damage"]), float(t["speed"]), int(t["xp"]), int(t["gold"]),
			String(t["behaviour"]).to_upper(), "   •  ELITE" if bool(t.get("elite", false)) else ""]
		DarkStyle.body(stats, 12, Color("#6b5138"))
		vb.add_child(stats)

		var lore := BleedingLabel.new()
		lore.text = EnemyDB.lore(id)
		lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lore.custom_minimum_size = Vector2(560, 0)
		DarkStyle.body(lore, 12, Color("#8a7358"))
		vb.add_child(lore)

		var spawn := Button.new()
		spawn.text = "Spawn x3"
		spawn.custom_minimum_size = Vector2(96, 32)
		spawn.pressed.connect(func():
			EventBus.cheat_spawn_enemy.emit(id, 3)
			EventBus.toast_msg("Spawned 3 x " + String(t["name"]), DarkStyle.ACCENTS["magic"]))
		hb.add_child(spawn)

	_section(p, "Boss schedule")
	for d in EnemyDB.BOSSES:
		var b: Dictionary = EnemyDB.BOSSES[d]
		_row_label(p, "Depth %s  —  %s  (%s)" % [str(d), String(b["title"]), String(b["id"])], Color("#a8322a"))


func _page_telemetry() -> void:
	var p := _new_page("telemetry")
	_section(p, "Run statistics")
	var g := _grid(2)
	p.add_child(g)
	for k in ["run_depth", "run_kills", "run_gold", "run_time", "run_level", "run_enemies",
			"run_damage", "run_speed", "run_rooms", "run_cells", "run_fps", "run_seed"]:
		_live[k] = _row_label(g, "—")

	_section(p, "Engine")
	var g2 := _grid(2)
	p.add_child(g2)
	_live["engine_fps"] = _row_label(g2, "—")
	_live["engine_draw"] = _row_label(g2, "—")
	_live["engine_mem"] = _row_label(g2, "—")
	_live["engine_objects"] = _row_label(g2, "—")

	_section(p, "Recent events")
	var log := VBoxContainer.new()
	p.add_child(log)
	_live["log"] = _row_label(log, "—")
	_live["log"].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _page_system() -> void:
	var p := _new_page("system")
	_section(p, "Run control")
	var g := _grid(2)
	p.add_child(g)
	_action_button(g, "Restart run  (new seed)", func(): EventBus.request_restart.emit(), true)
	_action_button(g, "Respawn at spawn point", func():
		if level and level.player:
			level.player.position = level._cell_center(level.spawn_cell)
			level.player.is_dead = false
			level.player.set_process(true)
			level.player.visible = true
			GameState.hp = GameState.max_hp
			EventBus.hp_changed.emit(GameState.hp, GameState.max_hp))
	_action_button(g, "Save cheats to disk", func():
		GameState.save_meta()
		EventBus.toast_msg("CHEATS SAVED", Color("#3f7a4a")))
	_action_button(g, "Load cheats from disk", func():
		GameState.load_meta()
		_refresh_all()
		EventBus.toast_msg("CHEATS LOADED", Color("#3f7a4a")))

	_section(p, "Camera")
	var cg := _grid(2)
	p.add_child(cg)
	for z in [1.0, 2.0, 2.4, 3.0, 4.0, 5.0]:
		var zz: float = z
		_action_button(cg, "Zoom %.1fx" % zz, func():
			var cam := get_tree().get_first_node_in_group("camera")
			if cam and cam.has_method("set_zoom_level"):
				cam.set_zoom_level(zz))
	_action_button(cg, "Screen shake test", func():
		var cam := get_tree().get_first_node_in_group("camera")
		if cam and cam.has_method("kick"):
			cam.kick(8.0, Vector2.RIGHT))

	_shortcuts(p)

	_section(p, "About")
	_row_label(p, "Dungeon of the Nine Realms  v1.0.0", DarkStyle.INK_BRIGHT)
	_row_label(p, "Art: Kenney (CC0) + 0x72 dungeon tiles via Dungeon-CampusMinden (CC0).", Color("#8a7358"))
	_row_label(p, "Engine: Godot 4.7  •  GDScript  •  gl_compatibility renderer.", Color("#8a7358"))


func _shortcuts(p: Node) -> void:
	_section(p, "Controls")
	_row_label(p, "WASD / arrows   move")
	_row_label(p, "LMB             melee slash")
	_row_label(p, "RMB             ranged bolt")
	_row_label(p, "Esc             close this console")


# ---------------------------------------------------------------------------
# Live refresh
# ---------------------------------------------------------------------------
func _refresh_all() -> void:
	_status.text = "GOD  ON" if GameState.god_mode else "GOD  OFF"
	_status.add_theme_color_override("font_color", Color("#3f7a4a") if GameState.god_mode else Color("#8a7358"))

	if _live.has("hp"):
		_live["hp"].text = "HP: %d / %d" % [GameState.hp, GameState.max_hp]
		_live["level"].text = "Level: %d" % GameState.level
		_live["gold"].text = "Gold: %d" % GameState.gold
		_live["damage"].text = "Attack: %d" % GameState.stat_damage
		_live["armour"].text = "Armour: %d" % GameState.armour
		_live["crit"].text = "Crit: %.0f%% x%.1f" % [GameState.crit_chance * 100.0, GameState.crit_mult]
		_live["lifesteal"].text = "Lifesteal: %.0f%%" % (GameState.lifesteal * 100.0)
		_live["speed"].text = "Move speed: %.0f" % GameState.stat_move_speed
		_live["kills"].text = "Kills: %d" % GameState.kills

	if level:
		if _live.has("run_depth"):
			_live["run_depth"].text = "Depth: %d  (%s)" % [GameState.depth, String(Assets.BIOME_NAMES.get(level.biome, level.biome))]
			_live["run_kills"].text = "Kills: %d" % GameState.kills
			_live["run_gold"].text = "Gold: %d" % GameState.gold
			_live["run_time"].text = "Run time: %d:%02d" % [int(GameState.run_time) / 60, int(GameState.run_time) % 60]
			_live["run_level"].text = "Level: %d  (xp %d/%d)" % [GameState.level, GameState.xp, GameState.xp_needed]
			_live["run_damage"].text = "Attack: %d" % GameState.stat_damage
			_live["run_speed"].text = "Move: %.0f   Monsters: %.2fx" % [GameState.stat_move_speed, GameState.enemy_speed_mult]
			_live["run_rooms"].text = "Rooms: %d" % level.rooms.size()
			_live["run_cells"].text = "Grid: %d x %d" % [level.GW, level.GH]
			var n := 0
			for e in level.entities.get_children():
				if e is Enemy and not e.is_dead:
					n += 1
			_live["run_enemies"].text = "Monsters alive: %d" % n
			_live["run_fps"].text = "FPS: %d" % Engine.get_frames_per_second()

		if _live.has("census"):
			var tally := {}
			var total := 0
			for e in level.entities.get_children():
				if e is Enemy and not e.is_dead:
					tally[e.id] = int(tally.get(e.id, 0)) + 1
					total += 1
			var parts: Array[String] = []
			for k in tally:
				parts.append("%s x%d" % [String(EnemyDB.TYPES.get(k, {}).get("name", k)), int(tally[k])])
			_live["census"].text = ", ".join(parts) if parts.size() > 0 else "no monsters alive"
			_live["census_total"].text = "Total alive: %d" % total


func _process(delta: float) -> void:
	if not is_open:
		return
	_live_tick += delta
	if _live_tick < 0.25:
		return
	_live_tick = 0.0
	_refresh_all()
	if _live.has("engine_fps"):
		_live["engine_fps"].text = "FPS: %d" % Engine.get_frames_per_second()
		_live["engine_draw"].text = "Draw calls: %d" % Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		_live["engine_mem"].text = "Memory: %.1f MB" % (OS.get_static_memory_usage() / 1048576.0)
		_live["engine_objects"].text = "Objects: %d" % Performance.get_monitor(Performance.OBJECT_COUNT)
		_live["run_fps"].text = "FPS: %d" % Engine.get_frames_per_second()

var _live_tick := 0.0
