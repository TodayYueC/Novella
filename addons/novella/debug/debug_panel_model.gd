extends RefCounted

class_name NovellaDebugPanelModel

const DeveloperTools := preload("res://addons/novella/debug/developer_tools.gd")
const FlowGraphBuilder := preload("res://addons/novella/debug/flow_graph_builder.gd")

var tools := DeveloperTools.new()
var graph_builder := FlowGraphBuilder.new()

func build_panels(vm: Variant, variable_manager: Variant, command_registry: Variant, root: Node = null, ast: Variant = null) -> Dictionary:
	return {
		"ok": true,
		"variables": tools.variable_watch(variable_manager),
		"trace": tools.trace_vm(vm),
		"console": {"available": command_registry != null and command_registry.has_method("execute")},
		"nodes": tools.inspect_nodes(root) if root != null else {"ok": true, "nodes": [], "count": 0},
		"performance": tools.performance_snapshot(root),
		"flow_graph": graph_builder.build(ast) if ast != null else {"nodes": [], "edges": [], "stats": {}},
	}


func execute_console_line(command_line: String, command_registry: Variant, context: Dictionary = {}) -> Dictionary:
	return tools.execute_console(command_line, command_registry, context)


func performance_panel(root: Node = null, baseline: Dictionary = {}) -> Dictionary:
	var snapshot := tools.performance_snapshot(root)
	if not baseline.is_empty():
		snapshot["baseline"] = baseline.duplicate(true)
		snapshot["fps_delta"] = float(snapshot.get("fps", 0.0)) - float(baseline.get("fps", 0.0))
	return snapshot


func flow_graph_panel(ast: Variant, unlocked_nodes: Array = []) -> Dictionary:
	var graph := graph_builder.build(ast)
	for node_id in unlocked_nodes:
		graph = graph_builder.unlock_node(graph, str(node_id))
	return graph
