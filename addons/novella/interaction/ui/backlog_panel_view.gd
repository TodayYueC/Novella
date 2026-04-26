extends Control

class_name NovellaBacklogPanelView

var text_label: RichTextLabel

func _ready() -> void:
	_build_ui()


func apply_entries(entries: Array) -> void:
	_build_ui()
	var fragments: Array[String] = []
	for entry in entries:
		var kind := str(entry.get("type", ""))
		var speaker := str(entry.get("speaker", ""))
		var text := str(entry.get("text", ""))
		if kind == "choice":
			fragments.append("> %s" % text)
		elif speaker.is_empty():
			fragments.append(text)
		else:
			fragments.append("%s: %s" % [speaker, text])
	text_label.text = "\n\n".join(fragments)


func clear() -> void:
	_build_ui()
	text_label.text = ""


func _build_ui() -> void:
	if text_label != null:
		return
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 48.0
	offset_top = 48.0
	offset_right = -48.0
	offset_bottom = -48.0
	text_label = RichTextLabel.new()
	text_label.name = "TextLabel"
	text_label.bbcode_enabled = true
	text_label.fit_content = true
	text_label.anchor_right = 1.0
	text_label.anchor_bottom = 1.0
	add_child(text_label)
