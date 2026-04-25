extends RefCounted

class_name NovellaLabelManager

var labels: Dictionary = {}

func rebuild(nodes: Array) -> void:
	labels.clear()
	for i in range(nodes.size()):
		var node = nodes[i]
		if node.kind == &"label":
			labels[node.label_name] = i


func has_label(label_name: StringName) -> bool:
	return labels.has(label_name)


func get_index(label_name: StringName, default_value: int = -1) -> int:
	return int(labels.get(label_name, default_value))
