extends Node2D
## Top-level orchestrator: game state machine, world, camera, HUD, menus.
##
## States: MENU -> PLAYING -> (PAUSED) -> GAME_OVER -> MENU

enum State { MENU, PLAYING, GAME_OVER }

var state: int = State.MENU
var level: Level
var camera: CameraRig
var hud: Hud
var admin: AdminPanel
var menu: MainMenu
var pause: PauseMenu
var fade: FadeOverlay
var giveup: GiveUpScreen
var gameover: GameOverScreen
var jump_scare: JumpScare
var menu_bestiary: MainMenuBestiary
var menu_settings: MainMenuSettings
var loading: LoadingScreen
var _over_shown := false
var _scare_timer := 0.0
var _scare_interval := 30.0
var _menu_shot := false

const MAX_DEPTH := 15


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#1a1018"))
	get_tree().root.theme = DarkStyle.build_theme()
	# Check for menu screenshot mode
	for a in OS.get_cmdline_user_args():
		if a == "--shot-menu":
			_menu_shot = true

	# --- world ------------------------------------------------------------
	level = Level.new()
	level.name = "Level"
	level.depth = 1
	add_child(level)

	# --- camera -----------------------------------------------------------
	camera = CameraRig.new()
	camera.name = "Camera"
	camera.add_to_group("camera")
	add_child(camera)
	camera.set_target(level.player)

	# --- ui ---------------------------------------------------------------
	hud = Hud.new(); hud.name = "HUD"; hud.level = level; add_child(hud)
	admin = AdminPanel.new(); admin.name = "AdminPanel"; admin.level = level; add_child(admin)
	pause = PauseMenu.new(); pause.name = "PauseMenu"; add_child(pause)
	menu = MainMenu.new(); menu.name = "MainMenu"; add_child(menu)
	fade = FadeOverlay.new(); fade.name = "Fade"; add_child(fade)
	giveup = GiveUpScreen.new(); giveup.name = "GiveUp"; add_child(giveup)
	jump_scare = JumpScare.new(); jump_scare.name = "JumpScare"; add_child(jump_scare)
	menu_bestiary = MainMenuBestiary.new(); menu_bestiary.name = "MenuBestiary"; add_child(menu_bestiary)
	menu_settings = MainMenuSettings.new(); menu_settings.name = "MenuSettings"; add_child(menu_settings)
	loading = LoadingScreen.new(); loading.name = "LoadingScreen"; add_child(loading)
	loading.finished.connect(func():
		loading.visible = false
		_to_menu_now())
	_build_gameover()

	# --- wiring -----------------------------------------------------------
	EventBus.damage_number.connect(_on_damage_number)
	EventBus.player_died.connect(_on_player_died)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.request_restart.connect(_start_new_run)
	EventBus.request_to_menu.connect(_to_menu)
	EventBus.floor_changed.connect(_on_floor)
	EventBus.run_ended.connect(_on_run_ended)
	EventBus.settings_applied.connect(_apply_settings)
	EventBus.request_pause.connect(func(): if state == State.PLAYING: pause.toggle())
	EventBus.request_give_up.connect(_ask_give_up)
	EventBus.cheat_full_heal.connect(func():
		GameState.hp = GameState.max_hp
		EventBus.hp_changed.emit(GameState.hp, GameState.max_hp))

	menu.start_new_run.connect(_start_new_run)
	menu.continue_run.connect(_continue_run)
	menu.quit_game.connect(func(): get_tree().quit())
	menu.give_up.connect(_ask_give_up)
	menu.open_settings.connect(func(): menu_settings.open_panel())
	menu.open_bestiary.connect(func(): menu_bestiary.open_panel())
	pause.give_up.connect(_ask_give_up)
	giveup.confirmed_quit.connect(func():
		# a beat for the flash to land, then out
		var t := get_tree().create_timer(0.45)
		t.timeout.connect(func(): get_tree().quit()))
	giveup.cancelled.connect(func():
		get_tree().paused = false
		EventBus.toast_msg("WISE.", Color("#8fe0a0"))
		if state == State.GAME_OVER:
			gameover.open())

	_apply_settings()
	# Loading screen will call _to_menu_now() when done


# ---------------------------------------------------------------------------
# State machine
# ---------------------------------------------------------------------------
func _to_menu() -> void:
	if state == State.MENU and menu.visible:
		# already there
		menu.refresh()
		return
	fade.transition(func(): _to_menu_now(), Color(0.7, 0.6, 1.0), 0.22)


func _to_menu_now() -> void:
	state = State.MENU
	menu.visible = true
	menu.refresh()
	menu._play_entrance()
	pause.set_open(false)
	gameover.close()
	admin.set_open(false)
	hud.visible = false
	level.visible = false
	get_tree().paused = false
	_over_shown = false


func _start_new_run() -> void:
	get_node("/root/SaveManager").clear_run()
	GameState.reset_run()
	GameState.depth = 1
	GameState.run_seed = randi()
	# Play menu exit animation, then transition
	if menu and menu.visible:
		menu._play_exit()
		await get_tree().create_timer(0.5).timeout
	fade.transition(func(): _enter_play(true), Color(0.8, 0.0, 0.05), 0.20)


func _continue_run() -> void:
	var sm := get_node("/root/SaveManager")
	if not sm.load_run():
		_start_new_run()
		return
	# Play menu exit animation, then transition
	if menu and menu.visible:
		menu._play_exit()
		await get_tree().create_timer(0.5).timeout
	fade.transition(func(): _enter_play(false), Color(0.6, 0.85, 1.0), 0.20)


