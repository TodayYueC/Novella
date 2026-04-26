extends RefCounted

class_name NovellaPresentationCommands

const CommandParser := preload("res://addons/novella/script/command_parser.gd")

var parser := CommandParser.new()
var character_manager: Variant
var background_manager: Variant
var audio_manager: Variant
var camera_director: Variant
var effect_manager: Variant
var printer_manager: Variant

func register_all(registry: Variant, managers: Dictionary) -> void:
	character_manager = managers.get("character_manager")
	background_manager = managers.get("background_manager")
	audio_manager = managers.get("audio_manager")
	camera_director = managers.get("camera_director")
	effect_manager = managers.get("effect_manager")
	printer_manager = managers.get("printer_manager")

	registry.register_command(&"char", Callable(self, "_command_char"))
	registry.register_command(&"char_remove", Callable(self, "_command_char_remove"))
	registry.register_command(&"char_move", Callable(self, "_command_char_move"))
	registry.register_command(&"char_emotion", Callable(self, "_command_char_emotion"))
	registry.register_command(&"char_effect", Callable(self, "_command_char_effect"))
	registry.register_command(&"bg", Callable(self, "_command_bg"))
	registry.register_command(&"bg_remove", Callable(self, "_command_bg_remove"))
	registry.register_command(&"scene", Callable(self, "_command_scene"))
	registry.register_command(&"env", Callable(self, "_command_env"))
	registry.register_command(&"play_music", Callable(self, "_command_play_music"))
	registry.register_command(&"stop_music", Callable(self, "_command_stop_music"))
	registry.register_command(&"play_se", Callable(self, "_command_play_se"))
	registry.register_command(&"play_voice", Callable(self, "_command_play_voice"))
	registry.register_command(&"stop_voice", Callable(self, "_command_stop_voice"))
	registry.register_command(&"ambience", Callable(self, "_command_ambience"))
	registry.register_command(&"camera", Callable(self, "_command_camera"))
	registry.register_command(&"camera_shake", Callable(self, "_command_camera_shake"))
	registry.register_command(&"camera_reset", Callable(self, "_command_camera_reset"))
	registry.register_command(&"shake", Callable(self, "_command_screen_shake"))
	registry.register_command(&"flash", Callable(self, "_command_flash"))
	registry.register_command(&"fade", Callable(self, "_command_fade"))
	registry.register_command(&"effect", Callable(self, "_command_effect"))
	registry.register_command(&"nvl_clear", Callable(self, "_command_nvl_clear"))


func _command_char(raw_arguments: String, _context: Dictionary) -> Dictionary:
	var parsed := _parse(raw_arguments)
	var positional: Array = parsed["positional"]
	if positional.is_empty():
		return {"ok": false, "error": "Invalid @char syntax. Expected '@char name [attributes...]'."}
	var character_id := StringName(str(positional[0]))
	var attributes := positional.slice(1)
	var options: Dictionary = parsed["named"]
	return character_manager.show_character(character_id, attributes, options)


func _command_char_remove(raw_arguments: String, _context: Dictionary) -> Dictionary:
	var parsed := _parse(raw_arguments)
	var character_id := _first_id(parsed)
	return character_manager.hide_character(character_id, parsed["named"])


func _command_char_move(raw_arguments: String, _context: Dictionary) -> Dictionary:
	var parsed := _parse(raw_arguments)
	var character_id := _first_id(parsed)
	var named: Dictionary = parsed["named"]
	return character_manager.move_character(character_id, named.get(&"pos", "center"), named)


func _command_char_emotion(raw_arguments: String, _context: Dictionary) -> Dictionary:
	var parsed := _parse(raw_arguments)
	var character_id := _first_id(parsed)
	var emotion := StringName(str(_argument(parsed, 1, parsed["named"].get(&"emotion", ""))))
	return character_manager.set_emotion(character_id, emotion, parsed["named"])


func _command_char_effect(raw_arguments: String, _context: Dictionary) -> Dictionary:
	var parsed := _parse(raw_arguments)
	var character_id := _first_id(parsed)
	var effect_name := StringName(str(_argument(parsed, 1, parsed["named"].get(&"effect", "shake"))))
	var params: Dictionary = parsed["named"].duplicate(true)
	params["character"] = String(character_id)
	return effect_manager.trigger_effect(effect_name, "character:%s" % character_id, params)


