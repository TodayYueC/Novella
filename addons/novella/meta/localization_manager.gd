extends RefCounted

class_name NovellaLocalizationManager

signal locale_changed(previous_locale: StringName, next_locale: StringName)
signal translation_added(locale: StringName, key: StringName)
signal missing_translation(locale: StringName, key: StringName)

var default_locale: StringName = &"en"
var current_locale: StringName = &"en"
var fallback_locale: StringName = &"en"
var auto_translate_keys: bool = true
var catalogs: Dictionary = {}
var missing_keys: Dictionary = {}

func _init() -> void:
	add_locale(default_locale)


func configure(options: Dictionary = {}) -> void:
	if options.has("default_locale"):
		default_locale = StringName(str(options["default_locale"]))
	if options.has("fallback_locale"):
		fallback_locale = StringName(str(options["fallback_locale"]))
	if options.has("current_locale"):
		set_locale(StringName(str(options["current_locale"])))
	if options.has("auto_translate_keys"):
		auto_translate_keys = _as_bool(options["auto_translate_keys"])
	add_locale(default_locale)
	add_locale(fallback_locale)


func add_locale(locale: StringName, entries: Dictionary = {}, replace: bool = false) -> void:
	if replace or not catalogs.has(locale):
		catalogs[locale] = {}
	var catalog: Dictionary = catalogs[locale]
	for key in entries:
		catalog[StringName(str(key))] = str(entries[key])


func add_translation(locale: StringName, key: StringName, value: String) -> void:
	add_locale(locale)
	catalogs[locale][key] = value
	translation_added.emit(locale, key)


func set_locale(locale: StringName) -> Dictionary:
	add_locale(locale)
	var previous := current_locale
	current_locale = locale
	if previous != current_locale:
		locale_changed.emit(previous, current_locale)
	return {"ok": true, "locale": String(current_locale), "previous": String(previous)}


func has_translation(key: StringName, locale: StringName = &"") -> bool:
	var target := current_locale if locale == &"" else locale
	return catalogs.has(target) and catalogs[target].has(key)


func translate(key: StringName, replacements: Variant = {}, locale: StringName = &"") -> String:
	var target := current_locale if locale == &"" else locale
	var template := _lookup(key, target)
	if template == null:
		_record_missing(target, key)
		return String(key)
	return _format(str(template), replacements)


func localize_text(text: String, replacements: Variant = {}) -> String:
	var key := StringName("")
	if text.begins_with("$"):
		key = StringName(text.substr(1).strip_edges())
	elif text.begins_with("tr:"):
		key = StringName(text.substr(3).strip_edges())
	elif auto_translate_keys and has_translation(StringName(text)):
		key = StringName(text)
	if key == &"":
		return _format(text, replacements)
	return translate(key, replacements)


func get_available_locales() -> Array:
	var result: Array = []
	for locale in catalogs:
		result.append(String(locale))
	result.sort()
	return result


func get_missing_keys() -> Dictionary:
	return missing_keys.duplicate(true)


func export_csv(locale: StringName = &"", include_header: bool = true) -> String:
	var target := current_locale if locale == &"" else locale
	add_locale(target)
	var keys: Array = []
	for key in catalogs[target]:
		keys.append(String(key))
	keys.sort()
	var lines: Array = []
	if include_header:
		lines.append("key,text")
	for key_text in keys:
		var key := StringName(str(key_text))
		lines.append("%s,%s" % [_csv_escape(String(key)), _csv_escape(str(catalogs[target][key]))])
	return "\n".join(lines)


func import_csv(locale: StringName, csv_text: String, replace: bool = false) -> Dictionary:
	add_locale(locale, {}, replace)
	var rows := _parse_csv(csv_text)
	var imported := 0
	for row_index in range(rows.size()):
		var row: Array = rows[row_index]
		if row.size() < 2:
			continue
		if row_index == 0 and _is_csv_header(row):
			continue
		var key := StringName(str(row[0]).strip_edges())
		if key == &"":
			continue
		add_translation(locale, key, str(row[1]))
		imported += 1
	return {"ok": true, "locale": String(locale), "imported": imported}


