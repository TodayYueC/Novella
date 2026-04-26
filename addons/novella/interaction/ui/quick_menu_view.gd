extends Control

class_name NovellaQuickMenuView

signal action_pressed(action_id: StringName)

var bar: HBoxContainer
var buttons: Array[Button] = []

func _ready() -> void:
	_build_ui()


func apply_actions(actions: Array) -> void:
	_build_ui()
	for button in buttons:
		button.queue_free()
	buttons.clear()
	for action in actions:
		if not bool(action.get("visible", true)):
			continue
		var button := Button.new()
		button.text = str(action.get("label", action.get("id", "")))
		button.disabled = not bool(action.get("enabled", true))
		button.custom_minimum_size = Vector2(72.0, 32.0)
		var action_id := StringName(str(action.get("id", "")))
		button.pressed.connect(_on_action_pressed.bind(action_id))
		bar.add_child(button)
		buttons.append(button)


func clear() -> void:
	_build_ui()
	for button in buttons:
		button.queue_free()
	buttons.clear()


func _build_ui() -> void:
	if bar != null:
		return
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 0.0
	offset_left = 16.0
	offset_top = 12.0
	offset_right = -16.0
	offset_bottom = 48.0
	bar = HBoxContainer.new()
	bar.name = "ActionBar"
	bar.anchor_right = 1.0
	bar.anchor_bottom = 1.0
	bar.alignment = BoxContainer.ALIGNMENT_END
	bar.add_theme_constant_override("separation", 6)
	add_child(bar)


func _on_action_pressed(action_id: StringName) -> void:
	action_pressed.emit(action_id)
