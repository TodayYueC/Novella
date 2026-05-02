extends RefCounted

class_name NovellaRollbackManager

const Constants := preload("res://addons/novella/core/constants.gd")

signal snapshot_pushed(snapshot: Dictionary)
signal rollback_applied(snapshot: Dictionary)
signal rollback_policy_changed

var limit: int = Constants.DEFAULT_ROLLBACK_LIMIT
var snapshots: Array = []
var rollback_prevented: bool = false
var fixed_index: int = -1

func configure(options: Dictionary = {}) -> void:
	if options.has("limit"):
		limit = max(1, int(options["limit"]))
		_trim()


func push_snapshot(state: Dictionary, metadata: Dictionary = {}) -> Dictionary:
	var snapshot := {
		"state": state.duplicate(true),
		"metadata": metadata.duplicate(true),
		"fixed": false,
	}
	snapshots.append(snapshot)
	_trim()
	snapshot_pushed.emit(snapshot.duplicate(true))
	return snapshot.duplicate(true)


func can_rollback(steps: int = 1) -> bool:
	if rollback_prevented or snapshots.is_empty():
		return false
	var target_index: int = snapshots.size() - max(1, steps)
	return target_index >= 0 and target_index > fixed_index


func rollback(steps: int = 1) -> Dictionary:
	if not can_rollback(steps):
		return {"ok": false, "prevented": rollback_prevented, "available": snapshots.size()}
	var target_index: int = snapshots.size() - max(1, steps)
	return _rollback_to_snapshot_index(target_index)


func rollback_to_index(target_index: int) -> Dictionary:
	if rollback_prevented:
		return {"ok": false, "prevented": true, "available": snapshots.size()}
	return _rollback_to_snapshot_index(target_index)


func rollback_to_line(line: int) -> Dictionary:
	for index in range(snapshots.size() - 1, -1, -1):
		var metadata: Dictionary = snapshots[index].get("metadata", {})
		if int(metadata.get("line", -1)) == line:
			return rollback_to_index(index)
	return {"ok": false, "error": "No rollback snapshot for line '%s'." % line}


func rollback_to_metadata(key: String, value: Variant) -> Dictionary:
	for index in range(snapshots.size() - 1, -1, -1):
		var metadata: Dictionary = snapshots[index].get("metadata", {})
		if metadata.get(key) == value:
			return rollback_to_index(index)
	return {"ok": false, "error": "No rollback snapshot for metadata '%s'." % key}


func list_targets() -> Array:
	var result: Array = []
	for index in range(snapshots.size()):
		var snapshot: Dictionary = snapshots[index]
		result.append({
			"index": index,
			"metadata": snapshot.get("metadata", {}).duplicate(true),
			"fixed": bool(snapshot.get("fixed", false)),
			"available": index > fixed_index and not rollback_prevented,
		})
	return result


func _rollback_to_snapshot_index(target_index: int) -> Dictionary:
	if target_index < 0 or target_index >= snapshots.size() or target_index <= fixed_index:
		return {"ok": false, "target_index": target_index, "fixed_index": fixed_index, "available": snapshots.size()}
	var snapshot: Dictionary = snapshots[target_index].duplicate(true)
	while snapshots.size() > target_index:
		snapshots.pop_back()
	rollback_applied.emit(snapshot)
	return {"ok": true, "snapshot": snapshot, "state": snapshot.get("state", {})}


func prevent_rollback() -> void:
	rollback_prevented = true
	rollback_policy_changed.emit()


func allow_rollback() -> void:
	rollback_prevented = false
	rollback_policy_changed.emit()


func fix_current_position() -> void:
	fixed_index = snapshots.size() - 1
	if fixed_index >= 0:
		snapshots[fixed_index]["fixed"] = true
	rollback_policy_changed.emit()


func clear() -> void:
	snapshots.clear()
	fixed_index = -1


func get_state() -> Dictionary:
	return {
		"limit": limit,
		"snapshots": snapshots.duplicate(true),
		"rollback_prevented": rollback_prevented,
		"fixed_index": fixed_index,
	}


func restore_state(state: Dictionary) -> void:
	limit = int(state.get("limit", limit))
	snapshots = state.get("snapshots", []).duplicate(true)
	rollback_prevented = _as_bool(state.get("rollback_prevented", rollback_prevented))
	fixed_index = int(state.get("fixed_index", fixed_index))
	_trim()


func _trim() -> void:
	while snapshots.size() > limit:
		snapshots.pop_front()
		fixed_index = max(-1, fixed_index - 1)


func _as_bool(value: Variant) -> bool:
	if value is bool:
		return value
	var text := str(value).strip_edges().to_lower()
	return text == "true" or text == "1" or text == "yes" or text == "on"
