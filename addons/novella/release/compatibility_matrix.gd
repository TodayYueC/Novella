extends RefCounted

class_name NovellaCompatibilityMatrix

const Constants := preload("res://addons/novella/core/constants.gd")

const TARGETS := [
	{
		"version": "4.3",
		"major": 4,
		"minor": 3,
		"role": "minimum",
		"support": "targeted",
		"verified": false,
		"notes": "Minimum Godot 4.x compatibility target.",
	},
	{
		"version": "4.4",
		"major": 4,
		"minor": 4,
		"role": "compatibility",
		"support": "targeted",
		"verified": false,
		"notes": "Compatibility target pending local runtime verification.",
	},
	{
		"version": "4.5",
		"major": 4,
		"minor": 5,
		"role": "compatibility",
		"support": "targeted",
		"verified": false,
		"notes": "Compatibility target pending local runtime verification.",
	},
	{
		"version": "4.6",
		"major": 4,
		"minor": 6,
		"role": "primary",
		"support": "verified",
		"verified": true,
		"notes": "Primary development and release validation runtime.",
	},
]

var local_results: Dictionary = {}

func get_targets() -> Array:
	return TARGETS.duplicate(true)


func record_verification(version: String, passed: bool, notes: String = "") -> Dictionary:
	local_results[version] = {
		"version": version,
		"passed": passed,
		"notes": notes,
	}
	return local_results[version].duplicate(true)


func get_target(version: String) -> Dictionary:
	for target in TARGETS:
		if str(target.get("version", "")) == version:
			return target.duplicate(true)
	return {}


func get_minimum_target() -> Dictionary:
	return get_target("%s.%s" % [Constants.MIN_GODOT_MAJOR, Constants.MIN_GODOT_MINOR])


func get_primary_target() -> Dictionary:
	return get_target("%s.%s" % [Constants.PRIMARY_GODOT_MAJOR, Constants.PRIMARY_GODOT_MINOR])


func validate_primary() -> Dictionary:
	var issues: Array[String] = []
	if get_minimum_target().is_empty():
		issues.append("Compatibility matrix does not include the declared minimum Godot version.")
	if get_primary_target().is_empty():
		issues.append("Compatibility matrix does not include the declared primary Godot version.")
	for target in TARGETS:
		if int(target.get("major", 0)) != Constants.MIN_GODOT_MAJOR:
			issues.append("Novella v1.0 only supports the Godot 4 line; found %s." % target.get("version", "unknown"))
	return {
		"ok": issues.is_empty(),
		"issues": issues,
		"minimum": "%s.%s" % [Constants.MIN_GODOT_MAJOR, Constants.MIN_GODOT_MINOR],
		"primary": "%s.%s" % [Constants.PRIMARY_GODOT_MAJOR, Constants.PRIMARY_GODOT_MINOR],
	}


func compatibility_report() -> Dictionary:
	var targets := get_targets()
	var verified: Array = []
	var pending: Array = []
	for target in targets:
		var version := str(target.get("version", ""))
		var local: Dictionary = local_results.get(version, {})
		var is_verified := bool(target.get("verified", false)) or bool(local.get("passed", false))
		if is_verified:
			verified.append(version)
		else:
			pending.append(version)
	return {
		"ok": validate_primary()["ok"],
		"minimum": get_minimum_target(),
		"primary": get_primary_target(),
		"targets": targets,
		"verified": verified,
		"pending": pending,
		"local_results": local_results.duplicate(true),
	}


func api_compatibility_checks() -> Array:
	return [
		{"id": "godot_4_line", "ok": Constants.MIN_GODOT_MAJOR == 4, "message": "Novella targets the Godot 4 API line."},
		{"id": "minimum_4_3", "ok": Constants.MIN_GODOT_MINOR <= 3, "message": "Minimum target remains Godot 4.3+."},
		{"id": "primary_4_6", "ok": Constants.PRIMARY_GODOT_MINOR == 6, "message": "Primary validation runtime remains Godot 4.6."},
	]


func runtime_status(version_info: Dictionary = {}) -> Dictionary:
	var info := version_info
	if info.is_empty():
		info = Engine.get_version_info()
	var major := int(info.get("major", 0))
	var minor := int(info.get("minor", 0))
	var version := "%s.%s" % [major, minor]
	var supported := major == Constants.MIN_GODOT_MAJOR and minor >= Constants.MIN_GODOT_MINOR
	var primary := major == Constants.PRIMARY_GODOT_MAJOR and minor == Constants.PRIMARY_GODOT_MINOR
	var target := get_target(version)
	var support := "future-compatible" if supported and target.is_empty() else str(target.get("support", "unsupported"))
	if primary:
		support = "verified"
	return {
		"version": version,
		"supported": supported,
		"primary": primary,
		"target": target,
		"support": support,
		"message": _status_message(version, supported, primary, support),
	}


func _status_message(version: String, supported: bool, primary: bool, support: String) -> String:
	if not supported:
		return "Godot %s is outside Novella's Godot 4.3+ support target." % version
	if primary:
		return "Godot %s is Novella's primary verified runtime." % version
	return "Godot %s is supported in compatibility mode (%s)." % [version, support]
