extends RefCounted

class_name NovellaAchievementManager

const ExpressionEvaluator := preload("res://addons/novella/script/expression_evaluator.gd")

signal achievement_registered(achievement_id: StringName, achievement: Dictionary)
signal achievement_unlocked(achievement_id: StringName, achievement: Dictionary)
signal achievement_progressed(achievement_id: StringName, progress: float, target: float)

var achievements: Dictionary = {}
var unlock_order: Array = []
var evaluator := ExpressionEvaluator.new()

func register_achievement(achievement_id: StringName, data: Dictionary = {}, replace: bool = true) -> Dictionary:
	if achievements.has(achievement_id) and not replace:
		return achievements[achievement_id].duplicate(true)
	var existing: Dictionary = achievements.get(achievement_id, {})
	var target_value := float(data.get("target", existing.get("target", 1.0)))
	var achievement := {
		"id": String(achievement_id),
		"title": str(data.get("title", existing.get("title", String(achievement_id)))),
		"description": str(data.get("description", existing.get("description", ""))),
		"hidden": _as_bool(data.get("hidden", existing.get("hidden", false))),
		"condition": str(data.get("condition", existing.get("condition", ""))),
		"progress": float(data.get("progress", existing.get("progress", 0.0))),
		"target": maxf(1.0, target_value),
		"unlocked": _as_bool(data.get("unlocked", existing.get("unlocked", false))),
		"metadata": data.get("metadata", existing.get("metadata", {})).duplicate(true) if data.get("metadata", existing.get("metadata", {})) is Dictionary else {},
	}
	achievements[achievement_id] = achievement
	achievement_registered.emit(achievement_id, achievement.duplicate(true))
	return achievement.duplicate(true)


func unlock(achievement_id: StringName, data: Dictionary = {}) -> Dictionary:
	var achievement := register_achievement(achievement_id, data, false)
	var was_unlocked := _as_bool(achievement.get("unlocked", false))
	achievement["unlocked"] = true
	achievement["progress"] = float(achievement.get("target", 1.0))
	if data.has("title"):
		achievement["title"] = str(data["title"])
	if data.has("description"):
		achievement["description"] = str(data["description"])
	achievements[achievement_id] = achievement
	if not was_unlocked:
		unlock_order.append(String(achievement_id))
		achievement_unlocked.emit(achievement_id, achievement.duplicate(true))
	return achievement.duplicate(true)


func set_progress(achievement_id: StringName, progress: float, data: Dictionary = {}) -> Dictionary:
	var achievement := register_achievement(achievement_id, data, false)
	achievement["progress"] = clampf(progress, 0.0, float(achievement.get("target", 1.0)))
	achievements[achievement_id] = achievement
	achievement_progressed.emit(achievement_id, float(achievement["progress"]), float(achievement.get("target", 1.0)))
	if float(achievement["progress"]) >= float(achievement.get("target", 1.0)):
		return unlock(achievement_id)
	return achievement.duplicate(true)


func add_progress(achievement_id: StringName, amount: float = 1.0, data: Dictionary = {}) -> Dictionary:
	var achievement := register_achievement(achievement_id, data, false)
	return set_progress(achievement_id, float(achievement.get("progress", 0.0)) + amount, data)


func evaluate_conditions(variable_source: Variant) -> Array:
	var unlocked: Array = []
	for achievement_id in achievements:
		var achievement: Dictionary = achievements[achievement_id]
		var condition := str(achievement.get("condition", ""))
		if condition.is_empty() or _as_bool(achievement.get("unlocked", false)):
			continue
		if bool(evaluator.evaluate(condition, variable_source, false)):
			unlocked.append(unlock(achievement_id))
	return unlocked


func is_unlocked(achievement_id: StringName) -> bool:
	return achievements.has(achievement_id) and _as_bool(achievements[achievement_id].get("unlocked", false))


func get_achievement(achievement_id: StringName) -> Dictionary:
	return achievements.get(achievement_id, {}).duplicate(true)


func list_achievements(include_hidden: bool = true) -> Array:
	var result: Array = []
	for achievement_id in achievements:
		var achievement: Dictionary = achievements[achievement_id]
		if not include_hidden and _as_bool(achievement.get("hidden", false)) and not _as_bool(achievement.get("unlocked", false)):
			continue
		result.append(achievement.duplicate(true))
	result.sort_custom(func(a, b): return str(a.get("id", "")) < str(b.get("id", "")))
	return result


func get_state() -> Dictionary:
	return {
		"achievements": achievements.duplicate(true),
		"unlock_order": unlock_order.duplicate(true),
	}


func restore_state(state: Dictionary) -> void:
	achievements = _string_name_achievements(state.get("achievements", achievements))
	unlock_order = state.get("unlock_order", []).duplicate(true)


func _string_name_achievements(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in source:
		result[StringName(str(key))] = source[key].duplicate(true)
	return result


func _as_bool(value: Variant) -> bool:
	if value is bool:
		return value
	var text := str(value).strip_edges().to_lower()
	return text == "true" or text == "1" or text == "yes" or text == "on"
