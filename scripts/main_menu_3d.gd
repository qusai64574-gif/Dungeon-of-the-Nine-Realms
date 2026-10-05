class_name MainMenu3D
extends CanvasLayer
## Main menu with TRUE 3D buttons — real extruded geometry.
## Buttons have actual depth (Z extrusion), beveled edges, and 3D lighting.

signal start_new_run
signal continue_run
signal quit_game
signal give_up

var _root: Control
var _subviewport: SubViewport
var _camera: Camera3D
var _perspective: Node2D
var _t: float = 0.0
var _state := "initializing"
var _entrance_done := false
var _exiting := false
var _buttons: Dictionary = {}  # name -> Node3D
var _btn_order: Array[String] = ["Btn_NewGame", "Btn_Continue", "Btn_Settings", "Btn_Binary", "Btn_GiveUp"]
var _btn_base_pos: Dictionary = {}
var _sword_logo: BloodySwordLogo

func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = true
	_state = "entering"
	_play_entrance()

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var bg := TextureRect.new()
	bg.texture = _bloody_background_texture()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_root.add_child(bg)

	_perspective = Node2D.new()
	_perspective.name = "Perspective"
	_perspective.position = Vector2(300, 300)
	_perspective.rotation = -11.0 * PI / 180.0
	_perspective.scale = Vector2(0.927, 1.0)
	_root.add_child(_perspective)

	# SubViewportContainer
	var svc := SubViewportContainer.new()
	svc.name = "SubViewportContainer"
	svc.size = Vector2(800, 600)
	svc.position = Vector2(-400, -300)
	_perspective.add_child(svc)

	_subviewport = SubViewport.new()
	_subviewport.name = "SubViewport"
	_subviewport.size = Vector2(800, 600)
	_subviewport.transparent_bg = true
	_subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svc.add_child(_subviewport)

	# Camera
	_camera = Camera3D.new()
	_camera.name = "Camera3D"
	_camera.position = Vector3(0, 0, 10)
	_camera.fov = 50
	_subviewport.add_child(_camera)

	# Lighting
	var dir_light := DirectionalLight3D.new()
	dir_light.name = "DirLight"
	dir_light.rotation_degrees = Vector3(-45, -30, 0)
	dir_light.light_energy = 2.0
	_subviewport.add_child(dir_light)

	var omni_light := OmniLight3D.new()
	omni_light.name = "OmniLight"
	omni_light.position = Vector3(0, 0, 5)
	omni_light.light_energy = 1.5
	omni_light.omni_range = 15
	_subviewport.add_child(omni_light)

	var back_light := DirectionalLight3D.new()
	back_light.name = "BackLight"
	back_light.rotation_degrees = Vector3(30, 150, 0)
	back_light.light_energy = 0.8
	_subviewport.add_child(back_light)

	# Build true 3D buttons
	_build_3d_buttons()

	# Sword logo
	_sword_logo = BloodySwordLogo.new()
	_sword_logo.name = "SwordLogo"
	_sword_logo.custom_minimum_size = Vector2(220, 220)
	_sword_logo.position = Vector2(-110, -320)
	_perspective.add_child(_sword_logo)

	# Stats footer
	var foot := BleedingLabel.new()
	foot.name = "Foot"
	DarkStyle.body(foot, 13, Color("#c93a3a"))
	foot.set_blood_colour(Color("#c93a3a"))
	foot.set_streak_colour(Color("#3a0000"))
	foot.add_theme_color_override("font_outline_color", Color("#000000"))
	foot.add_theme_constant_override("outline_size", 3)
	foot.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	foot.position = Vector2(40, -25)
	_root.add_child(foot)

	_refresh()

func _build_3d_buttons() -> void:
	var btn_y := 0.0
	var btn_names := ["NEW GAME", "CONTINUE", "SETTINGS", "BESTIARY", "GIVE UP"]
	var btn_actions := ["Btn_NewGame", "Btn_Continue", "Btn_Settings", "Btn_Binary", "Btn_GiveUp"]
	var btn_colors := [
		Color("#4aba5a"),  # green
		Color("#4a9ab8"),  # blue
		Color("#ff9040"),  # orange
		Color("#9a4aba"),  # purple
		Color("#ff2a30"),  # red
	]

	for i in btn_names.size():
		var btn_node := _create_3d_button(btn_names[i], btn_colors[i])
		btn_node.position = Vector3(0, btn_y, 0)
		_subviewport.add_child(btn_node)
		_buttons[btn_actions[i]] = btn_node
		_btn_base_pos[btn_actions[i]] = btn_node.position
		btn_y -= 1.2