func _command_bg(raw_arguments: String, _context: Dictionary) -> Dictionary:
	var parsed := _parse(raw_arguments)
	return background_manager.show_background(_first_id(parsed), parsed["named"])


func _command_bg_remove(raw_arguments: String, _context: Dictionary) -> Dictionary:
	return background_manager.remove_background(_parse(raw_arguments)["named"])


func _command_scene(raw_arguments: String, _context: Dictionary) -> Dictionary:
	var parsed := _parse(raw_arguments)
	var result: Dictionary = background_manager.change_scene(_first_id(parsed), parsed["named"])
	if result.get("clear_characters", true) and character_manager != null:
		character_manager.clear()
	if result.get("reset_camera", true) and camera_director != null:
		camera_director.reset()
	return result


func _command_env(raw_arguments: String, _context: Dictionary) -> Dictionary:
	var parsed := _parse(raw_arguments)
	return background_manager.set_environment(_first_id(parsed), parsed["named"])


func _command_play_music(raw_arguments: String, _context: Dictionary) -> Dictionary:
	var parsed := _parse(raw_arguments)
	return audio_manager.play(&"bgm", _first_id(parsed), parsed["named"])


func _command_stop_music(raw_arguments: String, _context: Dictionary) -> Dictionary:
	return audio_manager.stop(&"bgm", _parse(raw_arguments)["named"])


func _command_play_se(raw_arguments: String, _context: Dictionary) -> Dictionary:
	var parsed := _parse(raw_arguments)
	return audio_manager.play(&"se", _first_id(parsed), parsed["named"])


func _command_play_voice(raw_arguments: String, _context: Dictionary) -> Dictionary:
	var parsed := _parse(raw_arguments)
	return audio_manager.play(&"voice", _first_id(parsed), parsed["named"])


func _command_stop_voice(raw_arguments: String, _context: Dictionary) -> Dictionary:
	return audio_manager.stop(&"voice", _parse(raw_arguments)["named"])


func _command_ambience(raw_arguments: String, _context: Dictionary) -> Dictionary:
	var parsed := _parse(raw_arguments)
	return audio_manager.play(&"bgs", _first_id(parsed), parsed["named"])


func _command_camera(raw_arguments: String, _context: Dictionary) -> Dictionary:
	return camera_director.move_camera(_parse(raw_arguments)["named"])


func _command_camera_shake(raw_arguments: String, _context: Dictionary) -> Dictionary:
	return camera_director.shake(_parse(raw_arguments)["named"])


func _command_camera_reset(raw_arguments: String, _context: Dictionary) -> Dictionary:
	return camera_director.reset(_parse(raw_arguments)["named"])


func _command_screen_shake(raw_arguments: String, _context: Dictionary) -> Dictionary:
	return effect_manager.trigger_effect(&"shake", "screen", _parse(raw_arguments)["named"])


func _command_flash(raw_arguments: String, _context: Dictionary) -> Dictionary:
	return effect_manager.trigger_effect(&"flash", "screen", _parse(raw_arguments)["named"])


func _command_fade(raw_arguments: String, _context: Dictionary) -> Dictionary:
	return effect_manager.trigger_effect(&"fade", "screen", _parse(raw_arguments)["named"])


func _command_effect(raw_arguments: String, _context: Dictionary) -> Dictionary:
	var parsed := _parse(raw_arguments)
	var effect_name := StringName(str(_argument(parsed, 0, parsed["named"].get(&"type", "shake"))))
	return effect_manager.trigger_effect(effect_name, str(parsed["named"].get(&"target", "screen")), parsed["named"])


func _command_nvl_clear(_raw_arguments: String, _context: Dictionary) -> Dictionary:
	if printer_manager != null and printer_manager.has_method("set_mode"):
		printer_manager.set_mode(&"nvl", {"clear": true})
	return {"ok": true, "cleared": "nvl"}


func _parse(raw_arguments: String) -> Dictionary:
	return parser.parse_arguments(raw_arguments)


func _first_id(parsed: Dictionary) -> StringName:
	return StringName(str(_argument(parsed, 0, "")))


func _argument(parsed: Dictionary, index: int, default_value: Variant = "") -> Variant:
	var positional: Array = parsed["positional"]
	if index < positional.size():
		return positional[index]
	return default_value
