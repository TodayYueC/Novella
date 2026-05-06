@tool
extends Control

class_name NovellaEditorDock

const TimelineEditorPanelScene := preload("res://addons/novella/editor/ui/timeline_editor_panel.tscn")

signal analyze_requested(path: String)
signal template_requested(template_id: StringName)
signal new_script_requested(path: String)
signal save_requested(path: String)
signal visual_event_added(event_type: StringName, form: Dictionary)
signal visual_event_updated(index: int, form: Dictionary)
signal visual_event_moved(from_index: int, to_index: int)
signal visual_event_duplicated(index: int)
signal visual_event_deleted(index: int)
signal visual_events_copied(indices: Array)
signal visual_events_pasted(index: int)
signal visual_undo_requested()
signal visual_redo_requested()

var path_edit: LineEdit
var new_button: Button
var analyze_button: Button
var save_button: Button
var tabs: TabContainer
var outline_tree: Tree
var timeline_tree: Tree
var visual_timeline: Control
var event_type_options: OptionButton
var name_edit: LineEdit
var speaker_edit: LineEdit
var command_edit: LineEdit
var target_edit: LineEdit
var condition_edit: LineEdit
var text_edit: TextEdit
var choices_edit: TextEdit
var add_event_button: Button
var update_event_button: Button
var undo_button: Button
var redo_button: Button
var script_preview: TextEdit
var status_label: Label
var diagnostics_label: RichTextLabel
var templates_list: ItemList
var selected_visual_index: int = -1

func _ready() -> void:
	_build_ui()


func apply_analysis(analysis: Dictionary) -> void:
	_build_ui()
	path_edit.text = str(analysis.get("file_path", path_edit.text))
	_apply_outline(analysis.get("outline", {}))
	_apply_timeline(analysis.get("timeline", {}))
	if visual_timeline != null and visual_timeline.has_method("apply_events"):
		visual_timeline.apply_events(analysis.get("timeline", {}).get("events", []))
	_apply_diagnostics(analysis.get("diagnostics", {}))


func apply_visual_state(state: Dictionary) -> void:
	_build_ui()
	path_edit.text = str(state.get("file_path", path_edit.text))
	var events: Array = state.get("events", [])
	if visual_timeline != null and visual_timeline.has_method("apply_events"):
		visual_timeline.apply_events(events)
		if visual_timeline.has_method("select_event"):
			visual_timeline.select_event(selected_visual_index)
	_apply_timeline({"events": events})
	_apply_diagnostics(state.get("diagnostics", {}))
	script_preview.text = str(state.get("script", state.get("source", "")))
	status_label.text = _status_for_state(state)
	_update_inspector_buttons()


func apply_templates(templates: Array) -> void:
	_build_ui()
	templates_list.clear()
	for template in templates:
		var index := templates_list.add_item(str(template.get("name", template.get("id", ""))))
		templates_list.set_item_metadata(index, StringName(str(template.get("id", ""))))


