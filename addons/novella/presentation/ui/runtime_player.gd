extends Control

class_name NovellaRuntimePlayerView

signal script_started(file_path: String)
signal script_finished(transcript: Array)
signal choice_buttons_changed(choices: Array)
signal quick_action_requested(action_id: StringName, result: Dictionary)

const RuntimeStageScene := preload("res://addons/novella/presentation/ui/runtime_stage.tscn")

var runtime: Variant = null
var vm: Variant = null
var parser: Variant = null
var quick_menu_manager: Variant = null

var stage: Control
var choice_panel: PanelContainer
var choice_list: VBoxContainer
var quick_menu_bar: HBoxContainer
var status_label: Label

var current_choices: Array = []
var auto_bind_runtime_flags: bool = true


func _ready() -> void:
	_build_ui()


func bind_runtime(runtime_context: Variant) -> void:
	runtime = runtime_context
	_build_ui()
	vm = _runtime_value(&"vm")
	parser = _runtime_value(&"parser")
	quick_menu_manager = _runtime_value(&"quick_menu_manager")
	if vm != null:
		if auto_bind_runtime_flags:
			vm.auto_select_choices = false
			vm.pause_on_text = true
		_connect_signal(vm, "choice_waiting", Callable(self, "_on_choice_waiting"))
		_connect_signal(vm, "advance_waiting", Callable(self, "_on_advance_waiting"))
		_connect_signal(vm, "finished", Callable(self, "_on_finished"))
		_connect_signal(vm, "runtime_error", Callable(self, "_on_runtime_error"))
	if stage != null and stage.has_method("bind_managers"):
		stage.bind_managers(_manager_context())
	if quick_menu_manager != null:
		_connect_signal(quick_menu_manager, "visibility_changed", Callable(self, "_on_quick_menu_visibility_changed"))
		_rebuild_quick_menu()


func start_script(source: String, file_path: String = "", max_steps: int = 10000) -> Array:
	_build_ui()
	_clear_choices()
	if stage != null and stage.has_method("clear"):
		stage.clear()
	if vm == null:
		return [{"type": "error", "message": "Runtime player has no VM bound.", "line": 0}]
	var ast = null
	if runtime != null and not (runtime is Dictionary) and runtime.has_method("parse_script"):
		ast = runtime.parse_script(source, file_path)
	elif parser != null and parser.has_method("parse"):
		ast = parser.parse(source, file_path)
	else:
		return [{"type": "error", "message": "Runtime player has no parser bound.", "line": 0}]
	vm.auto_select_choices = false
	vm.pause_on_text = true
	vm.load_script(ast)
	status_label.text = "Running %s" % (file_path if not file_path.is_empty() else "script")
	script_started.emit(file_path)
	return vm.run(max_steps)


func advance(max_steps: int = 10000) -> Dictionary:
	if vm == null:
		return {"ok": false, "error": "Runtime player has no VM bound."}
	if bool(vm.get("waiting_for_choice")):
		return {"ok": false, "error": "Runtime player is waiting for a choice."}
	if bool(vm.get("waiting_for_advance")) and vm.has_method("advance"):
		return vm.advance(max_steps)
	if vm.has_method("continue_run"):
		vm.continue_run(max_steps)
		return {"ok": true, "waiting_for_choice": bool(vm.get("waiting_for_choice")), "waiting_for_advance": bool(vm.get("waiting_for_advance"))}
	return {"ok": false, "error": "VM cannot continue."}


func choose_choice(choice_index: int, max_steps: int = 10000) -> Dictionary:
	if vm == null or not vm.has_method("choose"):
		return {"ok": false, "error": "Runtime player has no choice-capable VM."}
	_clear_choices()
	return vm.choose(choice_index, max_steps)


func dispatch_quick_action(action_id: StringName) -> Dictionary:
	if quick_menu_manager == null or not quick_menu_manager.has_method("dispatch_action"):
		return {"ok": false, "error": "Runtime player has no quick menu manager."}
	var result: Dictionary = quick_menu_manager.dispatch_action(action_id, {"runtime_player": self, "vm": vm})
	quick_action_requested.emit(action_id, result)
	return result


func refresh_quick_menu() -> void:
	_rebuild_quick_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if vm != null and not bool(vm.get("waiting_for_choice")):
			advance()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			advance()
		elif event.keycode == KEY_ESCAPE or event.keycode == KEY_H:
			if stage != null and stage.has_method("set_ui_hidden"):
				stage.set_ui_hidden(not bool(stage.get("hidden_ui")))


