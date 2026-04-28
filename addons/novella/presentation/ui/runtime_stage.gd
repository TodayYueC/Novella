extends Control

class_name NovellaRuntimeStageView

signal advance_requested
signal ui_hidden_changed(hidden: bool)

const AdvPrinterScene := preload("res://addons/novella/presentation/ui/adv_printer.tscn")
const NvlPrinterScene := preload("res://addons/novella/presentation/ui/nvl_printer.tscn")

var background_layer: ColorRect
var background_label: Label
var character_layer: Control
var effect_layer: ColorRect
var effect_label: Label
var printer_layer: Control
var adv_view: Control
var nvl_view: Control
var status_label: Label
var hidden_ui: bool = false

func _ready() -> void:
	_build_ui()


func bind_managers(managers: Dictionary) -> void:
	_build_ui()
	var printer_manager = managers.get("printer_manager")
	if printer_manager != null:
		if printer_manager.has_signal("dialogue_presented"):
			printer_manager.dialogue_presented.connect(apply_line)
		if printer_manager.has_signal("narration_presented"):
			printer_manager.narration_presented.connect(apply_line)
	var background_manager = managers.get("background_manager")
	if background_manager != null and background_manager.has_signal("background_changed"):
		background_manager.background_changed.connect(apply_background)
	var character_manager = managers.get("character_manager")
	if character_manager != null:
		if character_manager.has_signal("character_shown"):
			character_manager.character_shown.connect(func(_id, _state): apply_characters(character_manager.get_scene_state()))
		if character_manager.has_signal("character_hidden"):
			character_manager.character_hidden.connect(func(_id): apply_characters(character_manager.get_scene_state()))
		if character_manager.has_signal("character_moved"):
			character_manager.character_moved.connect(func(_id, _position): apply_characters(character_manager.get_scene_state()))
	var effect_manager = managers.get("effect_manager")
	if effect_manager != null and effect_manager.has_signal("effect_triggered"):
		effect_manager.effect_triggered.connect(func(_name, _target, _params): apply_effects(effect_manager.get_state()))
	var camera_director = managers.get("camera_director")
	if camera_director != null:
		if camera_director.has_signal("camera_changed"):
			camera_director.camera_changed.connect(apply_camera)
		if camera_director.has_signal("camera_shaken"):
			camera_director.camera_shaken.connect(func(payload): apply_effects({"active_effects": [payload]}))
	var audio_manager = managers.get("audio_manager")
	if audio_manager != null and audio_manager.has_signal("channel_changed"):
		audio_manager.channel_changed.connect(func(_channel, _state): apply_audio(audio_manager.get_state()))


func apply_line(payload: Dictionary) -> void:
	_build_ui()
	var mode := StringName(str(payload.get("mode", "adv")))
	if mode == &"nvl":
		adv_view.visible = false
		nvl_view.visible = not hidden_ui
		if nvl_view.has_method("apply_payload"):
			nvl_view.apply_payload(payload)
	else:
		nvl_view.visible = false
		adv_view.visible = not hidden_ui
		if adv_view.has_method("apply_payload"):
			adv_view.apply_payload(payload)


func apply_background(state: Dictionary) -> void:
	_build_ui()
	var id_text := str(state.get("id", state.get("background", {}).get("id", "")))
	background_layer.color = _color_for_id(id_text)
	background_label.text = id_text
	status_label.text = "BG %s / %s" % [id_text, str(state.get("transition", ""))]


func apply_characters(characters: Variant) -> void:
	_build_ui()
	_clear_children(character_layer)
	var source: Dictionary = {}
	if characters is Dictionary and characters.has("characters"):
		source = characters["characters"]
	elif characters is Dictionary:
		source = characters
	for character_id in source:
		var state: Dictionary = source[character_id]
		character_layer.add_child(_build_character_marker(String(character_id), state))


func apply_effects(state: Dictionary) -> void:
	_build_ui()
	var effects: Array = state.get("active_effects", [])
	if effects.is_empty():
		effect_layer.color = Color(0.0, 0.0, 0.0, 0.0)
		effect_label.text = ""
		return
	var latest: Dictionary = effects.back()
	effect_layer.color = Color(1.0, 1.0, 1.0, clampf(float(latest.get("intensity", 0.35)) * 0.2, 0.05, 0.45))
	effect_label.text = "%s:%s" % [str(latest.get("effect", "effect")), str(latest.get("target", "screen"))]


func apply_audio(state: Dictionary) -> void:
	_build_ui()
	var labels: Array[String] = []
	var channels: Dictionary = state.get("channels", {})
	for channel in channels:
		var channel_state: Dictionary = channels[channel]
		if bool(channel_state.get("playing", false)):
			labels.append("%s:%s" % [String(channel), str(channel_state.get("id", ""))])
	status_label.text = "Audio %s" % ", ".join(labels)


