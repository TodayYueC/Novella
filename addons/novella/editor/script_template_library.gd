extends RefCounted

class_name NovellaScriptTemplateLibrary

var templates: Dictionary = {
	&"adv_scene": {
		"name": "ADV Scene",
		"description": "ADV dialogue scene with background, character, choice, and ending.",
		"body": "@var affinity = 0\n\nlabel start:\n    @bg {background} transition:dissolve time:0.5\n    @char {character} {pose} {emotion} pos:center\n    {character}: {opening_line}\n    menu:\n        \"{choice_text}\":\n            @set affinity += 1\n            {character}: {choice_reply}\n    jump end\n\nlabel end:\n    {character}: {ending_line}\n",
	},
	&"nvl_scene": {
		"name": "NVL Scene",
		"description": "NVL narration page with clear and return to ADV.",
		"body": "label {label}:\n    @mode nvl\n    {narration}\n    @nvl_clear\n    @mode adv\n",
	},
	&"choice_block": {
		"name": "Choice Block",
		"description": "Conditional menu choice block.",
		"body": "menu:\n    \"{first_choice}\" if {first_condition}:\n        jump {first_target}\n    \"{second_choice}\":\n        jump {second_target}\n",
	},
	&"character_entrance": {
		"name": "Character Entrance",
		"description": "Character show, focus, line, and exit.",
		"body": "@char {character} {pose} {emotion} pos:{position} enter:{enter}\n{character}: {line}\n@char_remove {character} exit:{exit}\n",
	},
}

func list_templates() -> Array:
	var result: Array = []
	for template_id in templates:
		var template: Dictionary = templates[template_id]
		result.append({
			"id": String(template_id),
			"name": template.get("name", String(template_id)),
			"description": template.get("description", ""),
		})
	return result


func has_template(template_id: StringName) -> bool:
	return templates.has(template_id)


func get_template(template_id: StringName) -> Dictionary:
	return templates.get(template_id, {}).duplicate(true)


func render(template_id: StringName, replacements: Dictionary = {}) -> String:
	var template := get_template(template_id)
	var body := str(template.get("body", ""))
	for key in _default_values().keys():
		body = body.replace("{%s}" % key, str(replacements.get(key, _default_values()[key])))
	for key in replacements:
		body = body.replace("{%s}" % key, str(replacements[key]))
	return body


func _default_values() -> Dictionary:
	return {
		"background": "school_day",
		"character": "Ryone",
		"pose": "uniform",
		"emotion": "happy",
		"opening_line": "Welcome back.",
		"choice_text": "Talk",
		"choice_reply": "I wanted to hear your voice.",
		"ending_line": "See you soon.",
		"label": "memory",
		"narration": "The room grows quiet.",
		"first_choice": "Go",
		"first_condition": "affinity >= 1",
		"first_target": "go_path",
		"second_choice": "Stay",
		"second_target": "stay_path",
		"position": "center",
		"enter": "fade",
		"exit": "fade",
		"line": "I am here.",
	}
