extends RefCounted

class_name NovellaScriptMigration

const CURRENT_SCRIPT_VERSION := "1.0"
const HEADER_PREFIX := "# novella_version:"

const DEPRECATED_COMMAND_ALIASES := {
	"@language": "@locale",
	"@achieve": "@achievement",
}


func detect_version(source: String) -> String:
	for raw_line in _normalize_lines(source):
		var trimmed := raw_line.strip_edges()
		if trimmed.begins_with(HEADER_PREFIX):
			return trimmed.substr(HEADER_PREFIX.length()).strip_edges()
	return "legacy"


func migrate(source: String, target_version: String = CURRENT_SCRIPT_VERSION) -> Dictionary:
	var warnings: Array[String] = []
	var from_version := detect_version(source)
	if target_version != CURRENT_SCRIPT_VERSION:
		return {
			"ok": false,
			"source": source,
			"from_version": from_version,
			"target_version": target_version,
			"warnings": warnings,
			"changes": ["Unsupported target script version '%s'." % target_version],
		}

	var changed_lines := _rewrite_command_aliases(_normalize_lines(source), warnings)
	var migrated := _with_version_header(changed_lines, target_version)
	var changes: Array[String] = []
	if from_version != target_version:
		changes.append("Updated script version header from '%s' to '%s'." % [from_version, target_version])
	if not warnings.is_empty():
		changes.append("Rewrote deprecated command aliases.")
	if changes.is_empty():
		changes.append("Script already matches the current Novella script version.")

	return {
		"ok": true,
		"source": migrated,
		"from_version": from_version,
		"target_version": target_version,
		"warnings": warnings,
		"changes": changes,
	}


func check_source(source: String) -> Dictionary:
	var version := detect_version(source)
	var warnings: Array[String] = []
	for raw_line in _normalize_lines(source):
		var command := _leading_command(raw_line)
		if DEPRECATED_COMMAND_ALIASES.has(command):
			warnings.append("Deprecated command '%s' should be migrated to '%s'." % [command, DEPRECATED_COMMAND_ALIASES[command]])
	return {
		"ok": version == CURRENT_SCRIPT_VERSION and warnings.is_empty(),
		"version": version,
		"current_version": CURRENT_SCRIPT_VERSION,
		"warnings": warnings,
	}


func _normalize_lines(source: String) -> Array[String]:
	var result: Array[String] = []
	for line in source.replace("\r\n", "\n").replace("\r", "\n").split("\n", true):
		result.append(line)
	return result


func _rewrite_command_aliases(lines: Array[String], warnings: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for line in lines:
		var command := _leading_command(line)
		if DEPRECATED_COMMAND_ALIASES.has(command):
			var replacement: String = DEPRECATED_COMMAND_ALIASES[command]
			var left_trimmed := line.strip_edges(true, false)
			var indent := line.substr(0, line.length() - left_trimmed.length())
			var suffix := left_trimmed.substr(command.length())
			result.append("%s%s%s" % [indent, replacement, suffix])
			warnings.append("Replaced '%s' with '%s'." % [command, replacement])
		else:
			result.append(line)
	return result


func _leading_command(line: String) -> String:
	var left_trimmed := line.strip_edges(true, false)
	if not left_trimmed.begins_with("@"):
		return ""
	var end := left_trimmed.find(" ")
	var tab := left_trimmed.find("\t")
	if end < 0 or (tab >= 0 and tab < end):
		end = tab
	if end < 0:
		return left_trimmed
	return left_trimmed.substr(0, end)


func _with_version_header(lines: Array[String], target_version: String) -> String:
	var output := lines.duplicate()
	for index in range(output.size()):
		var trimmed := str(output[index]).strip_edges()
		if trimmed.begins_with(HEADER_PREFIX):
			output[index] = "%s %s" % [HEADER_PREFIX, target_version]
			return "\n".join(output)
	output.insert(0, "%s %s" % [HEADER_PREFIX, target_version])
	return "\n".join(output)
