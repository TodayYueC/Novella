extends Node

const ServiceBus := preload("res://addons/novella/core/service_bus.gd")
const EventBus := preload("res://addons/novella/core/event_bus.gd")
const VariableManager := preload("res://addons/novella/script/variable_manager.gd")
const CommandRegistry := preload("res://addons/novella/script/command_registry.gd")
const Parser := preload("res://addons/novella/script/parser.gd")
const VM := preload("res://addons/novella/script/novella_vm.gd")
const BasicCommands := preload("res://addons/novella/script/commands/basic_commands.gd")
const PresentationCommands := preload("res://addons/novella/script/commands/presentation_commands.gd")
const PrinterManager := preload("res://addons/novella/presentation/printer_manager.gd")
const CharacterManager := preload("res://addons/novella/presentation/characters/character_manager.gd")
const BackgroundManager := preload("res://addons/novella/presentation/backgrounds/background_manager.gd")
const EffectManager := preload("res://addons/novella/presentation/effects/effect_manager.gd")
const AudioManager := preload("res://addons/novella/presentation/audio/audio_manager.gd")
const CameraDirector := preload("res://addons/novella/presentation/camera/camera_director.gd")

var services: ServiceBus
var events: EventBus
var variables: VariableManager
var commands: CommandRegistry
var parser: Parser
var vm: VM
var basic_commands: BasicCommands
var presentation_commands: PresentationCommands
var printer_manager: PrinterManager
var character_manager: CharacterManager
var background_manager: BackgroundManager
var effect_manager: EffectManager
var audio_manager: AudioManager
var camera_director: CameraDirector

func _ready() -> void:
	_bootstrap()


func _bootstrap() -> void:
	services = ServiceBus.new()
	events = EventBus.new()
	variables = VariableManager.new()
	commands = CommandRegistry.new()
	parser = Parser.new()
	vm = VM.new()
	printer_manager = PrinterManager.new()
	character_manager = CharacterManager.new()
	background_manager = BackgroundManager.new()
	effect_manager = EffectManager.new()
	audio_manager = AudioManager.new()
	camera_director = CameraDirector.new()
	basic_commands = BasicCommands.new()
	presentation_commands = PresentationCommands.new()
	basic_commands.register_all(commands, variables)
	presentation_commands.register_all(commands, {
		"printer_manager": printer_manager,
		"character_manager": character_manager,
		"background_manager": background_manager,
		"effect_manager": effect_manager,
		"audio_manager": audio_manager,
		"camera_director": camera_director,
	})

	services.register_service(&"event_bus", events, true)
	services.register_service(&"variable_manager", variables, true)
	services.register_service(&"command_registry", commands, true)
	services.register_service(&"script_parser", parser, true)
	services.register_service(&"vm", vm, true)
	services.register_service(&"printer_manager", printer_manager, true)
	services.register_service(&"character_manager", character_manager, true)
	services.register_service(&"background_manager", background_manager, true)
	services.register_service(&"effect_manager", effect_manager, true)
	services.register_service(&"audio_manager", audio_manager, true)
	services.register_service(&"camera_director", camera_director, true)

	vm.variable_manager = variables
	vm.command_registry = commands
	vm.printer_manager = printer_manager


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


func register_printer(mode: StringName, printer: Variant, replace_existing: bool = true) -> void:
	printer_manager.register_printer(mode, printer, replace_existing)
