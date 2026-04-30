extends RefCounted

class_name NovellaFlowGraphBuilder

func build(ast: Variant) -> Dictionary:
	var graph := {"nodes": [], "edges": [], "entry": "", "stats": {}}
	if ast == null:
		graph["stats"] = _stats(graph)
		return graph
	var label_nodes := _label_nodes(ast.children)
	graph["nodes"].append_array(label_nodes)
	if not label_nodes.is_empty():
		graph["entry"] = label_nodes[0]["id"]
	var current_label := ""
	_walk_nodes(ast.children, current_label, graph)
	graph["stats"] = _stats(graph)
	return graph


func unlock_node(graph: Dictionary, node_id: String, metadata: Dictionary = {}) -> Dictionary:
	var next_graph := graph.duplicate(true)
	for node in next_graph.get("nodes", []):
		if node.get("id", "") == node_id:
			node["unlocked"] = true
			node["unlock_metadata"] = metadata.duplicate(true)
	return next_graph


func apply_unlocks(graph: Dictionary, unlocked_ids: Array) -> Dictionary:
	var next_graph := graph.duplicate(true)
	for node in next_graph.get("nodes", []):
		node["unlocked"] = unlocked_ids.has(node.get("id", ""))
	return next_graph


func reachable_labels(graph: Dictionary, start_id: String = "") -> Array:
	var start := start_id if not start_id.is_empty() else str(graph.get("entry", ""))
	var reached: Array = []
	var queue: Array = [start]
	while not queue.is_empty():
		var current := str(queue.pop_front())
		if current.is_empty() or reached.has(current):
			continue
		reached.append(current)
		for edge in graph.get("edges", []):
			if edge.get("from", "") == current and not reached.has(edge.get("to", "")):
				queue.append(edge.get("to", ""))
	return reached


func _label_nodes(nodes: Array) -> Array:
	var result: Array = []
	for node in nodes:
		if node.kind == &"label":
			result.append({
				"id": _label_id(String(node.label_name)),
				"type": "label",
				"label": String(node.label_name),
				"title": String(node.label_name),
				"line": int(node.line),
				"unlocked": false,
			})
	return result


func _walk_nodes(nodes: Array, current_label: String, graph: Dictionary) -> String:
	var label := current_label
	for index in range(nodes.size()):
		var node = nodes[index]
		match node.kind:
			&"label":
				var previous := label
				label = String(node.label_name)
				if not previous.is_empty():
					_add_edge(graph, _label_id(previous), _label_id(label), "next", node.line)
			&"jump":
				_add_edge(graph, _label_id(label), _label_id(String(node.target_label)), "jump", node.line)
			&"call":
				_add_edge(graph, _label_id(label), _label_id(String(node.target_label)), "call", node.line)
			&"menu":
				for choice_index in range(node.choices.size()):
					var choice = node.choices[choice_index]
					var choice_id := "choice:%s:%s" % [choice.line, choice_index]
					_add_node_once(graph, {
						"id": choice_id,
						"type": "choice",
						"label": label,
						"title": choice.text,
						"condition": choice.condition,
						"line": int(choice.line),
						"unlocked": false,
					})
					_add_edge(graph, _label_id(label), choice_id, "choice", choice.line)
					_walk_choice_actions(choice.actions, choice_id, label, graph)
			&"if":
				for branch_index in range(node.branches.size()):
					var branch: Dictionary = node.branches[branch_index]
					var branch_id := "branch:%s:%s" % [branch.get("line", node.line), branch_index]
					_add_node_once(graph, {
						"id": branch_id,
						"type": "branch",
						"label": label,
						"title": str(branch.get("condition", "else")) if not str(branch.get("condition", "")).is_empty() else "else",
						"condition": str(branch.get("condition", "")),
						"line": int(branch.get("line", node.line)),
						"unlocked": false,
					})
					_add_edge(graph, _label_id(label), branch_id, "branch", int(branch.get("line", node.line)))
					_walk_choice_actions(branch.get("actions", []), branch_id, label, graph)
			&"while":
				var loop_id := "loop:%s" % node.line
				_add_node_once(graph, {
					"id": loop_id,
					"type": "loop",
					"label": label,
					"title": node.condition,
					"condition": node.condition,
					"line": int(node.line),
					"unlocked": false,
				})
				_add_edge(graph, _label_id(label), loop_id, "loop", node.line)
				_walk_choice_actions(node.actions, loop_id, label, graph)
	return label


func _walk_choice_actions(actions: Array, from_id: String, current_label: String, graph: Dictionary) -> void:
	var nested_label := current_label
	var linked := false
	for action in actions:
		match action.kind:
			&"jump":
				_add_edge(graph, from_id, _label_id(String(action.target_label)), "jump", action.line)
				linked = true
			&"call":
				_add_edge(graph, from_id, _label_id(String(action.target_label)), "call", action.line)
				linked = true
			&"label":
				nested_label = String(action.label_name)
				_add_edge(graph, from_id, _label_id(nested_label), "next", action.line)
				linked = true
			&"menu", &"if", &"while":
				var before_count: int = graph["edges"].size()
				_walk_nodes([action], nested_label, graph)
				if graph["edges"].size() > before_count:
					linked = true
	if not linked and not current_label.is_empty():
		_add_edge(graph, from_id, _label_id(current_label), "return", 0)


func _add_node_once(graph: Dictionary, node: Dictionary) -> void:
	for existing in graph["nodes"]:
		if existing.get("id", "") == node.get("id", ""):
			return
	graph["nodes"].append(node)


func _add_edge(graph: Dictionary, from_id: String, to_id: String, edge_type: String, line: int) -> void:
	if from_id.is_empty() or to_id.is_empty():
		return
	var edge := {"from": from_id, "to": to_id, "type": edge_type, "line": line}
	for existing in graph["edges"]:
		if existing.get("from", "") == edge["from"] and existing.get("to", "") == edge["to"] and existing.get("type", "") == edge["type"]:
			return
	graph["edges"].append(edge)


func _label_id(label_name: String) -> String:
	return "label:%s" % label_name


func _stats(graph: Dictionary) -> Dictionary:
	var counts: Dictionary = {}
	for node in graph.get("nodes", []):
		var node_type := str(node.get("type", "node"))
		counts[node_type] = int(counts.get(node_type, 0)) + 1
	return {
		"nodes": graph.get("nodes", []).size(),
		"edges": graph.get("edges", []).size(),
		"by_type": counts,
	}
