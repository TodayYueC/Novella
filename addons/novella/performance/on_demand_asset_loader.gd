extends RefCounted

class_name NovellaOnDemandAssetLoader

const CommandParser := preload("res://addons/novella/script/command_parser.gd")
const AssetIndex := preload("res://addons/novella/editor/asset_index.gd")

var command_parser := CommandParser.new()
var asset_index := AssetIndex.new()
var loaded_assets: Dictionary = {}
var dry_run: bool = true

func configure(options: Dictionary = {}) -> void:
	if options.has("dry_run"):
		dry_run = bool(options["dry_run"])


func build_plan(events: Array, index: Dictionary, options: Dictionary = {}) -> Dictionary:
	var references := collect_references(events)
	var resolved := asset_index.validate_references(index, references)
	var queue: Array = []
	for reference in resolved.get("valid_assets", []):
		var asset: Dictionary = reference.get("asset", {})
		queue.append({
			"id": str(reference.get("id", "")),
			"path": str(asset.get("path", "")),
			"category": str(asset.get("category", "")),
			"role": str(asset.get("role", "")),
			"command": str(reference.get("command", "")),
			"line": int(reference.get("line", 0)),
			"priority": _priority_for(reference, asset),
			"streaming": _should_stream(asset),
			"preload": false,
		})
	queue.sort_custom(func(a, b): return int(a.get("priority", 100)) < int(b.get("priority", 100)))
	return {
		"ok": bool(resolved.get("ok", true)),
		"dry_run": bool(options.get("dry_run", dry_run)),
		"queue": _dedupe_queue(queue),
		"missing_assets": resolved.get("missing_assets", []),
		"summary": _summary_for(queue, resolved),
	}


func collect_references(events: Array) -> Array:
	var references: Array = []
	_collect_event_references(events, references)
	return references


func load_next(plan: Dictionary, options: Dictionary = {}) -> Dictionary:
	var queue: Array = plan.get("queue", [])
	for entry_value in queue:
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value
		var asset_id := str(entry.get("id", ""))
		if loaded_assets.has(asset_id):
			continue
		return load_asset(entry, options)
	return {"ok": false, "empty": true, "loaded_assets": loaded_assets.keys()}


func load_window(plan: Dictionary, count: int = 4, options: Dictionary = {}) -> Dictionary:
	var loaded: Array = []
	for _i in range(maxi(1, count)):
		var result := load_next(plan, options)
		if not bool(result.get("ok", false)):
			break
		loaded.append(result)
	return {"ok": true, "loaded": loaded, "loaded_assets": loaded_assets.keys()}


func validate_audio_streaming(plan: Dictionary) -> Dictionary:
	var warnings: Array = []
	for entry in plan.get("queue", []):
		if not entry is Dictionary:
			continue
		if str(entry.get("category", "")) == "audio" and not bool(entry.get("streaming", false)):
			warnings.append({"id": entry.get("id", ""), "path": entry.get("path", ""), "message": "Audio entry is not marked for streaming."})
	return {"ok": warnings.is_empty(), "warnings": warnings}


func memory_report() -> Dictionary:
	return {
		"ok": true,
		"loaded_count": loaded_assets.size(),
		"loaded_ids": loaded_assets.keys(),
		"dry_run": dry_run,
	}


func load_asset(entry: Dictionary, options: Dictionary = {}) -> Dictionary:
	var asset_id := str(entry.get("id", ""))
	var path := str(entry.get("path", ""))
	var use_dry_run := bool(options.get("dry_run", dry_run))
	if asset_id.is_empty() or path.is_empty():
		return {"ok": false, "error": "Asset entry requires id and path."}
	if use_dry_run:
		loaded_assets[asset_id] = {"path": path, "resource": null, "dry_run": true}
		return {"ok": true, "id": asset_id, "path": path, "dry_run": true}
	if not ResourceLoader.exists(path):
		return {"ok": false, "id": asset_id, "path": path, "error": "Resource path does not exist."}
	var resource := ResourceLoader.load(path)
	if resource == null:
		return {"ok": false, "id": asset_id, "path": path, "error": "ResourceLoader returned null."}
	loaded_assets[asset_id] = {"path": path, "resource": resource, "dry_run": false}
	return {"ok": true, "id": asset_id, "path": path, "resource": resource}


