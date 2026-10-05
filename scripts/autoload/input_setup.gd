extends Node
## Registers every input action at runtime. Doing this in code instead of the
## project file keeps the bindings readable and version-proof.

func _enter_tree() -> void:
	_bind("move_left",  [KEY_A, KEY_LEFT])
	_bind("move_right", [KEY_D, KEY_RIGHT])
	_bind("move_up",    [KEY_W, KEY_UP])
	_bind("move_down",  [KEY_S, KEY_DOWN])
	_bind("attack",     [KEY_SPACE])
	_bind("ranged",     [KEY_E])
	# The admin console: backslash, and F1 as a courtesy alternate.
	_bind("admin_panel", [KEY_BACKSLASH, KEY_F1])
	_bind("pause",       [KEY_ESCAPE])
	_bind("ui_cancel",   [KEY_ESCAPE])


func _bind(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.5)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
