extends RefCounted

class_name NovellaFlagSet

var _flags: Dictionary = {}

func set_flag(flag_name: StringName, enabled: bool = true) -> void:
	_flags[flag_name] = enabled


func clear_flag(flag_name: StringName) -> void:
	_flags.erase(flag_name)


func toggle_flag(flag_name: StringName) -> bool:
	var enabled := not check_flag(flag_name)
	set_flag(flag_name, enabled)
	return enabled


func check_flag(flag_name: StringName) -> bool:
	return bool(_flags.get(flag_name, false))


func to_array() -> Array:
	var result: Array = []
	for flag_name in _flags:
		if _flags[flag_name]:
			result.append(String(flag_name))
	return result


func from_array(flags: Array) -> void:
	_flags.clear()
	for flag_name in flags:
		set_flag(StringName(str(flag_name)), true)


func duplicate_flags() -> Variant:
	var copy = get_script().new()
	copy.from_array(to_array())
	return copy
