extends Control

class_name NovellaChoiceMenuView

signal choice_pressed(index: int)

var list: VBoxContainer
var buttons: Array[Button] = []

func _ready() -> void:
	_build_ui()


func apply_choices(choices: Array) -> void:
	_build_ui()
	for button in buttons:
		button.queue_free()
	buttons.clear()
	for choice in choices:
		var button := Button.new()
		button.text = str(choice.get("text", ""))
		button.disabled = bool(choice.get("disabled", not bool(choice.get("enabled", true))))
		button.custom_minimum_size = Vector2(240.0, 36.0)
		var index := int(choice.get("index", -1))
		button.pressed.connect(_on_choice_pressed.bind(index))
		list.add_child(button)
		buttons.append(button)


func clear() -> void:
	_build_ui()
	for button in buttons:
		button.queue_free()
	buttons.clear()


func _build_ui() -> void:
	if list != null:
		return
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	list = VBoxContainer.new()
	list.name = "ChoiceList"
	list.anchor_left = 0.5
	list.anchor_top = 0.45
	list.anchor_right = 0.5
	list.anchor_bottom = 0.45
	list.offset_left = -180.0
	list.offset_top = -120.0
	list.offset_right = 180.0
	list.offset_bottom = 120.0
	list.add_theme_constant_override("separation", 8)
	add_child(list)


func _on_choice_pressed(index: int) -> void:
	choice_pressed.emit(index)
