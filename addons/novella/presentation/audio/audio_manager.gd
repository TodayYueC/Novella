extends RefCounted

class_name NovellaAudioManager

signal channel_changed(channel: StringName, state: Dictionary)

var channels: Dictionary = {
	&"bgm": {},
	&"bgs": {},
	&"se": {},
	&"voice": {},
}
var volumes: Dictionary = {
	&"master": 1.0,
	&"bgm": 1.0,
	&"bgs": 1.0,
	&"se": 1.0,
	&"voice": 1.0,
}

func play(channel: StringName, audio_id: StringName, options: Dictionary = {}) -> Dictionary:
	var state := {
		"ok": true,
		"channel": String(channel),
		"id": String(audio_id),
		"volume": float(options.get("volume", volumes.get(channel, 1.0))),
		"fade": float(options.get("fade", 0.0)),
		"loop": _as_bool(options.get("loop", channel == &"bgm" or channel == &"bgs")),
		"wait": _as_bool(options.get("wait", false)),
		"playing": true,
	}
	channels[channel] = state
	channel_changed.emit(channel, state)
	return state.duplicate(true)


func stop(channel: StringName, options: Dictionary = {}) -> Dictionary:
	var previous: Dictionary = channels.get(channel, {}).duplicate(true)
	var state := {
		"ok": true,
		"channel": String(channel),
		"previous": previous,
		"fade": float(options.get("fade", 0.0)),
		"playing": false,
	}
	channels[channel] = state
	channel_changed.emit(channel, state)
	return state


func set_volume(channel: StringName, volume: float) -> void:
	volumes[channel] = clampf(volume, 0.0, 1.0)


func get_state() -> Dictionary:
	return {
		"channels": channels.duplicate(true),
		"volumes": volumes.duplicate(true),
	}


func _as_bool(value: Variant) -> bool:
	if value is bool:
		return value
	var text := str(value).to_lower()
	return text == "true" or text == "1" or text == "yes" or text == "on"
