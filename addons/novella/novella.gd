extends Node

const ServiceBus := preload("res://addons/novella/core/service_bus.gd")
const EventBus := preload("res://addons/novella/core/event_bus.gd")
const VariableManager := preload("res://addons/novella/script/variable_manager.gd")
const CommandRegistry := preload("res://addons/novella/script/command_registry.gd")
const Parser := preload("res://addons/novella/script/parser.gd")
const VM := preload("res://addons/novella/script/novella_vm.gd")
const BasicCommands := preload("res://addons/novella/script/commands/basic_commands.gd")

var services: ServiceBus
var events: EventBus
var variables: VariableManager
var commands: CommandRegistry
var parser: Parser
var vm: VM
var basic_commands: BasicCommands

func _ready() -> void:
	_bootstrap()


func _bootstrap() -> void:
	services = ServiceBus.new()
	events = EventBus.new()
	variables = VariableManager.new()
	commands = CommandRegistry.new()
	parser = Parser.new()
	vm = VM.new()
	basic_commands = BasicCommands.new()
	basic_commands.register_all(commands, variables)

	services.register_service(&"event_bus", events, true)
	services.register_service(&"variable_manager", variables, true)
	services.register_service(&"command_registry", commands, true)
	services.register_service(&"script_parser", parser, true)
	services.register_service(&"vm", vm, true)

	vm.variable_manager = variables
	vm.command_registry = commands


func reset_runtime() -> void:
	_bootstrap()


func parse_script(source: String, file_path: String = ""):
	return parser.parse(source, file_path)


func run_script(source: String, file_path: String = "", max_steps: int = 10000) -> Array:
	var ast = parse_script(source, file_path)
	vm.load_script(ast)
	return vm.run(max_steps)


func register_command(command_name: StringName, handler: Callable, options: Dictionary = {}) -> void:
	commands.register_command(command_name, handler, options)


func register_service(service_name: StringName, service: Variant, replace_existing: bool = true) -> void:
	services.register_service(service_name, service, replace_existing)
