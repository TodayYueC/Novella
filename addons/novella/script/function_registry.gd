extends RefCounted

class_name NovellaFunctionRegistry

var _functions: Dictionary = {}

func register_function(function_name: StringName, handler: Callable, replace_existing: bool = true) -> void:
	if _functions.has(function_name) and not replace_existing:
		push_error("Novella function '%s' is already registered." % function_name)
		return
	_functions[function_name] = handler


func has_function(function_name: StringName) -> bool:
	return _functions.has(function_name)


func call_function(function_name: StringName, args: Array = []) -> Variant:
	var handler: Callable = _functions.get(function_name, Callable())
	if not handler.is_valid():
		push_error("Unknown Novella function '%s'." % function_name)
		return null
	return handler.callv(args)


func bind_to_evaluator(evaluator: Variant) -> void:
	for function_name in _functions:
		evaluator.register_function(function_name, _functions[function_name])
