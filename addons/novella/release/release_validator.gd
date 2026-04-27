extends RefCounted

class_name NovellaReleaseValidator

const Constants := preload("res://addons/novella/core/constants.gd")
const ReleaseManifest := preload("res://addons/novella/release/release_manifest.gd")

var manifest := ReleaseManifest.new()

func validate_release(file_list: Array, plugin_cfg_text: String = "", options: Dictionary = {}) -> Dictionary:
	var issues: Array = []
	var normalized_files := _normalize_file_list(file_list)
	_validate_required_files(normalized_files, issues)
	_validate_forbidden_files(normalized_files, issues)
	_validate_package_roots(normalized_files, issues)
	if not plugin_cfg_text.is_empty():
		_validate_plugin_cfg(plugin_cfg_text, issues)
	if not bool(options.get("allow_pre_1_0", false)) and not Constants.VERSION.begins_with("1.0."):
		issues.append(_issue("error", "version", "Release version must be in the 1.0 line. Current: %s." % Constants.VERSION))
	return _result(issues)


func package_files(file_list: Array) -> Array:
	var result: Array = []
	for raw_path in file_list:
		var path := _normalize_path(str(raw_path))
		if manifest.should_package_path(path):
			result.append(path)
	result.sort()
	return result


func validate_version_pair(plugin_cfg_text: String) -> Dictionary:
	var issues: Array = []
	_validate_plugin_cfg(plugin_cfg_text, issues)
	return _result(issues)


func _validate_required_files(files: Array, issues: Array) -> void:
	for required in ReleaseManifest.REQUIRED_FILES:
		if not files.has(required):
			issues.append(_issue("error", "required_file", "Missing required release file '%s'." % required))


func _validate_forbidden_files(files: Array, issues: Array) -> void:
	for path in files:
		if _is_forbidden_path(path):
			issues.append(_issue("error", "forbidden_file", "Forbidden release path is tracked: '%s'." % path))


func _validate_package_roots(files: Array, issues: Array) -> void:
	var package_files_list := package_files(files)
	if package_files_list.is_empty():
		issues.append(_issue("error", "package", "Package file list is empty."))
	if not package_files_list.has("addons/novella/plugin.cfg"):
		issues.append(_issue("error", "package", "Package does not include plugin.cfg."))


func _validate_plugin_cfg(plugin_cfg_text: String, issues: Array) -> void:
	var parsed := _parse_plugin_cfg(plugin_cfg_text)
	for key in ["name", "description", "author", "version", "script"]:
		if not parsed.has(key) or str(parsed[key]).is_empty():
			issues.append(_issue("error", "plugin_cfg", "plugin.cfg is missing '%s'." % key))
	if parsed.get("name", "") != "Novella":
		issues.append(_issue("error", "plugin_cfg", "plugin.cfg name must be Novella."))
	if parsed.get("script", "") != "novella_editor_plugin.gd":
		issues.append(_issue("error", "plugin_cfg", "plugin.cfg script must point to novella_editor_plugin.gd."))
	if parsed.get("version", "") != Constants.VERSION:
		issues.append(_issue("error", "version", "plugin.cfg version '%s' does not match Constants.VERSION '%s'." % [parsed.get("version", ""), Constants.VERSION]))


func _parse_plugin_cfg(text: String) -> Dictionary:
	var result: Dictionary = {}
	var lines := text.replace("\r\n", "\n").replace("\r", "\n").split("\n", false)
	for line in lines:
		var trimmed := line.strip_edges()
		if trimmed.is_empty() or trimmed.begins_with("[") or trimmed.begins_with(";") or trimmed.begins_with("#"):
			continue
		var equals := trimmed.find("=")
		if equals <= 0:
			continue
		var key := trimmed.substr(0, equals).strip_edges()
		var value := trimmed.substr(equals + 1).strip_edges()
		if value.begins_with("\"") and value.ends_with("\"") and value.length() >= 2:
			value = value.substr(1, value.length() - 2)
		result[key] = value
	return result


func _normalize_file_list(file_list: Array) -> Array:
	var result: Array = []
	for raw_path in file_list:
		result.append(_normalize_path(str(raw_path)))
	result.sort()
	return result


func _normalize_path(path: String) -> String:
	return path.replace("\\", "/").trim_prefix("./").strip_edges()


func _is_forbidden_path(path: String) -> bool:
	for marker in ReleaseManifest.FORBIDDEN_PATH_MARKERS:
		if path.contains(marker):
			return true
	for extension in ReleaseManifest.FORBIDDEN_EXTENSIONS:
		if path.to_lower().ends_with(extension):
			return true
	return false


func _issue(severity: String, code: String, message: String) -> Dictionary:
	return {"severity": severity, "code": code, "message": message}


func _result(issues: Array) -> Dictionary:
	var counts := {"error": 0, "warning": 0, "info": 0}
	for issue in issues:
		var severity := str(issue.get("severity", "info"))
		counts[severity] = int(counts.get(severity, 0)) + 1
	return {
		"ok": int(counts.get("error", 0)) == 0,
		"issues": issues,
		"counts": counts,
	}
