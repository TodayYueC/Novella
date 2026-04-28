extends Control

class_name NovellaSaveLoadPanelView

signal slot_save_requested(slot: StringName)
signal slot_load_requested(slot: StringName)
signal slot_delete_requested(slot: StringName)
signal confirmation_requested(action: StringName, slot: StringName)
signal page_changed(page: int)
signal close_requested

var mode: StringName = &"save"
var page: int = 0
var page_count: int = 1
var current_slots: Array = []

var title_label: Label
var page_label: Label
var slot_grid: GridContainer
var previous_button: Button
var next_button: Button
var confirm_panel: PanelContainer
var confirm_label: Label
var confirm_button: Button
var cancel_button: Button
var close_button: Button
var _pending_action: StringName = &""
var _pending_slot: StringName = &""

func _ready() -> void:
	_build_ui()


func apply_slots(slots: Array, p_mode: StringName = &"save", p_page: int = 0, p_page_count: int = 1) -> void:
	_build_ui()
	mode = p_mode
	page = max(0, p_page)
	page_count = max(1, p_page_count)
	current_slots = slots.duplicate(true)
	title_label.text = "Save" if mode == &"save" else "Load"
	page_label.text = "Page %s / %s" % [page + 1, page_count]
	previous_button.disabled = page <= 0
	next_button.disabled = page + 1 >= page_count
	_clear_slot_grid()
	for slot in current_slots:
		slot_grid.add_child(_build_slot_card(slot))


func request_confirmation(action: StringName, slot: StringName) -> void:
	_build_ui()
	_pending_action = action
	_pending_slot = slot
	confirm_label.text = "%s %s?" % [_action_label(action), String(slot)]
	confirm_panel.visible = true
	confirmation_requested.emit(action, slot)


func confirm_pending() -> void:
	if _pending_action == &"":
		return
	var action := _pending_action
	var slot := _pending_slot
	_clear_confirmation()
	match action:
		&"save":
			slot_save_requested.emit(slot)
		&"load":
			slot_load_requested.emit(slot)
		&"delete":
			slot_delete_requested.emit(slot)


func cancel_pending() -> void:
	_clear_confirmation()


func clear() -> void:
	_build_ui()
	_clear_slot_grid()
	current_slots.clear()
	_clear_confirmation()


func _build_ui() -> void:
	if slot_grid != null:
		return
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 40.0
	offset_top = 32.0
	offset_right = -40.0
	offset_bottom = -32.0

	var root := VBoxContainer.new()
	root.name = "Root"
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	var header := HBoxContainer.new()
	header.name = "Header"
	header.add_theme_constant_override("separation", 8)
	root.add_child(header)

	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "Save"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)

	close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = "Close"
	close_button.pressed.connect(func(): close_requested.emit())
	header.add_child(close_button)

	slot_grid = GridContainer.new()
	slot_grid.name = "SlotGrid"
	slot_grid.columns = 2
	slot_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(slot_grid)

	var footer := HBoxContainer.new()
	footer.name = "Footer"
	footer.add_theme_constant_override("separation", 8)
	root.add_child(footer)

	previous_button = Button.new()
	previous_button.name = "PreviousButton"
	previous_button.text = "Previous"
	previous_button.pressed.connect(_on_previous_pressed)
	footer.add_child(previous_button)

	page_label = Label.new()
	page_label.name = "PageLabel"
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(page_label)

	next_button = Button.new()
	next_button.name = "NextButton"
	next_button.text = "Next"
	next_button.pressed.connect(_on_next_pressed)
	footer.add_child(next_button)

	confirm_panel = PanelContainer.new()
	confirm_panel.name = "ConfirmPanel"
	confirm_panel.visible = false
	root.add_child(confirm_panel)

	var confirm_row := HBoxContainer.new()
	confirm_row.name = "ConfirmRow"
	confirm_row.add_theme_constant_override("separation", 8)
	confirm_panel.add_child(confirm_row)

	confirm_label = Label.new()
	confirm_label.name = "ConfirmLabel"
	confirm_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_row.add_child(confirm_label)

	confirm_button = Button.new()
	confirm_button.name = "ConfirmButton"
	confirm_button.text = "OK"
	confirm_button.pressed.connect(confirm_pending)
	confirm_row.add_child(confirm_button)

	cancel_button = Button.new()
	cancel_button.name = "CancelButton"
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(cancel_pending)
	confirm_row.add_child(cancel_button)


