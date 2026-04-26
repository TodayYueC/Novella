extends RefCounted

class_name NovellaBacklogManager

signal entry_added(entry: Dictionary)
signal backlog_cleared
signal voice_replay_requested(entry: Dictionary)

var max_entries: int = 200
var entries: Array = []
var next_id: int = 1

func configure(options: Dictionary = {}) -> void:
	if options.has("max_entries"):
		max_entries = max(1, int(options["max_entries"]))
		_trim()


func add_dialogue(speaker: String, text: String, line: int, payload: Dictionary = {}) -> Dictionary:
	return add_entry({
		"type": "dialogue",
		"speaker": speaker,
		"text": text,
		"line": line,
		"voice": payload.get("voice", payload.get("voice_id", "")),
		"presentation": payload.duplicate(true),
	})


func add_narration(text: String, line: int, payload: Dictionary = {}) -> Dictionary:
	return add_entry({
		"type": "narration",
		"speaker": "",
		"text": text,
		"line": line,
		"voice": payload.get("voice", payload.get("voice_id", "")),
		"presentation": payload.duplicate(true),
	})


func add_choice(text: String, line: int, index: int) -> Dictionary:
	return add_entry({
		"type": "choice",
		"speaker": "",
		"text": text,
		"line": line,
		"choice_index": index,
	})


func add_entry(entry: Dictionary) -> Dictionary:
	var stored := entry.duplicate(true)
	stored["id"] = next_id
	next_id += 1
	entries.append(stored)
	_trim()
	entry_added.emit(stored.duplicate(true))
	return stored.duplicate(true)


func get_entries() -> Array:
	return entries.duplicate(true)


func clear() -> void:
	entries.clear()
	backlog_cleared.emit()


func request_voice_replay(entry_id: int) -> Dictionary:
	for entry in entries:
		if int(entry.get("id", -1)) == entry_id:
			var payload: Dictionary = entry.duplicate(true)
			voice_replay_requested.emit(payload)
			return {"ok": true, "entry": payload, "voice": payload.get("voice", "")}
	return {"ok": false, "error": "Backlog entry '%s' was not found." % entry_id}


func get_state() -> Dictionary:
	return {
		"entries": entries.duplicate(true),
		"next_id": next_id,
		"max_entries": max_entries,
	}


func restore_state(state: Dictionary) -> void:
	entries = state.get("entries", []).duplicate(true)
	next_id = int(state.get("next_id", next_id))
	max_entries = int(state.get("max_entries", max_entries))
	_trim()


func _trim() -> void:
	while entries.size() > max_entries:
		entries.pop_front()
