@tool
extends Control

class_name NovellaTimelineEditorPanel

signal event_added(event_type: StringName)
signal event_selected(index: int)
signal event_moved(from_index: int, to_index: int)
signal event_duplicated(index: int)
signal event_deleted(index: int)
signal events_copied(indices: Array)
signal events_pasted(index: int)
signal mode_changed(mode: StringName)

var mode: StringName = &"visual"
var events: Array = []
var selected_index: int = -1
var list: ItemList
var mode_button: Button
var add_dialogue_button: Button
var add_command_button: Button
var move_up_button: Button
var move_down_button: Button
var duplicate_button: Button
var copy_button: Button
var paste_button: Button
var delete_button: Button

func _ready() -> void:
	_build_ui()


func apply_events(next_events: Array) -> void:
	_build_ui()
	events = next_events.duplicate(true)
	if selected_index >= events.size():
		selected_index = -1
	list.clear()
	for event in events:
		var index := list.add_item(_event_title(event))
		list.set_item_metadata(index, int(event.get("order", index)))
	if selected_index >= 0 and selected_index < list.item_count:
		list.select(selected_index)
	_update_buttons()


func set_mode(next_mode: StringName) -> void:
	mode = next_mode
	mode_button.text = "Mode: %s" % String(mode)
	mode_changed.emit(mode)


func get_selected_index() -> int:
	return selected_index


func select_event(index: int) -> void:
	if index < 0 or index >= events.size():
		selected_index = -1
		list.deselect_all()
	else:
		selected_index = index
		list.select(index)
	_update_buttons()


func _build_ui() -> void:
	if list != null:
		return
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0

	var root := VBoxContainer.new()
	root.name = "Root"
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.add_theme_constant_override("separation", 6)
	add_child(root)

	var toolbar := HBoxContainer.new()
	toolbar.name = "Toolbar"
	toolbar.add_theme_constant_override("separation", 6)
	root.add_child(toolbar)

	mode_button = Button.new()
	mode_button.name = "ModeButton"
	mode_button.text = "Mode: visual"
	mode_button.pressed.connect(_on_mode_pressed)
	toolbar.add_child(mode_button)

	add_dialogue_button = Button.new()
	add_dialogue_button.name = "AddDialogueButton"
	add_dialogue_button.text = "+ Dialogue"
	add_dialogue_button.pressed.connect(func(): event_added.emit(&"dialogue"))
	toolbar.add_child(add_dialogue_button)

	add_command_button = Button.new()
	add_command_button.name = "AddCommandButton"
	add_command_button.text = "+ Command"
	add_command_button.pressed.connect(func(): event_added.emit(&"command"))
	toolbar.add_child(add_command_button)

	move_up_button = Button.new()
	move_up_button.name = "MoveUpButton"
	move_up_button.text = "Up"
	move_up_button.pressed.connect(_on_move_up_pressed)
	toolbar.add_child(move_up_button)

	move_down_button = Button.new()
	move_down_button.name = "MoveDownButton"
	move_down_button.text = "Down"
	move_down_button.pressed.connect(_on_move_down_pressed)
	toolbar.add_child(move_down_button)

	duplicate_button = Button.new()
	duplicate_button.name = "DuplicateButton"
	duplicate_button.text = "Duplicate"
	duplicate_button.pressed.connect(_on_duplicate_pressed)
	toolbar.add_child(duplicate_button)

	copy_button = Button.new()
	copy_button.name = "CopyButton"
	copy_button.text = "Copy"
	copy_button.pressed.connect(_on_copy_pressed)
	toolbar.add_child(copy_button)

	paste_button = Button.new()
	paste_button.name = "PasteButton"
	paste_button.text = "Paste"
	paste_button.pressed.connect(_on_paste_pressed)
	toolbar.add_child(paste_button)

	delete_button = Button.new()
	delete_button.name = "DeleteButton"
	delete_button.text = "Delete"
	delete_button.pressed.connect(_on_delete_pressed)
	toolbar.add_child(delete_button)

	list = ItemList.new()
	list.name = "EventList"
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.item_selected.connect(_on_item_selected)
	root.add_child(list)
	_update_buttons()


func _event_title(event: Dictionary) -> String:
	var prefix := "%s  line %s" % [str(event.get("type", "event")), str(event.get("line", 0))]
	if event.has("speaker"):
		return "%s  %s: %s" % [prefix, event.get("speaker", ""), event.get("text", "")]
	if event.has("command"):
		return "%s  @%s %s" % [prefix, event.get("command", ""), event.get("arguments", "")]
	if event.has("label"):
		return "%s  %s" % [prefix, event.get("label", "")]
	if event.has("text"):
		return "%s  %s" % [prefix, event.get("text", "")]
	return prefix


func _on_item_selected(index: int) -> void:
	selected_index = index
	_update_buttons()
	event_selected.emit(index)


func _on_move_up_pressed() -> void:
	if selected_index <= 0:
		return
	event_moved.emit(selected_index, selected_index - 1)


func _on_move_down_pressed() -> void:
	if selected_index < 0 or selected_index + 1 >= events.size():
		return
	event_moved.emit(selected_index, selected_index + 1)


func _on_delete_pressed() -> void:
	if selected_index >= 0:
		event_deleted.emit(selected_index)


func _on_duplicate_pressed() -> void:
	if selected_index >= 0:
		event_duplicated.emit(selected_index)


func _on_copy_pressed() -> void:
	if selected_index >= 0:
		events_copied.emit([selected_index])


func _on_paste_pressed() -> void:
	events_pasted.emit(selected_index + 1 if selected_index >= 0 else -1)


func _on_mode_pressed() -> void:
	set_mode(&"text" if mode == &"visual" else &"visual")


func _update_buttons() -> void:
	if move_up_button == null:
		return
	move_up_button.disabled = selected_index <= 0
	move_down_button.disabled = selected_index < 0 or selected_index + 1 >= events.size()
	delete_button.disabled = selected_index < 0
	duplicate_button.disabled = selected_index < 0
	copy_button.disabled = selected_index < 0
