extends RefCounted

class_name NovellaGalleryManager

signal item_registered(item_id: StringName, item: Dictionary)
signal item_unlocked(item_id: StringName, item: Dictionary)
signal item_viewed(item_id: StringName)

var items: Dictionary = {}
var unlock_log: Array = []

func register_item(item_id: StringName, data: Dictionary = {}, replace: bool = true) -> Dictionary:
	if items.has(item_id) and not replace:
		return items[item_id].duplicate(true)
	var existing: Dictionary = items.get(item_id, {})
	var item := {
		"id": String(item_id),
		"type": str(data.get("type", existing.get("type", "cg"))),
		"title": str(data.get("title", existing.get("title", String(item_id)))),
		"description": str(data.get("description", existing.get("description", ""))),
		"asset": str(data.get("asset", existing.get("asset", ""))),
		"thumbnail": str(data.get("thumbnail", existing.get("thumbnail", ""))),
		"label": str(data.get("label", existing.get("label", ""))),
		"tags": data.get("tags", existing.get("tags", [])).duplicate(true) if data.get("tags", existing.get("tags", [])) is Array else [],
		"order": int(data.get("order", existing.get("order", 0))),
		"unlocked": _as_bool(data.get("unlocked", existing.get("unlocked", false))),
		"viewed": _as_bool(data.get("viewed", existing.get("viewed", false))),
		"metadata": data.get("metadata", existing.get("metadata", {})).duplicate(true) if data.get("metadata", existing.get("metadata", {})) is Dictionary else {},
	}
	items[item_id] = item
	item_registered.emit(item_id, item.duplicate(true))
	return item.duplicate(true)


func unlock_item(item_id: StringName, data: Dictionary = {}) -> Dictionary:
	var item := register_item(item_id, data, false)
	var was_unlocked := _as_bool(item.get("unlocked", false))
	item["unlocked"] = true
	if data.has("title"):
		item["title"] = str(data["title"])
	if data.has("asset"):
		item["asset"] = str(data["asset"])
	if data.has("type"):
		item["type"] = str(data["type"])
	if data.has("label"):
		item["label"] = str(data["label"])
	items[item_id] = item
	if not was_unlocked:
		unlock_log.append({"id": String(item_id), "type": item.get("type", ""), "title": item.get("title", "")})
		item_unlocked.emit(item_id, item.duplicate(true))
	return item.duplicate(true)


func unlock_replay(replay_id: StringName, label: StringName, data: Dictionary = {}) -> Dictionary:
	var payload := data.duplicate(true)
	payload["type"] = "replay"
	payload["label"] = String(label)
	return unlock_item(replay_id, payload)


func lock_item(item_id: StringName) -> Dictionary:
	if not items.has(item_id):
		return {"ok": true, "locked": false, "id": String(item_id)}
	items[item_id]["unlocked"] = false
	return items[item_id].duplicate(true)


func mark_viewed(item_id: StringName) -> Dictionary:
	if not items.has(item_id):
		return {"ok": false, "error": "Gallery item '%s' was not found." % item_id}
	items[item_id]["viewed"] = true
	item_viewed.emit(item_id)
	return items[item_id].duplicate(true)


func is_unlocked(item_id: StringName) -> bool:
	return items.has(item_id) and _as_bool(items[item_id].get("unlocked", false))


func get_item(item_id: StringName) -> Dictionary:
	return items.get(item_id, {}).duplicate(true)


func list_items(item_type: String = "", include_locked: bool = true) -> Array:
	var result: Array = []
	for item_id in items:
		var item: Dictionary = items[item_id]
		if not item_type.is_empty() and str(item.get("type", "")) != item_type:
			continue
		if not include_locked and not _as_bool(item.get("unlocked", false)):
			continue
		result.append(item.duplicate(true))
	result.sort_custom(func(a, b): return int(a.get("order", 0)) < int(b.get("order", 0)))
	return result


func get_state() -> Dictionary:
	return {
		"items": items.duplicate(true),
		"unlock_log": unlock_log.duplicate(true),
	}


func restore_state(state: Dictionary) -> void:
	items = _string_name_items(state.get("items", items))
	unlock_log = state.get("unlock_log", []).duplicate(true)


func _string_name_items(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in source:
		result[StringName(str(key))] = source[key].duplicate(true)
	return result


func _as_bool(value: Variant) -> bool:
	if value is bool:
		return value
	var text := str(value).strip_edges().to_lower()
	return text == "true" or text == "1" or text == "yes" or text == "on"