func _build_ui() -> void:
	if tabs != null:
		return
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	custom_minimum_size = Vector2(320.0, 420.0)

	var root := VBoxContainer.new()
	root.name = "Root"
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.add_theme_constant_override("separation", 6)
	add_child(root)

	var toolbar := HBoxContainer.new()
	toolbar.name = "Toolbar"
	root.add_child(toolbar)

	new_button = Button.new()
	new_button.name = "NewButton"
	new_button.text = "New"
	new_button.pressed.connect(_on_new_pressed)
	toolbar.add_child(new_button)

	path_edit = LineEdit.new()
	path_edit.name = "PathEdit"
	path_edit.placeholder_text = "res://"
	path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(path_edit)

	analyze_button = Button.new()
	analyze_button.name = "AnalyzeButton"
	analyze_button.text = "Analyze"
	analyze_button.pressed.connect(_on_analyze_pressed)
	toolbar.add_child(analyze_button)

	save_button = Button.new()
	save_button.name = "SaveButton"
	save_button.text = "Save"
	save_button.pressed.connect(_on_save_pressed)
	toolbar.add_child(save_button)

	tabs = TabContainer.new()
	tabs.name = "Tabs"
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(tabs)

	outline_tree = Tree.new()
	outline_tree.name = "Outline"
	outline_tree.columns = 3
	outline_tree.set_column_title(0, "Line")
	outline_tree.set_column_title(1, "Kind")
	outline_tree.set_column_title(2, "Title")
	outline_tree.column_titles_visible = true
	tabs.add_child(outline_tree)

	timeline_tree = Tree.new()
	timeline_tree.name = "Timeline"
	timeline_tree.columns = 4
	timeline_tree.set_column_title(0, "#")
	timeline_tree.set_column_title(1, "Line")
	timeline_tree.set_column_title(2, "Type")
	timeline_tree.set_column_title(3, "Detail")
	timeline_tree.column_titles_visible = true
	tabs.add_child(timeline_tree)

	visual_timeline = TimelineEditorPanelScene.instantiate()
	visual_timeline.name = "Visual"
	visual_timeline.event_added.connect(_on_visual_panel_event_added)
	visual_timeline.event_selected.connect(_on_visual_panel_event_selected)
	visual_timeline.event_moved.connect(func(from_index: int, to_index: int): visual_event_moved.emit(from_index, to_index))
	visual_timeline.event_duplicated.connect(func(index: int): visual_event_duplicated.emit(index))
	visual_timeline.event_deleted.connect(func(index: int): visual_event_deleted.emit(index))
	visual_timeline.events_copied.connect(func(indices: Array): visual_events_copied.emit(indices))
	visual_timeline.events_pasted.connect(func(index: int): visual_events_pasted.emit(index))
	tabs.add_child(visual_timeline)

	var inspector := VBoxContainer.new()
	inspector.name = "Inspector"
	inspector.add_theme_constant_override("separation", 6)
	tabs.add_child(inspector)
	_build_inspector(inspector)

	diagnostics_label = RichTextLabel.new()
	diagnostics_label.name = "Diagnostics"
	diagnostics_label.bbcode_enabled = true
	diagnostics_label.fit_content = true
	tabs.add_child(diagnostics_label)

	templates_list = ItemList.new()
	templates_list.name = "Templates"
	templates_list.item_activated.connect(_on_template_activated)
	tabs.add_child(templates_list)


func _build_inspector(parent: VBoxContainer) -> void:
	var actions := HBoxContainer.new()
	actions.name = "Actions"
	actions.add_theme_constant_override("separation", 6)
	parent.add_child(actions)

	add_event_button = Button.new()
	add_event_button.name = "AddEventButton"
	add_event_button.text = "Add"
	add_event_button.pressed.connect(_on_add_event_pressed)
	actions.add_child(add_event_button)

	update_event_button = Button.new()
	update_event_button.name = "UpdateEventButton"
	update_event_button.text = "Update"
	update_event_button.pressed.connect(_on_update_event_pressed)
	actions.add_child(update_event_button)

	undo_button = Button.new()
	undo_button.name = "UndoButton"
	undo_button.text = "Undo"
	undo_button.pressed.connect(func(): visual_undo_requested.emit())
	actions.add_child(undo_button)

	redo_button = Button.new()
	redo_button.name = "RedoButton"
	redo_button.text = "Redo"
	redo_button.pressed.connect(func(): visual_redo_requested.emit())
	actions.add_child(redo_button)

	var form := GridContainer.new()
	form.name = "EventForm"
	form.columns = 2
	form.add_theme_constant_override("h_separation", 8)
	form.add_theme_constant_override("v_separation", 4)
	parent.add_child(form)

	_add_form_label(form, "Type")
	event_type_options = OptionButton.new()
	event_type_options.name = "TypeOptions"
	_add_event_type("Dialogue", &"dialogue")
	_add_event_type("Narration", &"narration")
	_add_event_type("Label", &"label")
	_add_event_type("Command", &"command")
	_add_event_type("Background", &"background")
	_add_event_type("Character", &"character")
	_add_event_type("Audio", &"audio")
	_add_event_type("Flow", &"flow")
	_add_event_type("Menu", &"menu")
	form.add_child(event_type_options)

	_add_form_label(form, "Name")
	name_edit = LineEdit.new()
	name_edit.name = "NameEdit"
	name_edit.placeholder_text = "label or asset id"
	form.add_child(name_edit)

	_add_form_label(form, "Speaker")
	speaker_edit = LineEdit.new()
	speaker_edit.name = "SpeakerEdit"
	speaker_edit.placeholder_text = "Narrator"
	form.add_child(speaker_edit)

	_add_form_label(form, "Command")
	command_edit = LineEdit.new()
	command_edit.name = "CommandEdit"
	command_edit.placeholder_text = "wait, bg, char, play_music"
	form.add_child(command_edit)

	_add_form_label(form, "Target")
	target_edit = LineEdit.new()
	target_edit.name = "TargetEdit"
	target_edit.placeholder_text = "jump target or call label"
	form.add_child(target_edit)

	_add_form_label(form, "Condition")
	condition_edit = LineEdit.new()
	condition_edit.name = "ConditionEdit"
	condition_edit.placeholder_text = "optional expression"
	form.add_child(condition_edit)

	_add_form_label(form, "Text / Args")
	text_edit = TextEdit.new()
	text_edit.name = "TextEdit"
	text_edit.custom_minimum_size = Vector2(240.0, 88.0)
	text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_child(text_edit)

	_add_form_label(form, "Choices")
	choices_edit = TextEdit.new()
	choices_edit.name = "ChoicesEdit"
	choices_edit.custom_minimum_size = Vector2(240.0, 88.0)
	choices_edit.placeholder_text = "Choice text | condition | target_label"
	form.add_child(choices_edit)

	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "Ready"
	parent.add_child(status_label)

	script_preview = TextEdit.new()
	script_preview.name = "ScriptPreview"
	script_preview.editable = false
	script_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	script_preview.custom_minimum_size = Vector2(300.0, 160.0)
	parent.add_child(script_preview)


