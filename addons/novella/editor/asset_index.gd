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
		index[category].append({
			"path": path,
			"id": path.get_file().get_basename(),
			"extension": path.get_extension().to_lower(),
		})
	return index


func suggest_for_command(index: Dictionary, command_name: StringName) -> Array:
	if [&"char", &"char_emotion", &"char_move", &"char_remove"].has(command_name):
		return index.get("characters", []).duplicate(true)
	if [&"bg", &"scene"].has(command_name):
		return index.get("backgrounds", []).duplicate(true)
	if [&"play_music", &"play_se", &"play_voice", &"ambience"].has(command_name):
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
