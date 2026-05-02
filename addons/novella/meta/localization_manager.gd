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
var typography_rules: Dictionary = {}
var asset_overrides: Dictionary = {}
var language_packs: Dictionary = {}

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


func configure_typography(locale: StringName, rules: Dictionary) -> Dictionary:
	typography_rules[locale] = rules.duplicate(true)
	return {"ok": true, "locale": String(locale), "typography": typography_rules[locale].duplicate(true)}


func typography_for(locale: StringName = &"") -> Dictionary:
	var target := current_locale if locale == &"" else locale
	return typography_rules.get(target, typography_rules.get(fallback_locale, {})).duplicate(true)


func add_asset_override(locale: StringName, asset_id: StringName, path: String) -> Dictionary:
	if not asset_overrides.has(locale):
		asset_overrides[locale] = {}
	asset_overrides[locale][asset_id] = path
	return {"ok": true, "locale": String(locale), "asset_id": String(asset_id), "path": path}


func resolve_asset(asset_id: StringName, locale: StringName = &"") -> String:
	var target := current_locale if locale == &"" else locale
	if asset_overrides.has(target) and asset_overrides[target].has(asset_id):
		return str(asset_overrides[target][asset_id])
	if target != fallback_locale and asset_overrides.has(fallback_locale) and asset_overrides[fallback_locale].has(asset_id):
		return str(asset_overrides[fallback_locale][asset_id])
	return String(asset_id)


func register_language_pack(pack_id: StringName, locale: StringName, data: Dictionary) -> Dictionary:
	language_packs[pack_id] = {
		"id": String(pack_id),
		"locale": String(locale),
		"entries": data.get("entries", {}).duplicate(true) if data.get("entries", {}) is Dictionary else {},
		"assets": data.get("assets", {}).duplicate(true) if data.get("assets", {}) is Dictionary else {},
		"typography": data.get("typography", {}).duplicate(true) if data.get("typography", {}) is Dictionary else {},
	}
	return {"ok": true, "pack": language_packs[pack_id].duplicate(true)}


func load_language_pack(pack_id: StringName) -> Dictionary:
	if not language_packs.has(pack_id):
		return {"ok": false, "error": "Unknown language pack '%s'." % String(pack_id)}
	var pack: Dictionary = language_packs[pack_id]
	var locale := StringName(str(pack.get("locale", current_locale)))
	add_locale(locale, pack.get("entries", {}), false)
	for asset_id in pack.get("assets", {}):
		add_asset_override(locale, StringName(str(asset_id)), str(pack["assets"][asset_id]))
	configure_typography(locale, pack.get("typography", {}))
	return {"ok": true, "locale": String(locale), "pack": pack.duplicate(true)}


func plural(key_base: StringName, count: int, replacements: Variant = {}, locale: StringName = &"") -> String:
	var suffix := "one" if count == 1 else "other"
	var data := _replacement_dictionary(replacements)
	data["count"] = count
	return translate(StringName("%s.%s" % [String(key_base), suffix]), data, locale)


func split_translation(locale: StringName, key: StringName, parts: Array) -> Dictionary:
	add_locale(locale)
	var keys: Array = []
	for index in range(parts.size()):
		var part_key := StringName("%s.%s" % [String(key), index + 1])
		add_translation(locale, part_key, str(parts[index]))
		keys.append(String(part_key))
	return {"ok": true, "locale": String(locale), "base": String(key), "keys": keys}


func merge_translations(locale: StringName, keys: Array, separator: String = "\n") -> String:
	var parts: Array[String] = []
	for key_value in keys:
		parts.append(translate(StringName(str(key_value)), {}, locale))
	return separator.join(parts)


func export_template(keys: Array, locale: StringName = &"", include_existing: bool = true) -> String:
	var target := current_locale if locale == &"" else locale
	add_locale(target)
	var unique_keys := _unique_sorted_keys(keys)
	var lines := ["key,text"]
	for key_text in unique_keys:
		var key := StringName(str(key_text))
		var value := ""
		if include_existing and catalogs[target].has(key):
			value = str(catalogs[target][key])
		lines.append("%s,%s" % [_csv_escape(String(key)), _csv_escape(value)])
	return "\n".join(lines)


func merge_missing_keys(locale: StringName = &"") -> Dictionary:
	var target := current_locale if locale == &"" else locale
	add_locale(target)
	var locale_text := String(target)
	var added := 0
	for key_text in missing_keys.get(locale_text, []):
		var key := StringName(str(key_text))
		if not catalogs[target].has(key):
			catalogs[target][key] = String(key)
			added += 1
	return {"ok": true, "locale": locale_text, "added": added}


func coverage_report(keys: Array, locales: Array = []) -> Dictionary:
	var unique_keys := _unique_sorted_keys(keys)
	var target_locales := locales.duplicate()
	if target_locales.is_empty():
		target_locales = get_available_locales()
	var by_locale: Dictionary = {}
	for locale_value in target_locales:
		var locale := StringName(str(locale_value))
		add_locale(locale)
		var translated := 0
		var missing: Array = []
		for key_text in unique_keys:
			var key := StringName(str(key_text))
			if catalogs[locale].has(key) and not str(catalogs[locale][key]).strip_edges().is_empty():
				translated += 1
			else:
				missing.append(String(key))
		by_locale[String(locale)] = {
			"translated": translated,
			"total": unique_keys.size(),
			"missing": missing,
			"percent": 100.0 if unique_keys.is_empty() else (float(translated) / float(unique_keys.size())) * 100.0,
		}
	return {"keys": unique_keys, "locales": by_locale}


func get_state() -> Dictionary:
	return {
		"default_locale": String(default_locale),
		"current_locale": String(current_locale),
		"fallback_locale": String(fallback_locale),
		"auto_translate_keys": auto_translate_keys,
		"catalogs": catalogs.duplicate(true),
		"missing_keys": missing_keys.duplicate(true),
		"typography_rules": typography_rules.duplicate(true),
		"asset_overrides": asset_overrides.duplicate(true),
		"language_packs": language_packs.duplicate(true),
	}


func restore_state(state: Dictionary) -> void:
	default_locale = StringName(str(state.get("default_locale", String(default_locale))))
	current_locale = StringName(str(state.get("current_locale", String(current_locale))))
	fallback_locale = StringName(str(state.get("fallback_locale", String(fallback_locale))))
	auto_translate_keys = _as_bool(state.get("auto_translate_keys", auto_translate_keys))
	catalogs = _string_name_catalogs(state.get("catalogs", catalogs))
	missing_keys = state.get("missing_keys", {}).duplicate(true)
	typography_rules = _string_name_nested_dict(state.get("typography_rules", typography_rules))
	asset_overrides = _string_name_nested_dict(state.get("asset_overrides", asset_overrides))
	language_packs = _string_name_nested_dict(state.get("language_packs", language_packs))
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


func _string_name_nested_dict(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in source:
		result[StringName(str(key))] = source[key].duplicate(true) if source[key] is Dictionary else source[key]
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


func _unique_sorted_keys(keys: Array) -> Array:
	var result: Array = []
	for key_value in keys:
		var key := str(key_value).strip_edges()
		if not key.is_empty() and not result.has(key):
			result.append(key)
	result.sort()
	return result


func _as_bool(value: Variant) -> bool:
	if value is bool:
		return value
	var text := str(value).strip_edges().to_lower()
	return text == "true" or text == "1" or text == "yes" or text == "on"