func _create_3d_button(label: String, accent: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "Btn_" + label.replace(" ", "_")

	# Main button body — extruded box
	var body := CSGBox3D.new()
	body.name = "Body"
	body.size = Vector3(4.0, 0.8, 0.6)
	body.material = _button_material(accent)
	root.add_child(body)

	# Beveled top face
	var top := CSGBox3D.new()
	top.name = "Top"
	top.size = Vector3(3.8, 0.6, 0.5)
	top.position = Vector3(0, 0.1, 0.05)
	top.material = _button_material(accent.lightened(0.15))
	root.add_child(top)

	# Border frame
	var border := CSGBox3D.new()
	border.name = "Border"
	border.size = Vector3(4.1, 0.9, 0.55)
	border.position = Vector3(0, 0, -0.02)
	border.material = _border_material()
	root.add_child(border)

	# Label
	var label_node := Label3D.new()
	label_node.name = "Label"
	label_node.text = label
	label_node.font_size = 48
	label_node.modulate = accent
	label_node.position = Vector3(0, 0, 0.35)
	label_node.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	root.add_child(label_node)

	return root

func _button_material(accent: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#2e0d10")
	mat.metallic = 0.3
	mat.roughness = 0.4
	mat.emission_enabled = true
	mat.emission = accent.darkened(0.7)
	mat.emission_energy_multiplier = 0.3
	return mat

func _border_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#8f1219")
	mat.metallic = 0.5
	mat.roughness = 0.3
	return mat

func _handle_click(screen_pos: Vector2) -> void:
	if _subviewport == null or _camera == null:
		return
	var from := _camera.project_ray_origin(screen_pos)
	var to := from + _camera.project_ray_normal(screen_pos) * 100
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	var space_state: PhysicsDirectSpaceState3D = _subviewport.get_world_3d().space_state
	var result: Dictionary = space_state.intersect_ray(query)
	if result and result.collider:
		var btn_name = result.collider.name
		match btn_name:
			"Btn_NewGame":
				start_new_run.emit()
			"Btn_Continue":
				continue_run.emit()
			"Btn_Settings":
				pass
			"Btn_Binary":
				pass
			"Btn_GiveUp":
				give_up.emit()

func _play_entrance() -> void:
	_entrance_done = false
	_exiting = false
	_state = "entering"

	for btn_name in _btn_order:
		var btn: Node3D = _buttons.get(btn_name)
		if btn:
			btn.visible = false

	for i in _btn_order.size():
		var btn_name: String = _btn_order[i]
		var btn: Node3D = _buttons.get(btn_name)
		if btn:
			var delay := float(i) * 0.2
			var tw := create_tween()
			tw.tween_interval(delay)
			tw.tween_callback(func(): btn.visible = true)
			tw.tween_property(btn, "position", _btn_base_pos[btn_name], 0.95) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	var t_done := create_tween()
	t_done.tween_interval(0.2 * _btn_order.size() + 0.95)
	t_done.tween_callback(func():
		_entrance_done = true
		_state = "idle")

func _play_exit() -> void:
	if _exiting:
		return
	_exiting = true
	_state = "exiting"

	for i in range(_btn_order.size() - 1, -1, -1):
		var btn_name: String = _btn_order[i]
		var btn: Node3D = _buttons.get(btn_name)
		if btn:
			var delay := float(_btn_order.size() - 1 - i) * 0.07
			var tw := create_tween()
			tw.tween_interval(delay)
			tw.tween_callback(func(): btn.visible = false)

func _process(delta: float) -> void:
	_t += delta
	if _state == "idle":
		for i in _btn_order.size():
			var btn_name: String = _btn_order[i]
			var btn: Node3D = _buttons.get(btn_name)
			if btn:
				var phase := _t * TAU / 9.0 + float(i) * -1.9
				btn.position.y = _btn_base_pos[btn_name].y + sin(phase) * 0.1
				btn.rotation.y = sin(phase) * 0.02

func _bloody_background_texture() -> Texture2D:
	var w := 64
	var h := 36
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var p := Vector2(float(x) / w, float(y) / h)
			var t := p.y
			var col := Color("#0a0205").lerp(Color("#1a0508"), t)
			var stain := sin(p.x * 15.7 + p.y * 8.3) * sin(p.x * 7.1 - p.y * 11.7)
			if stain > 0.82:
				col = col.lerp(Color("#4a0000"), 0.35)
			elif stain > 0.70:
				col = col.lerp(Color("#2a0000"), 0.2)
			var bx := int(x) % 16
			var by := int(y) % 16
			if bx == 0 or by == 0:
				col = col.darkened(0.12)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

func _refresh() -> void:
	var foot: Label = _root.find_child("Foot", true, false)
	if foot:
		var sm := get_node_or_null("/root/SaveManager")
		if sm:
			foot.text = "Best depth %d     %d kills     %d runs" % [
				sm.best_depth, sm.total_kills, sm.total_runs]

func refresh() -> void:
	_refresh()