func apply_camera(state: Dictionary) -> void:
	_build_ui()
	var zoom := _coerce_vector2(state.get("zoom", Vector2.ONE), Vector2.ONE)
	var pos := _coerce_vector2(state.get("pos", Vector2.ZERO), Vector2.ZERO)
	printer_layer.scale = zoom
	printer_layer.position = pos
	character_layer.scale = zoom
	character_layer.position = pos
	status_label.text = "Camera pos=%s zoom=%s" % [pos, zoom]


func set_ui_hidden(hidden: bool) -> void:
	hidden_ui = hidden
	adv_view.visible = not hidden and adv_view.visible
	nvl_view.visible = not hidden and nvl_view.visible
	ui_hidden_changed.emit(hidden_ui)


func clear() -> void:
	_build_ui()
	background_label.text = ""
	status_label.text = ""
	_clear_children(character_layer)
	effect_label.text = ""
	effect_layer.color = Color(0.0, 0.0, 0.0, 0.0)
	if adv_view.has_method("clear"):
		adv_view.clear()
	if nvl_view.has_method("clear"):
		nvl_view.clear()


func _build_ui() -> void:
	if background_layer != null:
		return
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0

	background_layer = ColorRect.new()
	background_layer.name = "BackgroundLayer"
	background_layer.anchor_right = 1.0
	background_layer.anchor_bottom = 1.0
	background_layer.color = Color(0.08, 0.08, 0.1, 1.0)
	add_child(background_layer)

	background_label = Label.new()
	background_label.name = "BackgroundLabel"
	background_label.anchor_right = 1.0
	background_label.anchor_bottom = 0.0
	background_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	background_label.offset_top = 24.0
	background_layer.add_child(background_label)

	character_layer = Control.new()
	character_layer.name = "CharacterLayer"
	character_layer.anchor_right = 1.0
	character_layer.anchor_bottom = 1.0
	add_child(character_layer)

	effect_layer = ColorRect.new()
	effect_layer.name = "EffectLayer"
	effect_layer.anchor_right = 1.0
	effect_layer.anchor_bottom = 1.0
	effect_layer.color = Color(0.0, 0.0, 0.0, 0.0)
	add_child(effect_layer)

	effect_label = Label.new()
	effect_label.name = "EffectLabel"
	effect_label.anchor_right = 1.0
	effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect_layer.add_child(effect_label)

	printer_layer = Control.new()
	printer_layer.name = "PrinterLayer"
	printer_layer.anchor_right = 1.0
	printer_layer.anchor_bottom = 1.0
	add_child(printer_layer)

	adv_view = AdvPrinterScene.instantiate()
	adv_view.name = "AdvPrinter"
	printer_layer.add_child(adv_view)

	nvl_view = NvlPrinterScene.instantiate()
	nvl_view.name = "NvlPrinter"
	nvl_view.visible = false
	printer_layer.add_child(nvl_view)

	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.anchor_right = 1.0
	status_label.anchor_bottom = 0.0
	status_label.offset_left = 12.0
	status_label.offset_top = 8.0
	add_child(status_label)


func _build_character_marker(character_id: String, state: Dictionary) -> Control:
	var marker := Label.new()
	marker.name = "Character_%s" % character_id
	marker.text = "%s\n%s" % [character_id, ", ".join(state.get("attributes", []))]
	marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	marker.custom_minimum_size = Vector2(160.0, 320.0)
	marker.anchor_left = float(state.get("position", 0.5))
	marker.anchor_top = 0.24
	marker.anchor_right = float(state.get("position", 0.5))
	marker.anchor_bottom = 0.88
	marker.offset_left = -80.0
	marker.offset_right = 80.0
	marker.modulate = Color(1.0, 1.0, 1.0, 1.0 if bool(state.get("focused", false)) else 0.72)
	return marker


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _color_for_id(id_text: String) -> Color:
	if id_text.is_empty():
		return Color(0.08, 0.08, 0.1, 1.0)
	var total := 0
	for i in range(id_text.length()):
		total += id_text.unicode_at(i)
	var hue := float(total % 360) / 360.0
	return Color.from_hsv(hue, 0.42, 0.45, 1.0)


func _coerce_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Dictionary and value.has("x") and value.has("y"):
		return Vector2(float(value["x"]), float(value["y"]))
	var text := str(value)
	if text.is_valid_float():
		var scalar := float(text)
		return Vector2(scalar, scalar)
	return fallback
