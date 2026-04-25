extends RefCounted

signal service_registered(service_name: StringName, service: Variant)
signal service_removed(service_name: StringName)

var _services: Dictionary = {}

func register_service(service_name: StringName, service: Variant, replace_existing: bool = false) -> void:
	if _services.has(service_name) and not replace_existing:
		push_error("Novella service '%s' is already registered." % service_name)
		return
	_services[service_name] = service
	service_registered.emit(service_name, service)


func has_service(service_name: StringName) -> bool:
	return _services.has(service_name)


func get_service(service_name: StringName, default_value: Variant = null) -> Variant:
	return _services.get(service_name, default_value)


func require_service(service_name: StringName) -> Variant:
	if not _services.has(service_name):
		push_error("Required Novella service '%s' is not registered." % service_name)
		return null
	return _services[service_name]


func remove_service(service_name: StringName) -> bool:
	if not _services.has(service_name):
		return false
	_services.erase(service_name)
	service_removed.emit(service_name)
	return true


func clear() -> void:
	for service_name in _services.keys():
		service_removed.emit(service_name)
	_services.clear()


func list_services() -> Array:
	return _services.keys()
