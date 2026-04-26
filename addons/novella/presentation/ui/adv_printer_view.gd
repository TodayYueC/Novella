extends Control

class_name NovellaAdvPrinterView

var name_label: Label
var text_label: RichTextLabel
var continue_label: Label

func _ready() -> void:
	_build_ui()


func apply_payload(payload: Dictionary) -> void:
	_build_ui()
	name_label.text = str(payload.get("speaker", ""))
	text_label.text = str(payload.get("text", ""))
	continue_label.visible = true


func clear() -> void:
	_build_ui()
	name_label.text = ""
	text_label.text = ""
	continue_label.visible = false


func set_hidden(hidden: bool) -> void:
	visible = not hidden


func _build_ui() -> void:
	if name_label != null:
		return
	anchor_left = 0.0
	anchor_top = 0.68
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 32.0
	offset_top = 0.0
	offset_right = -32.0
	offset_bottom = -24.0

	name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(name_label)

	text_label = RichTextLabel.new()
	text_label.name = "TextLabel"
	text_label.bbcode_enabled = true
	text_label.fit_content = true
	text_label.anchor_top = 0.2
	text_label.anchor_right = 1.0
	text_label.anchor_bottom = 0.9
	add_child(text_label)

	continue_label = Label.new()
	continue_label.name = "ContinueLabel"
	continue_label.text = "▼"
	continue_label.anchor_left = 0.95
	continue_label.anchor_top = 0.82
	continue_label.anchor_right = 1.0
	continue_label.anchor_bottom = 1.0
	add_child(continue_label)
