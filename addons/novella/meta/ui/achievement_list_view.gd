extends Control

class_name NovellaAchievementListView

var item_list: ItemList

func _ready() -> void:
	_build_ui()


func apply_achievements(achievements: Array) -> void:
	_build_ui()
	item_list.clear()
	for achievement in achievements:
		var unlocked := bool(achievement.get("unlocked", false))
		var title := str(achievement.get("title", achievement.get("id", "")))
		var progress := float(achievement.get("progress", 0.0))
		var target := float(achievement.get("target", 1.0))
		var status := "Done" if unlocked else "%s/%s" % [_format_number(progress), _format_number(target)]
		item_list.add_item("%s - %s" % [title, status])


func _build_ui() -> void:
	if item_list != null:
		return
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	item_list = ItemList.new()
	item_list.name = "ItemList"
	item_list.anchor_right = 1.0
	item_list.anchor_bottom = 1.0
	add_child(item_list)


func _format_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(value))
	return str(value)
