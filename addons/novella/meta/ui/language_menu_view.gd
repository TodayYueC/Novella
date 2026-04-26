extends Control

class_name NovellaLanguageMenuView

signal locale_selected(locale: StringName)

var option_button: OptionButton

func _ready() -> void:
	_build_ui()


func apply_locales(locales: Array, current_locale: StringName = &"") -> void:
	_build_ui()
	option_button.clear()
	var selected_index := -1
	for i in range(locales.size()):
		var locale_text := str(locales[i])
		option_button.add_item(locale_text)
		option_button.set_item_metadata(i, StringName(locale_text))
		if StringName(locale_text) == current_locale:
			selected_index = i
	if selected_index >= 0:
		option_button.select(selected_index)


func _build_ui() -> void:
	if option_button != null:
		return
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 0.0
	offset_left = 16.0
	offset_top = 16.0
	offset_right = -16.0
	offset_bottom = 52.0
	option_button = OptionButton.new()
	option_button.name = "LocaleOptions"
	option_button.anchor_right = 1.0
	option_button.anchor_bottom = 1.0
	option_button.item_selected.connect(_on_item_selected)
	add_child(option_button)


func _on_item_selected(index: int) -> void:
	var metadata: Variant = option_button.get_item_metadata(index)
	locale_selected.emit(StringName(str(metadata)))
