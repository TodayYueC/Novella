extends RefCounted

class_name NovellaAssetIndex

const IMAGE_EXTENSIONS := ["png", "jpg", "jpeg", "webp", "svg"]
const AUDIO_EXTENSIONS := ["ogg", "wav", "mp3"]

func build(paths: Array) -> Dictionary:
	var index := {
		"characters": [],
		"backgrounds": [],
		"audio": [],
		"scripts": [],
		"scenes": [],
		"other": [],
	}
	for path_value in paths:
		var path := str(path_value).replace("\\", "/")
		var category := _category_for(path)
		index[category].append(_asset_item(path, category))
	return index


func suggest_for_command(index: Dictionary, command_name: StringName) -> Array:
	if [&"char", &"char_emotion", &"char_move", &"char_remove"].has(command_name):
		return index.get("characters", []).duplicate(true)
	if [&"bg", &"scene"].has(command_name):
		return index.get("backgrounds", []).duplicate(true)
	if [&"play_music", &"play_se", &"play_voice", &"ambience", &"stop_music", &"stop_voice"].has(command_name):
		return index.get("audio", []).duplicate(true)
	return []


func flatten(index: Dictionary) -> Array:
	var result: Array = []
	for category in index:
		for item in index[category]:
			var copy: Dictionary = item.duplicate(true)
			copy["category"] = category
			result.append(copy)
	return result


func find_by_id(index: Dictionary, asset_id: String, categories: Array = []) -> Dictionary:
	var needle := asset_id.strip_edges().to_lower()
	if needle.is_empty():
		return {}
	for item in flatten(index):
		var category := str(item.get("category", ""))
		if not _matches_categories(category, categories):
			continue
		if _item_matches_id(item, needle):
			return item.duplicate(true)
	return {}


func find_by_path(index: Dictionary, asset_path: String) -> Dictionary:
	var normalized := asset_path.replace("\\", "/")
	for item in flatten(index):
		if str(item.get("path", "")) == normalized:
			return item.duplicate(true)
	return {}


func validate_references(index: Dictionary, references: Array) -> Dictionary:
	var valid: Array = []
	var missing: Array = []
	for reference_value in references:
		if not reference_value is Dictionary:
			continue
		var reference: Dictionary = reference_value
		var asset_id := str(reference.get("id", reference.get("asset_id", "")))
		var categories: Array = reference.get("categories", [])
		var found := find_by_id(index, asset_id, categories)
		if found.is_empty() and reference.has("path"):
			found = find_by_path(index, str(reference["path"]))
		var entry := reference.duplicate(true)
		if found.is_empty():
			missing.append(entry)
		else:
			entry["asset"] = found
			valid.append(entry)
	return {
		"ok": missing.is_empty(),
		"references": references.duplicate(true),
		"valid_assets": valid,
		"missing_assets": missing,
	}


func summarize(index: Dictionary) -> Dictionary:
	var summary := {
		"total": 0,
		"characters": int(index.get("characters", []).size()),
		"backgrounds": int(index.get("backgrounds", []).size()),
		"audio": int(index.get("audio", []).size()),
		"scripts": int(index.get("scripts", []).size()),
		"scenes": int(index.get("scenes", []).size()),
		"other": int(index.get("other", []).size()),
	}
	for key in summary:
		if key != "total":
			summary["total"] += int(summary[key])
	return summary


func _category_for(path: String) -> String:
	var lower := path.to_lower()
	var extension := path.get_extension().to_lower()
	if extension == "nvs":
		return "scripts"
	if extension == "tscn" or extension == "scn":
		return "scenes"
	if IMAGE_EXTENSIONS.has(extension):
		if lower.contains("/background") or lower.contains("/bg/"):
			return "backgrounds"
		if lower.contains("/character") or lower.contains("/portrait") or lower.contains("/sprite"):
			return "characters"
	if AUDIO_EXTENSIONS.has(extension):
		return "audio"
	return "other"


func _asset_item(path: String, category: String) -> Dictionary:
	var base_id := path.get_file().get_basename()
	return {
		"path": path,
		"id": base_id,
		"base_id": base_id,
		"extension": path.get_extension().to_lower(),
		"category": category,
		"role": _role_for(path, category),
		"tags": _tags_for(path, base_id),
	}


func _role_for(path: String, category: String) -> String:
	var lower := path.to_lower()
	match category:
		"characters":
			if lower.contains("portrait") or lower.contains("side"):
				return "portrait"
			if lower.contains("expression") or lower.contains("emotion"):
				return "expression"
			return "sprite"
		"backgrounds":
			if lower.contains("/cg/") or lower.contains("/gallery/"):
				return "cg"
			return "background"
		"audio":
			if lower.contains("/voice/") or lower.contains("voice"):
				return "voice"
			if lower.contains("/se/") or lower.contains("/sfx/"):
				return "se"
			if lower.contains("/bgm/") or lower.contains("music"):
				return "bgm"
			return "audio"
		"scripts":
			return "script"
		"scenes":
			return "scene"
	return "asset"


func _tags_for(path: String, base_id: String) -> Array:
	var tags: Array = []
	var lower := path.to_lower().replace("res://", "")
	var raw_parts := lower.replace(".", "/").replace("_", "/").replace("-", "/").split("/", false)
	for part in raw_parts:
		if not tags.has(part):
			tags.append(part)
	for part in base_id.to_lower().replace("_", "/").replace("-", "/").split("/", false):
		if not tags.has(part):
			tags.append(part)
	return tags


func _matches_categories(category: String, categories: Array) -> bool:
	return categories.is_empty() or categories.has(category)


func _item_matches_id(item: Dictionary, needle: String) -> bool:
	var id := str(item.get("id", "")).to_lower()
	var base_id := str(item.get("base_id", "")).to_lower()
	var path := str(item.get("path", "")).to_lower()
	if needle == id or needle == base_id:
		return true
	if id.contains(needle) or base_id.contains(needle):
		return true
	if path.contains("/%s/" % needle) or path.contains("/%s." % needle):
		return true
	var tags: Array = item.get("tags", [])
	return tags.has(needle)
