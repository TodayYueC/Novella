extends RefCounted

signal event_emitted(event_name: StringName, payload: Dictionary)

var _subscribers: Dictionary = {}

func subscribe(event_name: StringName, handler: Callable) -> void:
	if not _subscribers.has(event_name):
		_subscribers[event_name] = []
	if not _subscribers[event_name].has(handler):
		_subscribers[event_name].append(handler)


func unsubscribe(event_name: StringName, handler: Callable) -> void:
	if not _subscribers.has(event_name):
		return
	_subscribers[event_name].erase(handler)


func emit(event_name: StringName, payload: Dictionary = {}) -> void:
	event_emitted.emit(event_name, payload)
	for handler in _subscribers.get(event_name, []):
		if handler.is_valid():
			handler.call(payload)


func clear(event_name: StringName = &"") -> void:
	if event_name == &"":
		_subscribers.clear()
	else:
		_subscribers.erase(event_name)
