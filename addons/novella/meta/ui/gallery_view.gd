extends Control

class_name NovellaGalleryView

signal item_pressed(item_id: StringName)

var item_list: ItemList

func _ready() -> void:
	_build_ui()


func apply_items(items: Array, show_locked_names: bool = false) -> void:
	_build_ui()
	item_list.clear()
	for item in items:
		var unlocked := bool(item.get("unlocked", false))
		var title := str(item.get("title", item.get("id", ""))) if unlocked or show_locked_names else "Locked"
		var prefix := "" if unlocked else "[ ] "
		var index := item_list.add_item("%s%s" % [prefix, title])
		item_list.set_item_metadata(index, StringName(str(item.get("id", ""))))


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
	item_list.item_activated.connect(_on_item_activated)
	add_child(item_list)


func _on_item_activated(index: int) -> void:
	var metadata: Variant = item_list.get_item_metadata(index)
	item_pressed.emit(StringName(str(metadata)))
