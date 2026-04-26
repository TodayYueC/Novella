extends RefCounted

class_name NovellaScriptDiagnostics

func analyze(ast: Variant, parser_errors: Array = [], known_commands: Array = []) -> Dictionary:
	var issues: Array = []
	for error in parser_errors:
		issues.append(_issue("error", 0, str(error), "parser"))
	if ast == null:
		issues.append(_issue("error", 0, "Script could not be parsed.", "script"))
		return _result(issues)
	var labels := _collect_label_counts(ast.children)
	for label_name in labels:
		if int(labels[label_name]["count"]) > 1:
			issues.append(_issue("error", int(labels[label_name]["line"]), "Duplicate label '%s'." % label_name, "label"))
	_walk(ast.children, issues, labels, known_commands)
	if not labels.has(&"start") and not labels.has("start"):
		issues.append(_issue("warning", 0, "Script has no 'start' label.", "structure"))
	return _result(issues)


func _walk(nodes: Array, issues: Array, labels: Dictionary, known_commands: Array) -> void:
	for node in nodes:
		match node.kind:
			&"dialogue":
				if str(node.speaker).strip_edges().is_empty():
					issues.append(_issue("warning", node.line, "Dialogue line has no speaker.", "dialogue"))
				if str(node.text).strip_edges().is_empty():
					issues.append(_issue("warning", node.line, "Dialogue line has no text.", "dialogue"))
			&"narration":
				if str(node.text).strip_edges().is_empty():
					issues.append(_issue("warning", node.line, "Narration line has no text.", "narration"))
			&"command":
				if not known_commands.is_empty() and not known_commands.has(node.command_name) and not known_commands.has(String(node.command_name)):
					issues.append(_issue("warning", node.line, "Unknown command '@%s'." % node.command_name, "command"))
			&"jump":
				if not labels.has(node.target_label) and not labels.has(String(node.target_label)):
					issues.append(_issue("error", node.line, "Unknown jump target '%s'." % node.target_label, "flow"))
			&"call":
				if not labels.has(node.target_label) and not labels.has(String(node.target_label)):
					issues.append(_issue("error", node.line, "Unknown call target '%s'." % node.target_label, "flow"))
			&"menu":
				if node.choices.is_empty():
					issues.append(_issue("error", node.line, "Menu has no choices.", "choice"))
				for choice in node.choices:
					if str(choice.text).strip_edges().is_empty():
						issues.append(_issue("warning", choice.line, "Choice has empty text.", "choice"))
					if choice.actions.is_empty():
						issues.append(_issue("warning", choice.line, "Choice '%s' has no actions." % choice.text, "choice"))
					_walk(choice.actions, issues, labels, known_commands)
			&"if":
				if node.branches.is_empty():
					issues.append(_issue("warning", node.line, "If block has no branches.", "branch"))
				for branch in node.branches:
					_walk(branch.get("actions", []), issues, labels, known_commands)


func _collect_label_counts(nodes: Array) -> Dictionary:
	var labels: Dictionary = {}
	for node in nodes:
		if node.kind == &"label":
			var key := String(node.label_name)
			var data: Dictionary = labels.get(key, {"count": 0, "line": node.line})
			data["count"] = int(data.get("count", 0)) + 1
			data["line"] = int(data.get("line", node.line))
			labels[key] = data
		if node.kind == &"menu":
			for choice in node.choices:
				var nested := _collect_label_counts(choice.actions)
				_merge_label_counts(labels, nested)
		elif node.kind == &"if":
			for branch in node.branches:
				var nested := _collect_label_counts(branch.get("actions", []))
				_merge_label_counts(labels, nested)
	return labels


func _merge_label_counts(target: Dictionary, source: Dictionary) -> void:
	for label_name in source:
		var data: Dictionary = target.get(label_name, {"count": 0, "line": source[label_name].get("line", 0)})
		data["count"] = int(data.get("count", 0)) + int(source[label_name].get("count", 0))
		target[label_name] = data


func _issue(severity: String, line: int, message: String, code: String) -> Dictionary:
	return {"severity": severity, "line": line, "message": message, "code": code}


func _result(issues: Array) -> Dictionary:
	var counts := {"error": 0, "warning": 0, "info": 0}
	for issue in issues:
		var severity := str(issue.get("severity", "info"))
		counts[severity] = int(counts.get(severity, 0)) + 1
	return {
		"issues": issues,
		"counts": counts,
		"has_errors": int(counts.get("error", 0)) > 0,
	}
