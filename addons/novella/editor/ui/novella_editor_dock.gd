@tool
extends Control

class_name NovellaEditorDock

signal analyze_requested(path: String)
signal template_requested(template_id: StringName)

var path_edit: LineEdit
var analyze_button: Button
var tabs: TabContainer
var outline_tree: Tree
var timeline_tree: Tree
var diagnostics_label: RichTextLabel
var templates_list: ItemList

func _ready() -> void:
	_build_ui()


func apply_analysis(analysis: Dictionary) -> void:
	_build_ui()
	path_edit.text = str(analysis.get("file_path", path_edit.text))
	_apply_outline(analysis.get("outline", {}))
	_apply_timeline(analysis.get("timeline", {}))
	_apply_diagnostics(analysis.get("diagnostics", {}))


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

	diagnostics_label = RichTextLabel.new()
	diagnostics_label.name = "Diagnostics"
	diagnostics_label.bbcode_enabled = true
	diagnostics_label.fit_content = true
	tabs.add_child(diagnostics_label)

	templates_list = ItemList.new()
	templates_list.name = "Templates"
	templates_list.item_activated.connect(_on_template_activated)
	tabs.add_child(templates_list)


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


func _on_analyze_pressed() -> void:
	analyze_requested.emit(path_edit.text)


func _on_template_activated(index: int) -> void:
	var metadata: Variant = templates_list.get_item_metadata(index)
	template_requested.emit(StringName(str(metadata)))