func get_state() -> Dictionary:
	return {
		"default_locale": String(default_locale),
		"current_locale": String(current_locale),
		"fallback_locale": String(fallback_locale),
		"auto_translate_keys": auto_translate_keys,
		"catalogs": catalogs.duplicate(true),
		"missing_keys": missing_keys.duplicate(true),
	}


func restore_state(state: Dictionary) -> void:
	default_locale = StringName(str(state.get("default_locale", String(default_locale))))
	current_locale = StringName(str(state.get("current_locale", String(current_locale))))
	fallback_locale = StringName(str(state.get("fallback_locale", String(fallback_locale))))
	auto_translate_keys = _as_bool(state.get("auto_translate_keys", auto_translate_keys))
	catalogs = _string_name_catalogs(state.get("catalogs", catalogs))
	missing_keys = state.get("missing_keys", {}).duplicate(true)
	add_locale(default_locale)
	add_locale(fallback_locale)
	add_locale(current_locale)


func _lookup(key: StringName, locale: StringName) -> Variant:
	if catalogs.has(locale) and catalogs[locale].has(key):
		return catalogs[locale][key]
	if locale != fallback_locale and catalogs.has(fallback_locale) and catalogs[fallback_locale].has(key):
		return catalogs[fallback_locale][key]
	if locale != default_locale and catalogs.has(default_locale) and catalogs[default_locale].has(key):
		return catalogs[default_locale][key]
	return null


func _record_missing(locale: StringName, key: StringName) -> void:
	var locale_text := String(locale)
	if not missing_keys.has(locale_text):
		missing_keys[locale_text] = []
	if not missing_keys[locale_text].has(String(key)):
		missing_keys[locale_text].append(String(key))
	missing_translation.emit(locale, key)


func _format(template: String, replacements: Variant) -> String:
	var data := _replacement_dictionary(replacements)
	var output := template
	for key in data:
		output = output.replace("{%s}" % str(key), str(data[key]))
	return output


func _replacement_dictionary(replacements: Variant) -> Dictionary:
	if replacements is Dictionary:
		return replacements
	if replacements != null and replacements.has_method("to_expression_dictionary"):
		return replacements.to_expression_dictionary()
	return {}


func _string_name_catalogs(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for locale in source:
		var locale_name := StringName(str(locale))
		result[locale_name] = {}
		var catalog: Dictionary = source[locale]
		for key in catalog:
			result[locale_name][StringName(str(key))] = str(catalog[key])
	return result


func _csv_escape(value: String) -> String:
	if value.contains("\"") or value.contains(",") or value.contains("\n") or value.contains("\r"):
		return "\"%s\"" % value.replace("\"", "\"\"")
	return value


func _parse_csv(csv_text: String) -> Array:
	var rows: Array = []
	var row: Array = []
	var current := ""
	var in_quotes := false
	var index := 0
	while index < csv_text.length():
		var ch := csv_text[index]
		if in_quotes:
			if ch == "\"" and index + 1 < csv_text.length() and csv_text[index + 1] == "\"":
				current += "\""
				index += 2
				continue
			if ch == "\"":
				in_quotes = false
				index += 1
				continue
			current += ch
			index += 1
			continue
		if ch == "\"":
			in_quotes = true
			index += 1
			continue
		if ch == ",":
			row.append(current)
			current = ""
			index += 1
			continue
		if ch == "\n":
			row.append(current)
			rows.append(row)
			row = []
			current = ""
			index += 1
			continue
		if ch == "\r":
			index += 1
			continue
		current += ch
		index += 1
	if not current.is_empty() or not row.is_empty():
		row.append(current)
		rows.append(row)
	return rows


func _is_csv_header(row: Array) -> bool:
	return row.size() >= 2 and str(row[0]).strip_edges().to_lower() == "key" and str(row[1]).strip_edges().to_lower() == "text"


func _as_bool(value: Variant) -> bool:
	if value is bool:
		return value
	var text := str(value).strip_edges().to_lower()
	return text == "true" or text == "1" or text == "yes" or text == "on"
