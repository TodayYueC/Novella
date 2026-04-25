extends RefCounted

class_name NovellaCommandRegistry

signal command_registered(command_name: StringName)
signal command_executed(command_name: StringName, result: Dictionary)

var _commands: Dictionary = {}

func register_command(command_name: StringName, handler: Callable, options: Dictionary = {}, replace_existing: bool = true) -> void:
	if _commands.has(command_name) and not replace_existing:
		push_error("Novella command '%s' is already registered." % command_name)
		return
	_commands[command_name] = {
		"handler": handler,
		"options": options.duplicate(true),
	}
	command_registered.emit(command_name)


func has_command(command_name: StringName) -> bool:
	return _commands.has(command_name)


func execute(command_name: StringName, raw_arguments: String = "", context: Dictionary = {}) -> Dictionary:
	if not _commands.has(command_name):
		var missing := {"ok": false, "error": "Unknown command '%s'." % command_name}
		command_executed.emit(command_name, missing)
		return missing
	var handler: Callable = _commands[command_name]["handler"]
	var result: Variant = handler.call(raw_arguments, context)
	if result is Dictionary:
		command_executed.emit(command_name, result)
		return result
	var wrapped := {"ok": true, "value": result}
	command_executed.emit(command_name, wrapped)
	return wrapped


func list_commands() -> Array:
	return _commands.keys()
