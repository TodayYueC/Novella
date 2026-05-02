extends RefCounted

class_name NovellaAudioManager

signal channel_changed(channel: StringName, state: Dictionary)

const SUPPORTED_EXTENSIONS := ["ogg", "wav", "mp3"]

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
var audio_library: Dictionary = {}
var voice_map: Dictionary = {}
var play_history: Array = []

func register_audio(audio_id: StringName, path: String, metadata: Dictionary = {}) -> Dictionary:
	audio_library[audio_id] = {
		"id": String(audio_id),
		"path": path,
		"extension": path.get_extension().to_lower(),
		"metadata": metadata.duplicate(true),
	}
	return {"ok": true, "audio": audio_library[audio_id].duplicate(true)}


func register_voice_line(speaker: StringName, line_id: Variant, audio_id: StringName, path: String = "", metadata: Dictionary = {}) -> Dictionary:
	if not path.is_empty() or not audio_library.has(audio_id):
		register_audio(audio_id, path, metadata)
	var key := _voice_key(speaker, line_id)
	voice_map[key] = {
		"speaker": String(speaker),
		"line_id": str(line_id),
		"audio_id": String(audio_id),
	}
	return {"ok": true, "key": key, "voice": voice_map[key].duplicate(true)}


func resolve_voice_id(speaker: StringName, line_id: Variant) -> StringName:
	var entry: Dictionary = voice_map.get(_voice_key(speaker, line_id), {})
	return StringName(str(entry.get("audio_id", "")))


func play_voice_for_line(speaker: StringName, line_id: Variant, options: Dictionary = {}) -> Dictionary:
	var voice_id := resolve_voice_id(speaker, line_id)
	if voice_id == &"":
		return {"ok": false, "missing": true, "speaker": String(speaker), "line_id": str(line_id)}
	return play(&"voice", voice_id, options)


func replay_voice(entry: Dictionary, options: Dictionary = {}) -> Dictionary:
	var voice_id := StringName(str(entry.get("voice", entry.get("voice_id", ""))))
	if voice_id == &"":
		voice_id = resolve_voice_id(StringName(str(entry.get("speaker", ""))), entry.get("line", entry.get("line_id", "")))
	if voice_id == &"":
		return {"ok": false, "missing": true, "entry": entry.duplicate(true)}
	return play(&"voice", voice_id, options)

func play(channel: StringName, audio_id: StringName, options: Dictionary = {}) -> Dictionary:
	var library_entry: Dictionary = audio_library.get(audio_id, {})
	var state := {
		"ok": true,
		"channel": String(channel),
		"id": String(audio_id),
		"path": str(options.get("path", library_entry.get("path", ""))),
		"volume": float(options.get("volume", volumes.get(channel, 1.0))),
		"fade": float(options.get("fade", 0.0)),
		"loop": _as_bool(options.get("loop", channel == &"bgm" or channel == &"bgs")),
		"wait": _as_bool(options.get("wait", false)),
		"playing": true,
	}
	channels[channel] = state
	play_history.append(state.duplicate(true))
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
	play_history.append(state.duplicate(true))
	channel_changed.emit(channel, state)
	return state


func set_volume(channel: StringName, volume: float) -> void:
	volumes[channel] = clampf(volume, 0.0, 1.0)


func validate_streams(require_paths: bool = false) -> Dictionary:
	var errors: Array = []
	for audio_id in audio_library:
		var item: Dictionary = audio_library[audio_id]
		var path := str(item.get("path", ""))
		var extension := path.get_extension().to_lower()
		if require_paths and path.is_empty():
			errors.append({"id": String(audio_id), "message": "Audio path is empty."})
		if not path.is_empty() and not SUPPORTED_EXTENSIONS.has(extension):
			errors.append({"id": String(audio_id), "path": path, "message": "Unsupported audio extension."})
	return {
		"ok": errors.is_empty(),
		"errors": errors,
		"count": audio_library.size(),
	}


func get_state() -> Dictionary:
	return {
		"channels": channels.duplicate(true),
		"volumes": volumes.duplicate(true),
		"audio_library": audio_library.duplicate(true),
		"voice_map": voice_map.duplicate(true),
		"play_history": play_history.duplicate(true),
	}


func restore_state(state: Dictionary) -> void:
	channels = state.get("channels", channels).duplicate(true)
	volumes = state.get("volumes", volumes).duplicate(true)
	audio_library = state.get("audio_library", audio_library).duplicate(true)
	voice_map = state.get("voice_map", voice_map).duplicate(true)
	play_history = state.get("play_history", play_history).duplicate(true)


func _voice_key(speaker: StringName, line_id: Variant) -> String:
	return "%s:%s" % [String(speaker), str(line_id)]


func _as_bool(value: Variant) -> bool:
	if value is bool:
		return value
	var text := str(value).to_lower()
	return text == "true" or text == "1" or text == "yes" or text == "on"