func _add_form_label(parent: GridContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	parent.add_child(label)


func _add_event_type(label: String, event_type: StringName) -> void:
	event_type_options.add_item(label)
	var index := event_type_options.get_item_count() - 1
	event_type_options.set_item_metadata(index, event_type)


func _apply_outline(outline: Dictionary) -> void:
	outline_tree.clear()
	var root := outline_tree.create_item()
	var parents := {0: root}
	for item in outline.get("items", []):
		var depth := int(item.get("depth", 0))
		var parent: TreeItem = parents.get(depth, root)
		var row := outline_tree.create_item(parent)
		row.set_text(0, str(item.get("line", "")))
		row.set_text(1, str(item.get("kind", "")))
		row.set_text(2, str(item.get("title", "")))
		parents[depth + 1] = row


func _apply_timeline(timeline: Dictionary) -> void:
	timeline_tree.clear()
	var root := timeline_tree.create_item()
	for event in timeline.get("events", []):
		var row := timeline_tree.create_item(root)
		row.set_text(0, str(event.get("order", "")))
		row.set_text(1, str(event.get("line", "")))
		row.set_text(2, str(event.get("type", "")))
		row.set_text(3, _detail_for_event(event))


func _apply_diagnostics(report: Dictionary) -> void:
	var fragments: Array[String] = []
	var counts: Dictionary = report.get("counts", {})
	fragments.append("Errors: %s  Warnings: %s" % [counts.get("error", 0), counts.get("warning", 0)])
	for issue in report.get("issues", []):
		fragments.append("[%s] line %s: %s" % [issue.get("severity", "info"), issue.get("line", 0), issue.get("message", "")])
	diagnostics_label.text = "\n".join(fragments)


func _detail_for_event(event: Dictionary) -> String:
	if event.has("command"):
		return "@%s %s" % [event.get("command", ""), event.get("arguments", "")]
	if event.has("speaker"):
		return "%s: %s" % [event.get("speaker", ""), event.get("text", "")]
	if event.has("target"):
		return "%s %s" % [event.get("kind", ""), event.get("target", "")]
	if event.has("text"):
		return str(event.get("text", ""))
	return str(event.get("label", ""))


func _selected_event_type() -> StringName:
	if event_type_options == null or event_type_options.selected < 0:
		return &"dialogue"
	var metadata: Variant = event_type_options.get_item_metadata(event_type_options.selected)
	return StringName(str(metadata))


func _select_event_type(event_type: StringName) -> void:
	if event_type_options == null:
		return
	for index in range(event_type_options.get_item_count()):
		if StringName(str(event_type_options.get_item_metadata(index))) == event_type:
			event_type_options.select(index)
			return


func _form_data() -> Dictionary:
	var event_type := _selected_event_type()
	return {
		"type": String(event_type),
		"label": name_edit.text,
		"id": name_edit.text,
		"speaker": speaker_edit.text,
		"command": command_edit.text,
		"kind": command_edit.text,
		"target": target_edit.text,
		"condition": condition_edit.text,
		"text": text_edit.text,
		"arguments": text_edit.text,
		"choices_text": choices_edit.text,
	}


func _default_form_data(event_type: StringName) -> Dictionary:
	match event_type:
		&"label":
			return {"type": "label", "label": "next_scene"}
		&"dialogue":
			return {"type": "dialogue", "speaker": "Narrator", "text": "New line."}
		&"narration":
			return {"type": "narration", "text": "New narration."}
		&"command":
			return {"type": "command", "command": "wait", "arguments": "0.5"}
		&"background":
			return {"type": "background", "command": "bg", "id": "background_id"}
		&"character":
			return {"type": "character", "command": "char", "id": "character_id"}
		&"audio":
			return {"type": "audio", "command": "play_music", "id": "music_id"}
		&"flow":
			return {"type": "flow", "kind": "jump", "target": "next_scene"}
		&"menu":
			return {"type": "menu", "choices_text": "Continue |  | next_scene\nReturn |  | start"}
	return {"type": String(event_type), "text": ""}


func _fill_form_from_event(event: Dictionary) -> void:
	var event_type := StringName(str(event.get("type", "dialogue")))
	_select_event_type(event_type)
	name_edit.text = str(event.get("label", event.get("id", "")))
	speaker_edit.text = str(event.get("speaker", ""))
	command_edit.text = str(event.get("command", event.get("kind", "")))
	target_edit.text = str(event.get("target", ""))
	condition_edit.text = str(event.get("condition", ""))
	text_edit.text = str(event.get("text", event.get("arguments", "")))
	choices_edit.text = _choices_text_from_event(event)


func _choices_text_from_event(event: Dictionary) -> String:
	var lines: Array[String] = []
	for choice in event.get("choices", []):
		if not choice is Dictionary:
			continue
		var target := ""
		for action in choice.get("actions", []):
			if action is Dictionary and str(action.get("type", "")) == "flow":
				target = str(action.get("target", ""))
				break
		lines.append("%s | %s | %s" % [str(choice.get("text", "")), str(choice.get("condition", "")), target])
	return "\n".join(lines)


func _status_for_state(state: Dictionary) -> String:
	var counts: Dictionary = state.get("diagnostics", {}).get("counts", {})
	var marker := "modified" if bool(state.get("dirty", false)) else "saved"
	var save_info: Dictionary = state.get("save", {})
	if bool(save_info.get("ok", false)):
		return "Saved: %s" % str(save_info.get("path", ""))
	if state.has("error"):
		return str(state["error"])
	return "%s  errors:%s warnings:%s" % [marker, counts.get("error", 0), counts.get("warning", 0)]


func _update_inspector_buttons() -> void:
	if update_event_button == null:
		return
	update_event_button.disabled = selected_visual_index < 0


func _on_new_pressed() -> void:
	new_script_requested.emit(path_edit.text)


func _on_analyze_pressed() -> void:
	analyze_requested.emit(path_edit.text)


func _on_save_pressed() -> void:
	save_requested.emit(path_edit.text)


func _on_add_event_pressed() -> void:
	visual_event_added.emit(_selected_event_type(), _form_data())


func _on_update_event_pressed() -> void:
	if selected_visual_index >= 0:
		visual_event_updated.emit(selected_visual_index, _form_data())


func _on_visual_panel_event_added(event_type: StringName) -> void:
	_select_event_type(event_type)
	visual_event_added.emit(event_type, _default_form_data(event_type))


func _on_visual_panel_event_selected(index: int) -> void:
	selected_visual_index = index
	var visual_events = visual_timeline.get("events") if visual_timeline != null else []
	if index >= 0 and index < visual_events.size():
		_fill_form_from_event(visual_events[index])
	_update_inspector_buttons()


func _on_template_activated(index: int) -> void:
	var metadata: Variant = templates_list.get_item_metadata(index)
	template_requested.emit(StringName(str(metadata)))
