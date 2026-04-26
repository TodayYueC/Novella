extends RefCounted

class_name NovellaAutoManager

const Constants := preload("res://addons/novella/core/constants.gd")

signal auto_changed(enabled: bool)
signal auto_advanced

var enabled: bool = false
var delay_seconds: float = Constants.DEFAULT_AUTO_DELAY
var per_character_seconds: float = 0.025
var wait_for_voice: bool = true
var prevented: bool = false

var _elapsed: float = 0.0

func configure(options: Dictionary = {}) -> void:
	if options.has("delay"):
		delay_seconds = maxf(0.0, float(options["delay"]))
	if options.has("per_character"):
		per_character_seconds = maxf(0.0, float(options["per_character"]))
	if options.has("voice_wait"):
		wait_for_voice = _as_bool(options["voice_wait"])


func start(options: Dictionary = {}) -> Dictionary:
	configure(options)
	if prevented:
		return {"ok": false, "prevented": true, "enabled": enabled}
	enabled = true
	_elapsed = 0.0
	auto_changed.emit(enabled)
	return {"ok": true, "enabled": enabled, "delay": delay_seconds}


func stop() -> Dictionary:
	enabled = false
	_elapsed = 0.0
	auto_changed.emit(enabled)
	return {"ok": true, "enabled": enabled}


func toggle(options: Dictionary = {}) -> Dictionary:
	if enabled:
		return stop()
	return start(options)


func prevent_auto() -> void:
	prevented = true
	stop()


func allow_auto() -> void:
	prevented = false


func advance(delta: float, visible_text: String = "", voice_playing: bool = false) -> bool:
	if not enabled or prevented:
		return false
	if wait_for_voice and voice_playing:
		_elapsed = 0.0
		return false
	_elapsed += maxf(0.0, delta)
	var target := delay_seconds + float(visible_text.length()) * per_character_seconds
	if _elapsed >= target:
		_elapsed = 0.0
		auto_advanced.emit()
		return true
	return false


func get_state() -> Dictionary:
	return {
		"enabled": enabled,
		"delay_seconds": delay_seconds,
		"per_character_seconds": per_character_seconds,
		"wait_for_voice": wait_for_voice,
		"prevented": prevented,
	}


func restore_state(state: Dictionary) -> void:
	enabled = _as_bool(state.get("enabled", enabled))
	delay_seconds = float(state.get("delay_seconds", delay_seconds))
	per_character_seconds = float(state.get("per_character_seconds", per_character_seconds))
	wait_for_voice = _as_bool(state.get("wait_for_voice", wait_for_voice))
	prevented = _as_bool(state.get("prevented", prevented))
	_elapsed = 0.0


func _as_bool(value: Variant) -> bool:
	if value is bool:
		return value
	var text := str(value).strip_edges().to_lower()
	return text == "true" or text == "1" or text == "yes" or text == "on"
