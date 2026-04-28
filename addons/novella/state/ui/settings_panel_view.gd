extends Control

class_name NovellaSettingsPanelView

signal setting_changed(key: StringName, value: Variant)
signal reset_requested
signal close_requested

var root: VBoxContainer
var controls: Dictionary = {}
var _updating: bool = false

func _ready() -> void:
	_build_ui()


func apply_settings(settings: Dictionary) -> void:
	_build_ui()
	_updating = true
	_set_slider(&"text_speed", float(settings.get("text_speed", 35.0)))
	_set_slider(&"auto_delay", float(settings.get("auto_delay", 1.5)))
	_set_slider(&"master_volume", float(settings.get("master_volume", 1.0)))
	_set_slider(&"music_volume", float(settings.get("music_volume", 1.0)))
	_set_slider(&"voice_volume", float(settings.get("voice_volume", 1.0)))
	_set_slider(&"sfx_volume", float(settings.get("sfx_volume", 1.0)))
	_set_toggle(&"fullscreen", bool(settings.get("fullscreen", false)))
	_set_toggle(&"skip_unread", bool(settings.get("skip_unread", false)))
	_set_locale(str(settings.get("locale", "en")))
	_updating = false


func _build_ui() -> void:
	if root != null:
		return
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 48.0
	offset_top = 36.0
	offset_right = -48.0
	offset_bottom = -36.0

	root = VBoxContainer.new()
	root.name = "Root"
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var header := HBoxContainer.new()
	header.name = "Header"
	header.add_theme_constant_override("separation", 8)
	root.add_child(header)

	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "Settings"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var reset_button := Button.new()
	reset_button.name = "ResetButton"
	reset_button.text = "Reset"
	reset_button.pressed.connect(func(): reset_requested.emit())
	header.add_child(reset_button)

	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "Close"
	close_button.pressed.connect(func(): close_requested.emit())
	header.add_child(close_button)

	_add_slider(&"text_speed", "Text Speed", 1.0, 120.0, 1.0)
	_add_slider(&"auto_delay", "Auto Delay", 0.0, 10.0, 0.1)
	_add_slider(&"master_volume", "Master Volume", 0.0, 1.0, 0.01)
	_add_slider(&"music_volume", "Music Volume", 0.0, 1.0, 0.01)
	_add_slider(&"voice_volume", "Voice Volume", 0.0, 1.0, 0.01)
	_add_slider(&"sfx_volume", "SFX Volume", 0.0, 1.0, 0.01)
	_add_toggle(&"fullscreen", "Fullscreen")
	_add_toggle(&"skip_unread", "Skip Unread Text")
	_add_locale_picker()


func _add_slider(key: StringName, label_text: String, min_value: float, max_value: float, step: float) -> void:
	var row := HBoxContainer.new()
	row.name = "%sRow" % String(key)
	row.add_theme_constant_override("separation", 8)
	root.add_child(row)

	var label := Label.new()
	label.name = "Label"
	label.text = label_text
	label.custom_minimum_size = Vector2(140.0, 0.0)
	row.add_child(label)

	var slider := HSlider.new()
	slider.name = "Control"
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_on_slider_changed.bind(key))
	row.add_child(slider)
	controls[key] = slider


func _add_toggle(key: StringName, label_text: String) -> void:
	var toggle := CheckButton.new()
	toggle.name = "%sToggle" % String(key)
	toggle.text = label_text
	toggle.toggled.connect(_on_toggle_changed.bind(key))
	root.add_child(toggle)
	controls[key] = toggle


func _add_locale_picker() -> void:
	var row := HBoxContainer.new()
	row.name = "localeRow"
	row.add_theme_constant_override("separation", 8)
	root.add_child(row)

	var label := Label.new()
	label.text = "Language"
	label.custom_minimum_size = Vector2(140.0, 0.0)
	row.add_child(label)

	var picker := OptionButton.new()
	picker.name = "Control"
	for locale in ["en", "zh_CN", "ja"]:
		picker.add_item(locale)
	picker.item_selected.connect(_on_locale_selected)
	row.add_child(picker)
	controls[&"locale"] = picker


func _set_slider(key: StringName, value: float) -> void:
	if controls.has(key):
		controls[key].value = value


func _set_toggle(key: StringName, value: bool) -> void:
	if controls.has(key):
		controls[key].button_pressed = value


func _set_locale(locale: String) -> void:
	var picker: OptionButton = controls.get(&"locale")
	if picker == null:
		return
	for index in range(picker.item_count):
		if picker.get_item_text(index) == locale:
			picker.select(index)
			return
	picker.select(0)


func _on_slider_changed(value: float, key: StringName) -> void:
	if _updating:
		return
	setting_changed.emit(key, value)


func _on_toggle_changed(value: bool, key: StringName) -> void:
	if _updating:
		return
	setting_changed.emit(key, value)


func _on_locale_selected(index: int) -> void:
	if _updating:
		return
	var picker: OptionButton = controls.get(&"locale")
	if picker != null:
		setting_changed.emit(&"locale", picker.get_item_text(index))
