extends RefCounted

class_name NovellaScriptOutlineBuilder

func build(ast: Variant) -> Dictionary:
	var items: Array = []
	var stats := {
		"labels": 0,
		"dialogue": 0,
		"narration": 0,
		"commands": 0,
		"menus": 0,
		"choices": 0,
		"branches": 0,
		"jumps": 0,
		"calls": 0,
	}
	if ast == null:
		return {"items": items, "stats": stats, "file_path": ""}
	_collect_nodes(ast.children, items, stats, 0, "root")
	return {
		"items": items,
		"stats": stats,
		"file_path": ast.file_path,
	}


func _collect_nodes(nodes: Array, items: Array, stats: Dictionary, depth: int, parent_id: String) -> void:
	for index in range(nodes.size()):
		var node = nodes[index]
		var item_id := "%s/%s" % [parent_id, index]
		_count_node(node, stats)
		items.append({
			"id": item_id,
			"kind": String(node.kind),
			"title": _title_for(node),
			"line": int(node.line),
			"depth": depth,
			"index": index,
		})
		match node.kind:
			&"menu":
				for choice_index in range(node.choices.size()):
					var choice = node.choices[choice_index]
					stats["choices"] += 1
					var choice_id := "%s/choice%s" % [item_id, choice_index]
					items.append({
						"id": choice_id,
						"kind": "choice",
						"title": choice.text,
						"line": int(choice.line),
						"depth": depth + 1,
						"index": choice_index,
						"condition": choice.condition,
					})
					_collect_nodes(choice.actions, items, stats, depth + 2, choice_id)
			&"if":
				for branch_index in range(node.branches.size()):
					var branch: Dictionary = node.branches[branch_index]
					stats["branches"] += 1
					var branch_id := "%s/branch%s" % [item_id, branch_index]
					items.append({
						"id": branch_id,
						"kind": "branch",
						"title": str(branch.get("condition", "else")) if not str(branch.get("condition", "")).is_empty() else "else",
						"line": int(branch.get("line", node.line)),
						"depth": depth + 1,
						"index": branch_index,
					})
					_collect_nodes(branch.get("actions", []), items, stats, depth + 2, branch_id)


func _count_node(node: Variant, stats: Dictionary) -> void:
	match node.kind:
		&"label":
			stats["labels"] += 1
		&"dialogue":
			stats["dialogue"] += 1
		&"narration":
			stats["narration"] += 1
		&"command":
			stats["commands"] += 1
		&"menu":
			stats["menus"] += 1
		&"jump":
			stats["jumps"] += 1
		&"call":
			stats["calls"] += 1


func _title_for(node: Variant) -> String:
	match node.kind:
		&"label":
			return "label %s" % node.label_name
		&"dialogue":
			return "%s: %s" % [node.speaker, _shorten(node.text)]
		&"narration":
			return _shorten(node.text)
		&"command":
			return "@%s %s" % [node.command_name, node.raw_arguments]
		&"jump":
			return "jump %s" % node.target_label
		&"call":
			return "call %s" % node.target_label
		&"return":
			return "return"
		&"menu":
			return "menu"
		&"if":
			return "if"
	return String(node.kind)


func _shorten(text: String, max_length: int = 72) -> String:
	if text.length() <= max_length:
		return text
	return text.substr(0, max_length - 3) + "..."
