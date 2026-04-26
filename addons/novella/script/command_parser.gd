extends RefCounted

class_name NovellaCommandParser

func parse_arguments(raw_arguments: String) -> Dictionary:
	var tokens := _split_arguments(raw_arguments)
	var positional: Array = []
	var named: Dictionary = {}
	for token in tokens:
		var token_text := str(token)
		var colon: int = token_text.find(":")
		if colon > 0:
			named[StringName(token_text.substr(0, colon).strip_edges())] = token_text.substr(colon + 1).strip_edges()
		else:
			positional.append(token_text)
	return {
		"positional": positional,
		"named": named,
		"raw": raw_arguments,
	}


func _split_arguments(raw_arguments: String) -> Array:
	var result: Array = []
	var current := ""
	var in_string := false
	var escaped := false
	for i in range(raw_arguments.length()):
		var ch := raw_arguments[i]
		if escaped:
			current += ch
			escaped = false
			continue
		if ch == "\\":
			current += ch
			escaped = true
			continue
		if ch == "\"":
			current += ch
			in_string = not in_string
			continue
		if ch == " " and not in_string:
			if not current.is_empty():
				result.append(current)
				current = ""
			continue
		current += ch
	if not current.is_empty():
		result.append(current)
	return result