func _enter_play(fresh: bool) -> void:
	state = State.PLAYING
	menu.visible = false
	gameover.close()
	hud.visible = true
	level.visible = true
	pause.set_open(false)
	get_tree().paused = false
	_over_shown = false
	level.depth = GameState.depth
	level.build(GameState.depth, fresh)
	if camera:
		camera.set_target(level.player)
	_apply_settings()
	# Struck by BLOODY lightning: red bolt from the sky, shockwave, land.
	_play_bloody_strike()
	EventBus.toast_msg("WASD move  •  LMB slash  •  RMB bolt", Color("#8a6068"))
	get_node("/root/SaveManager").mark_dirty()


func _play_bloody_strike() -> void:
	if level == null or level.player == null:
		return
	var strike := BloodyStrike.new()
	strike.name = "BloodyStrike"
	strike.set_target(level.player, camera)
	level.add_child(strike)
	fade.flash(Color(0.8, 0.0, 0.05), 0.42, 0.30)
	if camera:
		camera.kick(7.0, Vector2.DOWN)


func _ask_give_up() -> void:
	# pause the world so nothing moves behind the scare
	get_tree().paused = true
	giveup.open()


func _apply_settings() -> void:
	var sm := get_node_or_null("/root/SaveManager")
	if sm == null:
		return
	if camera:
		camera.set_zoom_level(sm.camera_zoom)
		camera.shake_enabled = sm.screen_shake
	# brightness is a global modulate on the world layer
	if level:
		var b: float = clampf(sm.brightness, 0.4, 1.6)
		level.modulate = Color(b, b, b, 1.0)


func _trigger_jump_scare() -> void:
	if jump_scare and state == State.PLAYING:
		jump_scare.trigger(0.6 + randf() * 0.4)

func _process(delta: float) -> void:
	# Random ambient jump scares
	if state == State.PLAYING:
		_scare_timer += delta
		if _scare_timer >= _scare_interval:
			_scare_timer = 0.0
			_scare_interval = randf_range(20.0, 45.0)
			if randf() < 0.3:
				_trigger_jump_scare()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if state == State.PLAYING:
			pause.toggle()
			get_viewport().set_input_as_handled()
		elif state == State.MENU:
			get_tree().quit()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if state == State.MENU:
			var menu := get_node_or_null("MainMenu")
			if menu and menu.has_method("_handle_click"):
				menu._handle_click(get_viewport().get_mouse_position())


# ---------------------------------------------------------------------------
# Floating combat text
# ---------------------------------------------------------------------------
func _on_damage_number(pos: Vector2, amount: int, kind: int) -> void:
	var sm := get_node_or_null("/root/SaveManager")
	if sm and not sm.show_damage_numbers and kind != 3:
		return
	var txt := str(amount)
	var col := Color(1, 1, 1)
	var sz := 12
	var rise := 34.0
	match kind:
		0:
			col = Color(1.0, 0.92, 0.55); sz = 13
		1:
			txt = str(amount) + "!"; col = Color(1.0, 0.45, 0.35); sz = 19; rise = 52.0
		2:
			txt = "+" + str(amount); col = Color(0.45, 1.0, 0.55); sz = 14
		3:
			txt = "-" + str(amount); col = Color(1.0, 0.35, 0.4); sz = 16; rise = 42.0
	var ft := FloatingText.new()
	ft.setup(txt, col, pos, sz, rise)
	if level and level.fx:
		level.fx.add_child(ft)
	else:
		add_child(ft)


func _on_enemy_killed(_n: String, pos: Vector2, _xp: int) -> void:
	if level and level.fx:
		var fx := HitFX.new()
		fx.setup(pos, Color(1.0, 0.55, 0.35), 10, 110.0, 3.0)
		level.fx.add_child(fx)
	var sm := get_node_or_null("/root/SaveManager")
	if sm:
		sm.mark_dirty()
	# 15% chance of jump scare on kill
	if randf() < 0.15:
		_trigger_jump_scare()


func _on_floor(depth: int) -> void:
	if depth > MAX_DEPTH and not _over_shown:
		_show_over(true)
	if camera and level and level.player:
		camera.set_target(level.player)
	var sm := get_node_or_null("/root/SaveManager")
	if sm:
		sm.mark_dirty()
	# 25% chance of jump scare on floor change
	if randf() < 0.25:
		_trigger_jump_scare()


func _on_run_ended(victory: bool) -> void:
	var sm := get_node_or_null("/root/SaveManager")
	if sm:
		sm.record_run_end(victory)


# ---------------------------------------------------------------------------
# End of run
# ---------------------------------------------------------------------------
func _on_player_died() -> void:
	if state != State.PLAYING:
		return
	if level:
		level.mark_player_dead()
	get_tree().paused = false
	_show_over(false)


func _build_gameover() -> void:
	gameover = GameOverScreen.new()
	gameover.name = "GameOver"
	add_child(gameover)
	gameover.restart_requested.connect(_start_new_run)
	gameover.give_up_requested.connect(func():
		get_tree().paused = false
		_to_menu())


func _show_over(victory: bool) -> void:
	if _over_shown:
		return
	_over_shown = true
	state = State.GAME_OVER
	if victory:
		gameover.set_stats("You cleared all %d depths. The Nine Realms are quiet — for now." % MAX_DEPTH)
	else:
		var m := int(GameState.run_time) / 60
		var s := int(GameState.run_time) % 60
		gameover.set_stats("Depth reached   %d\nKills   %d\nGold   %d\nLevel   %d\nTime   %d:%02d"
			% [GameState.depth, GameState.kills, GameState.gold, GameState.level, m, s])
	gameover.open()
	EventBus.run_ended.emit(victory)
	EventBus.toast_msg("RUN ENDED", DarkStyle.INK if not victory else DarkStyle.INK_BRIGHT)