func _on_choice_waiting(choices: Array, line: int) -> void:
	_build_ui()
	current_choices = choices.duplicate(true)
	_clear_children(choice_list)
	for choice in choices:
		var button := Button.new()
		var choice_index := int(choice.get("index", -1))
		button.name = "Choice_%s" % choice_index
		button.text = str(choice.get("text", "Choice"))
		button.disabled = not bool(choice.get("enabled", true))
		button.custom_minimum_size = Vector2(320.0, 40.0)
		button.pressed.connect(func(): choose_choice(choice_index))
		choice_list.add_child(button)
	choice_panel.visible = true
	status_label.text = "Choice at line %s" % line
	choice_buttons_changed.emit(current_choices.duplicate(true))


func _on_advance_waiting(kind: StringName, line: int) -> void:
	status_label.text = "%s line %s" % [String(kind).capitalize(), line]


func _on_finished(transcript: Array) -> void:
	_clear_choices()
	status_label.text = "Finished"
	script_finished.emit(transcript)


func _on_runtime_error(message: String, line: int) -> void:
	status_label.text = "Error line %s: %s" % [line, message]


func _on_quick_menu_visibility_changed(visible: bool) -> void:
	quick_menu_bar.visible = visible


func _rebuild_quick_menu() -> void:
	_build_ui()
	_clear_children(quick_menu_bar)
	if quick_menu_manager == null or not quick_menu_manager.has_method("get_visible_actions"):
		quick_menu_bar.visible = false
		return
	quick_menu_bar.visible = bool(quick_menu_manager.get("visible"))
	for action in quick_menu_manager.get_visible_actions():
		var action_id := StringName(str(action.get("id", "")))
		var button := Button.new()
		button.name = "Quick_%s" % String(action_id)
		button.text = str(action.get("label", action_id))
		button.disabled = not bool(action.get("enabled", true))
		button.custom_minimum_size = Vector2(72.0, 32.0)
		button.pressed.connect(func(): dispatch_quick_action(action_id))
		quick_menu_bar.add_child(button)


func _clear_choices() -> void:
	current_choices.clear()
	if choice_panel != null:
		choice_panel.visible = false
	if choice_list != null:
		_clear_children(choice_list)
	choice_buttons_changed.emit([])


func _manager_context() -> Dictionary:
	return {
		"printer_manager": _runtime_value(&"printer_manager"),
		"background_manager": _runtime_value(&"background_manager"),
		"character_manager": _runtime_value(&"character_manager"),
		"effect_manager": _runtime_value(&"effect_manager"),
		"camera_director": _runtime_value(&"camera_director"),
		"audio_manager": _runtime_value(&"audio_manager"),
	}


func _runtime_value(key: StringName) -> Variant:
	if runtime is Dictionary:
		return runtime.get(key, runtime.get(String(key), null))
	if runtime != null:
		return runtime.get(String(key))
	return null


func _connect_signal(source: Variant, signal_name: String, callback: Callable) -> void:
	if source == null or not source.has_signal(signal_name):
		return
	if not source.is_connected(signal_name, callback):
		source.connect(signal_name, callback)


func _build_ui() -> void:
	if stage != null:
		return
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0

	stage = RuntimeStageScene.instantiate()
	stage.name = "RuntimeStage"
	add_child(stage)
	if stage.has_signal("advance_requested"):
		stage.advance_requested.connect(func(): advance())

	quick_menu_bar = HBoxContainer.new()
	quick_menu_bar.name = "QuickMenuBar"
	quick_menu_bar.anchor_left = 0.0
	quick_menu_bar.anchor_top = 0.0
	quick_menu_bar.anchor_right = 1.0
	quick_menu_bar.anchor_bottom = 0.0
	quick_menu_bar.offset_left = 12.0
	quick_menu_bar.offset_top = 36.0
	quick_menu_bar.offset_right = -12.0
	quick_menu_bar.offset_bottom = 76.0
	add_child(quick_menu_bar)

	choice_panel = PanelContainer.new()
	choice_panel.name = "ChoicePanel"
	choice_panel.anchor_left = 0.5
	choice_panel.anchor_top = 0.38
	choice_panel.anchor_right = 0.5
	choice_panel.anchor_bottom = 0.38
	choice_panel.offset_left = -220.0
	choice_panel.offset_top = -20.0
	choice_panel.offset_right = 220.0
	choice_panel.offset_bottom = 220.0
	choice_panel.visible = false
	add_child(choice_panel)

	choice_list = VBoxContainer.new()
	choice_list.name = "ChoiceList"
	choice_list.custom_minimum_size = Vector2(400.0, 120.0)
	choice_panel.add_child(choice_list)

	status_label = Label.new()
	status_label.name = "RuntimeStatus"
	status_label.anchor_left = 0.0
	status_label.anchor_top = 0.0
	status_label.anchor_right = 1.0
	status_label.anchor_bottom = 0.0
	status_label.offset_left = 12.0
	status_label.offset_top = 8.0
	status_label.offset_right = -12.0
	status_label.offset_bottom = 32.0
	add_child(status_label)


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
