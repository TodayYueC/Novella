extends RefCounted

class_name NovellaPerformanceBudget

var baselines: Dictionary = {}

func capture(root: Node = null, loaded_assets: Dictionary = {}) -> Dictionary:
	return {
		"ok": true,
		"fps": Engine.get_frames_per_second(),
		"memory_static": Performance.get_monitor(Performance.MEMORY_STATIC),
		"object_count": Performance.get_monitor(Performance.OBJECT_COUNT),
		"resource_count": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
		"node_count": _count_nodes(root) if root != null else Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"loaded_assets": loaded_assets.keys(),
	}


func set_baseline(name: StringName, snapshot: Dictionary) -> Dictionary:
	baselines[name] = snapshot.duplicate(true)
	return {"ok": true, "name": String(name), "baseline": baselines[name].duplicate(true)}


func compare(name: StringName, snapshot: Dictionary, budgets: Dictionary = {}) -> Dictionary:
	if not baselines.has(name):
		return {"ok": false, "error": "Unknown performance baseline '%s'." % String(name)}
	var baseline: Dictionary = baselines[name]
	var deltas := {
		"fps": float(snapshot.get("fps", 0.0)) - float(baseline.get("fps", 0.0)),
		"memory_static": float(snapshot.get("memory_static", 0.0)) - float(baseline.get("memory_static", 0.0)),
		"object_count": float(snapshot.get("object_count", 0.0)) - float(baseline.get("object_count", 0.0)),
		"resource_count": float(snapshot.get("resource_count", 0.0)) - float(baseline.get("resource_count", 0.0)),
		"node_count": float(snapshot.get("node_count", 0.0)) - float(baseline.get("node_count", 0.0)),
	}
	var violations: Array = []
	for key in budgets:
		if absf(float(deltas.get(key, 0.0))) > float(budgets[key]):
			violations.append({"metric": key, "delta": deltas[key], "budget": budgets[key]})
	return {"ok": violations.is_empty(), "baseline": baseline, "snapshot": snapshot.duplicate(true), "deltas": deltas, "violations": violations}


func get_state() -> Dictionary:
	return {"baselines": baselines.duplicate(true)}


func restore_state(state: Dictionary) -> void:
	baselines = state.get("baselines", baselines).duplicate(true)


func _count_nodes(node: Node) -> int:
	var count := 1
	for child in node.get_children():
		count += _count_nodes(child)
	return count
