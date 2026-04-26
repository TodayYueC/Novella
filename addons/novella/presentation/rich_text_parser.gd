extends RefCounted

class_name NovellaRichTextParser

var inline_tag_pattern: RegEx
var color_tag_pattern: RegEx
var size_tag_pattern: RegEx
var font_tag_pattern: RegEx
var link_tag_pattern: RegEx
var ruby_tag_pattern: RegEx
var control_tag_pattern: RegEx

func _init() -> void:
	inline_tag_pattern = RegEx.create_from_string("\\{(/?)(b|i|u|s|wave|shake|rainbow)\\}")
	color_tag_pattern = RegEx.create_from_string("\\{color=([^}]+)\\}")
	size_tag_pattern = RegEx.create_from_string("\\{size=([^}]+)\\}")
	font_tag_pattern = RegEx.create_from_string("\\{font=([^}]+)\\}")
	link_tag_pattern = RegEx.create_from_string("\\{a=([^}]+)\\}")
	ruby_tag_pattern = RegEx.create_from_string("\\{rb=([^}]+)\\}([^{}]+)\\{/rb\\}")
	control_tag_pattern = RegEx.create_from_string("\\{(w|cps)=([^}]+)\\}|\\{(nw|fast)\\}")

func parse(text: String) -> Dictionary:
	var controls := _collect_controls(text)
	var bbcode := text
	bbcode = _replace_simple_tags(bbcode)
	bbcode = _replace_open_tag(bbcode, color_tag_pattern, "[color=$1]")
	bbcode = bbcode.replace("{/color}", "[/color]")
	bbcode = _replace_open_tag(bbcode, size_tag_pattern, "[font_size=$1]")
	bbcode = bbcode.replace("{/size}", "[/font_size]")
	bbcode = _replace_open_tag(bbcode, font_tag_pattern, "[font=$1]")
	bbcode = bbcode.replace("{/font}", "[/font]")
	bbcode = _replace_open_tag(bbcode, link_tag_pattern, "[url=$1]")
	bbcode = bbcode.replace("{/a}", "[/url]")
	bbcode = _replace_ruby_tags(bbcode)
	bbcode = control_tag_pattern.sub(bbcode, "", true)
	return {
		"bbcode": bbcode,
		"plain_text": strip_tags(text),
		"controls": controls,
	}


func strip_tags(text: String) -> String:
	var plain := text
	plain = ruby_tag_pattern.sub(plain, "$2", true)
	plain = inline_tag_pattern.sub(plain, "", true)
	plain = color_tag_pattern.sub(plain, "", true)
	plain = size_tag_pattern.sub(plain, "", true)
	plain = font_tag_pattern.sub(plain, "", true)
	plain = link_tag_pattern.sub(plain, "", true)
	plain = control_tag_pattern.sub(plain, "", true)
	plain = plain.replace("{/color}", "")
	plain = plain.replace("{/size}", "")
	plain = plain.replace("{/font}", "")
	plain = plain.replace("{/a}", "")
	return plain


func _replace_simple_tags(text: String) -> String:
	var output := text
	for tag in ["b", "i", "u", "s", "wave", "shake", "rainbow"]:
		output = output.replace("{%s}" % tag, "[%s]" % tag)
		output = output.replace("{/%s}" % tag, "[/%s]" % tag)
	return output


func _replace_open_tag(text: String, pattern: RegEx, replacement: String) -> String:
	return pattern.sub(text, replacement, true)


func _replace_ruby_tags(text: String) -> String:
	# Godot RichTextLabel has no built-in ruby annotation tag, so preserve both parts readably.
	return ruby_tag_pattern.sub(text, "$2($1)", true)


func _collect_controls(text: String) -> Array:
	var controls: Array = []
	for result in control_tag_pattern.search_all(text):
		var tag := str(result.get_string(1))
		var value := str(result.get_string(2))
		if tag.is_empty():
			tag = str(result.get_string(3))
		var offset := result.get_start()
		controls.append({
			"tag": tag,
			"value": value,
			"offset": offset,
		})
	return controls
