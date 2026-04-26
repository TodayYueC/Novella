extends Node

const ServiceBus := preload("res://addons/novella/core/service_bus.gd")
const EventBus := preload("res://addons/novella/core/event_bus.gd")
const VariableManager := preload("res://addons/novella/script/variable_manager.gd")
const CommandRegistry := preload("res://addons/novella/script/command_registry.gd")
const Parser := preload("res://addons/novella/script/parser.gd")
const VM := preload("res://addons/novella/script/novella_vm.gd")
const BasicCommands := preload("res://addons/novella/script/commands/basic_commands.gd")
const PresentationCommands := preload("res://addons/novella/script/commands/presentation_commands.gd")
const InteractionCommands := preload("res://addons/novella/script/commands/interaction_commands.gd")
const PrinterManager := preload("res://addons/novella/presentation/printer_manager.gd")
const CharacterManager := preload("res://addons/novella/presentation/characters/character_manager.gd")
const BackgroundManager := preload("res://addons/novella/presentation/backgrounds/background_manager.gd")
const EffectManager := preload("res://addons/novella/presentation/effects/effect_manager.gd")
const AudioManager := preload("res://addons/novella/presentation/audio/audio_manager.gd")
const CameraDirector := preload("res://addons/novella/presentation/camera/camera_director.gd")
const ChoiceManager := preload("res://addons/novella/interaction/choice_manager.gd")
const SaveManager := preload("res://addons/novella/state/save_manager.gd")
const RollbackManager := preload("res://addons/novella/state/rollback_manager.gd")
const SkipManager := preload("res://addons/novella/interaction/skip_manager.gd")
const AutoManager := preload("res://addons/novella/interaction/auto_manager.gd")
const BacklogManager := preload("res://addons/novella/state/backlog_manager.gd")
const QuickMenuManager := preload("res://addons/novella/interaction/quick_menu_manager.gd")

var services: ServiceBus
var events: EventBus
var variables: VariableManager
var commands: CommandRegistry
var parser: Parser
var vm: VM
var basic_commands: BasicCommands
var presentation_commands: PresentationCommands
var interaction_commands: InteractionCommands
var printer_manager: PrinterManager
var character_manager: CharacterManager
var background_manager: BackgroundManager
var effect_manager: EffectManager
var audio_manager: AudioManager
var camera_director: CameraDirector
var choice_manager: ChoiceManager
var save_manager: SaveManager
var rollback_manager: RollbackManager
var skip_manager: SkipManager
var auto_manager: AutoManager
var backlog_manager: BacklogManager
var quick_menu_manager: QuickMenuManager

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
	choice_manager = ChoiceManager.new()
	save_manager = SaveManager.new()
	rollback_manager = RollbackManager.new()
	skip_manager = SkipManager.new()
	auto_manager = AutoManager.new()
	backlog_manager = BacklogManager.new()
	quick_menu_manager = QuickMenuManager.new()
	basic_commands = BasicCommands.new()
	presentation_commands = PresentationCommands.new()
	interaction_commands = InteractionCommands.new()
	choice_manager.variable_manager = variables
	basic_commands.register_all(commands, variables)
	presentation_commands.register_all(commands, {
		"printer_manager": printer_manager,
		"character_manager": character_manager,
		"background_manager": background_manager,
		"effect_manager": effect_manager,
		"audio_manager": audio_manager,
		"camera_director": camera_director,
	})
	interaction_commands.register_all(commands, {
		"choice_manager": choice_manager,
		"save_manager": save_manager,
		"rollback_manager": rollback_manager,
		"skip_manager": skip_manager,
		"auto_manager": auto_manager,
		"backlog_manager": backlog_manager,
		"quick_menu_manager": quick_menu_manager,
	})
	_register_quick_menu_handlers()

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
	services.register_service(&"choice_manager", choice_manager, true)
	services.register_service(&"save_manager", save_manager, true)
	services.register_service(&"rollback_manager", rollback_manager, true)
	services.register_service(&"skip_manager", skip_manager, true)
	services.register_service(&"auto_manager", auto_manager, true)
	services.register_service(&"backlog_manager", backlog_manager, true)
	services.register_service(&"quick_menu_manager", quick_menu_manager, true)

	vm.variable_manager = variables
	vm.command_registry = commands
	vm.printer_manager = printer_manager
	vm.choice_manager = choice_manager
	vm.save_manager = save_manager
	vm.rollback_manager = rollback_manager
	vm.skip_manager = skip_manager
	vm.auto_manager = auto_manager
	vm.backlog_manager = backlog_manager
	vm.quick_menu_manager = quick_menu_manager
	vm.state_providers = {
		&"printer": printer_manager,
		&"characters": character_manager,
		&"background": background_manager,
		&"effects": effect_manager,
		&"audio": audio_manager,
		&"camera": camera_director,
		&"choices": choice_manager,
		&"skip": skip_manager,
		&"auto": auto_manager,
		&"backlog": backlog_manager,
		&"quick_menu": quick_menu_manager,
	}


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


func _register_quick_menu_handlers() -> void:
	quick_menu_manager.register_action_handler(&"auto", Callable(self, "_quick_action_auto"))
	quick_menu_manager.register_action_handler(&"skip", Callable(self, "_quick_action_skip"))
	quick_menu_manager.register_action_handler(&"save", Callable(self, "_quick_action_save"))
	quick_menu_manager.register_action_handler(&"load", Callable(self, "_quick_action_load"))
	quick_menu_manager.register_action_handler(&"log", Callable(self, "_quick_action_log"))
	quick_menu_manager.register_action_handler(&"rollback", Callable(self, "_quick_action_rollback"))


func _quick_action_auto(_context: Dictionary) -> Dictionary:
	return auto_manager.toggle()


func _quick_action_skip(_context: Dictionary) -> Dictionary:
	if skip_manager.mode == &"off":
		return skip_manager.start_skip(&"read")
	return skip_manager.stop_skip()


func _quick_action_save(_context: Dictionary) -> Dictionary:
	return save_manager.quick_save(vm.snapshot_state(), {"kind": "quick_menu"})


func _quick_action_load(_context: Dictionary) -> Dictionary:
	var payload: Dictionary = save_manager.quick_load()
	if bool(payload.get("ok", false)):
		vm.restore_state(payload.get("state", {}))
	return payload


func _quick_action_log(_context: Dictionary) -> Dictionary:
	return {"ok": true, "entries": backlog_manager.get_entries()}


func _quick_action_rollback(_context: Dictionary) -> Dictionary:
	var payload: Dictionary = rollback_manager.rollback()
	if bool(payload.get("ok", false)):
		vm.restore_state(payload.get("state", {}))
	return payload