func _build_slot_card(slot: Dictionary) -> Control:
	var card := VBoxContainer.new()
	card.name = "Slot_%s" % str(slot.get("slot", ""))
	card.custom_minimum_size = Vector2(280.0, 132.0)
	card.add_theme_constant_override("separation", 4)

	var title := Label.new()
	title.name = "SlotTitle"
	title.text = _slot_title(slot)
	title.clip_text = true
	card.add_child(title)

	var summary := Label.new()
	summary.name = "SlotSummary"
	summary.text = _slot_summary(slot)
	summary.clip_text = true
	card.add_child(summary)

	var time := Label.new()
	time.name = "SlotTime"
	time.text = str(slot.get("saved_at", ""))
	time.clip_text = true
	card.add_child(time)

	var actions := HBoxContainer.new()
	actions.name = "SlotActions"
	actions.add_theme_constant_override("separation", 6)
	card.add_child(actions)

	var action_button := Button.new()
	action_button.name = "ActionButton"
	action_button.text = "Save" if mode == &"save" else "Load"
	action_button.disabled = mode == &"load" and not bool(slot.get("occupied", false))
	action_button.pressed.connect(_on_slot_action_pressed.bind(slot.duplicate(true)))
	actions.add_child(action_button)

	var delete_button := Button.new()
	delete_button.name = "DeleteButton"
	delete_button.text = "Delete"
	delete_button.disabled = not bool(slot.get("occupied", false))
	delete_button.pressed.connect(_on_delete_pressed.bind(StringName(str(slot.get("slot", "")))))
	actions.add_child(delete_button)

	return card


func _slot_title(slot: Dictionary) -> String:
	var slot_name := str(slot.get("slot", ""))
	if bool(slot.get("occupied", false)):
		return "%s - %s" % [slot_name, str(slot.get("title", slot_name))]
	return "%s - Empty" % slot_name


func _slot_summary(slot: Dictionary) -> String:
	if not bool(slot.get("occupied", false)):
		return "No save data"
	var summary := str(slot.get("summary", ""))
	if summary.is_empty():
		summary = str(slot.get("version", ""))
	return summary


func _clear_slot_grid() -> void:
	for child in slot_grid.get_children():
		slot_grid.remove_child(child)
		child.queue_free()


func _clear_confirmation() -> void:
	_pending_action = &""
	_pending_slot = &""
	if confirm_panel != null:
		confirm_panel.visible = false
	if confirm_label != null:
		confirm_label.text = ""


func _on_slot_action_pressed(slot: Dictionary) -> void:
	var slot_name := StringName(str(slot.get("slot", "")))
	if mode == &"save":
		if bool(slot.get("occupied", false)):
			request_confirmation(&"save", slot_name)
		else:
			slot_save_requested.emit(slot_name)
	elif bool(slot.get("occupied", false)):
		slot_load_requested.emit(slot_name)


func _on_delete_pressed(slot: StringName) -> void:
	request_confirmation(&"delete", slot)


func _on_previous_pressed() -> void:
	if page <= 0:
		return
	page_changed.emit(page - 1)


func _on_next_pressed() -> void:
	if page + 1 >= page_count:
		return
	page_changed.emit(page + 1)


func _action_label(action: StringName) -> String:
	match action:
		&"save":
			return "Overwrite"
		&"load":
			return "Load"
		&"delete":
			return "Delete"
		_:
			return "Confirm"