func release_asset(asset_id: String) -> Dictionary:
	var existed := loaded_assets.erase(asset_id)
	return {"ok": true, "id": asset_id, "released": existed}


func release_unused(active_ids: Array) -> Dictionary:
	var released: Array = []
	for asset_id in loaded_assets.keys():
		if not active_ids.has(asset_id):
			loaded_assets.erase(asset_id)
			released.append(asset_id)
	return {"ok": true, "released": released, "remaining": loaded_assets.keys()}


func get_loaded_assets() -> Dictionary:
	return loaded_assets.duplicate(true)


func _collect_event_references(events: Array, references: Array) -> void:
	for event_value in events:
		if not event_value is Dictionary:
			continue
		var event: Dictionary = event_value
		var reference := _reference_for_event(event)
		if not reference.is_empty():
			references.append(reference)
		if event.has("children"):
			_collect_event_references(event["children"], references)
		if event.has("choices"):
			_collect_event_references(event["choices"], references)
		if event.has("branches"):
			for branch in event["branches"]:
				if branch is Dictionary and branch.has("children"):
					_collect_event_references(branch["children"], references)


func _reference_for_event(event: Dictionary) -> Dictionary:
	var command := StringName(str(event.get("command", "")))
	var id := str(event.get("id", _asset_id_from_argument(command, str(event.get("arguments", "")))))
	if id.is_empty():
		return {}
	var categories := _categories_for_command(command)
	if categories.is_empty():
		return {}
	return {"id": id, "categories": categories, "command": String(command), "line": int(event.get("line", 0))}


func _asset_id_from_argument(command: StringName, raw_arguments: String) -> String:
	var parsed := command_parser.parse_arguments(raw_arguments)
	var positional: Array = parsed.get("positional", [])
	var named: Dictionary = parsed.get("named", {})
	if [&"bg", &"scene", &"char", &"char_emotion", &"char_move", &"char_remove", &"play_music", &"play_se", &"play_voice", &"ambience"].has(command):
		if not positional.is_empty():
			return str(positional[0]).strip_edges().trim_prefix("\"").trim_suffix("\"")
	if [&"gallery", &"replay"].has(command) and named.has(&"asset"):
		return str(named[&"asset"]).strip_edges().get_file().get_basename()
	return ""


func _categories_for_command(command: StringName) -> Array:
	if [&"bg", &"scene"].has(command):
		return ["backgrounds"]
	if [&"char", &"char_emotion", &"char_move", &"char_remove"].has(command):
		return ["characters"]
	if [&"play_music", &"play_se", &"play_voice", &"ambience"].has(command):
		return ["audio"]
	if [&"gallery", &"replay"].has(command):
		return ["backgrounds", "characters", "other"]
	return []


func _priority_for(reference: Dictionary, asset: Dictionary) -> int:
	var command := str(reference.get("command", ""))
	if command == "scene" or command == "bg":
		return 10
	if command == "char":
		return 20
	if command.begins_with("play_voice") or command == "play_se":
		return 30
	if command == "play_music" or command == "ambience":
		return 40
	if str(asset.get("category", "")) == "audio":
		return 50
	return 100


func _should_stream(asset: Dictionary) -> bool:
	return str(asset.get("category", "")) == "audio" and ["ogg", "mp3", "wav"].has(str(asset.get("extension", "")))


func _dedupe_queue(queue: Array) -> Array:
	var seen: Dictionary = {}
	var result: Array = []
	for entry in queue:
		var key := str(entry.get("id", "")) + "|" + str(entry.get("path", ""))
		if seen.has(key):
			continue
		seen[key] = true
		result.append(entry)
	return result


func _summary_for(queue: Array, resolved: Dictionary) -> Dictionary:
	var by_category: Dictionary = {}
	for entry in queue:
		var category := str(entry.get("category", "other"))
		by_category[category] = int(by_category.get(category, 0)) + 1
	return {
		"total": _dedupe_queue(queue).size(),
		"missing": resolved.get("missing_assets", []).size(),
		"by_category": by_category,
	}
