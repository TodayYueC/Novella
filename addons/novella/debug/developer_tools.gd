extends RefCounted

class_name NovellaDeveloperTools

func variable_watch(variable_manager: Variant) -> Dictionary:
	if variable_manager == null or not variable_manager.has_method("snapshot"):
		return {"ok": false, "error": "No compatible variable manager."}
	var snapshot: Dictionary = variable_manager.snapshot()
	return {
		"ok": true,
		"game": _string_key_dict(snapshot.get("game", {})),
		"global": _string_key_dict(snapshot.get("global", {})),
		"settings": _string_key_dict(snapshot.get("settings", {})),
		"declarations": _string_key_dict(snapshot.get("declarations", {})),
		"flags": snapshot.get("flags", []),
	}


func set_variable(variable_manager: Variant, variable_name: StringName, value: Variant, scope: int = -1) -> Dictionary:
	if variable_manager == null or not variable_manager.has_method("set_variable"):
		return {"ok": false, "error": "No compatible variable manager."}
	variable_manager.set_variable(variable_name, value, scope)
	return {"ok": true, "name": String(variable_name), "value": value, "scope": variable_manager.get_scope(variable_name)}


func trace_vm(vm: Variant) -> Dictionary:
	if vm == null:
		return {"ok": false, "error": "No VM."}
	return {
		"ok": true,
		"current_index": int(vm.get("current_index")) if _has_property(vm, "current_index") else -1,
		"waiting_for_advance": bool(vm.get("waiting_for_advance")) if _has_property(vm, "waiting_for_advance") else false,
		"waiting_for_choice": bool(vm.get("waiting_for_choice")) if _has_property(vm, "waiting_for_choice") else false,
		"pending_advance": vm.get_pending_advance() if vm.has_method("get_pending_advance") else {},
		"pending_choice": vm.get_pending_choice() if vm.has_method("get_pending_choice") else {},
		"transcript_count": vm.transcript.size() if _has_property(vm, "transcript") else 0,
		"call_stack_depth": vm.call_stack.size() if _has_property(vm, "call_stack") else 0,
		"finished": vm.is_finished() if vm.has_method("is_finished") else false,
	}


func execute_console(command_line: String, command_registry: Variant, context: Dictionary = {}) -> Dictionary:
	if command_registry == null or not command_registry.has_method("execute"):
		return {"ok": false, "error": "No compatible command registry."}
	var trimmed := command_line.strip_edges()
	if trimmed.is_empty():
		return {"ok": false, "error": "Console command is empty."}
	if trimmed.begins_with("@"):
		trimmed = trimmed.substr(1)
	var split_at := trimmed.find(" ")
	var command_name := trimmed
	var raw_arguments := ""
	if split_at >= 0:
		command_name = trimmed.substr(0, split_at).strip_edges()
		raw_arguments = trimmed.substr(split_at + 1).strip_edges()
	var result: Dictionary = command_registry.execute(StringName(command_name), raw_arguments, context)
	result["console_command"] = command_name
	result["console_arguments"] = raw_arguments
	return result


func performance_snapshot(root: Node = null) -> Dictionary:
	var node_count := 0
	if root != null:
		node_count = _count_nodes(root)
	return {
		"ok": true,
		"fps": Engine.get_frames_per_second(),
		"node_count": node_count,
		"monitors": _performance_monitors(),
	}


func inspect_nodes(root: Node, max_nodes: int = 128) -> Dictionary:
	if root == null:
		return {"ok": false, "error": "Root node is null.", "nodes": []}
	var rows: Array = []
	_collect_nodes(root, rows, max_nodes)
	return {"ok": true, "nodes": rows, "count": rows.size(), "truncated": rows.size() >= max_nodes}


func _performance_monitors() -> Dictionary:
	var monitors := {}
	var names := {
		"memory_static": Performance.MEMORY_STATIC,
		"object_count": Performance.OBJECT_COUNT,
		"resource_count": Performance.OBJECT_RESOURCE_COUNT,
		"node_count": Performance.OBJECT_NODE_COUNT,
	}
	for key in names:
		monitors[key] = Performance.get_monitor(names[key])
	return monitors


func _collect_nodes(node: Node, rows: Array, max_nodes: int) -> void:
	if rows.size() >= max_nodes:
		return
	rows.append({
		"path": str(node.get_path()),
		"name": node.name,
		"class": node.get_class(),
		"child_count": node.get_child_count(),
	})
	for child in node.get_children():
		_collect_nodes(child, rows, max_nodes)
		if rows.size() >= max_nodes:
			return


func _count_nodes(node: Node) -> int:
	var count := 1
	for child in node.get_children():
		count += _count_nodes(child)
	return count


func _string_key_dict(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in source:
		result[String(key)] = source[key]
	return result


func _has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if property.get("name", "") == property_name:
			return true
	return false
