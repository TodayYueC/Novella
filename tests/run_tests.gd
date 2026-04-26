extends SceneTree

const Lexer := preload("res://addons/novella/script/lexer.gd")
const Token := preload("res://addons/novella/script/token.gd")
const Parser := preload("res://addons/novella/script/parser.gd")
const ExpressionEvaluator := preload("res://addons/novella/script/expression_evaluator.gd")
const VariableManager := preload("res://addons/novella/script/variable_manager.gd")
const CommandRegistry := preload("res://addons/novella/script/command_registry.gd")
const BasicCommands := preload("res://addons/novella/script/commands/basic_commands.gd")
const PresentationCommands := preload("res://addons/novella/script/commands/presentation_commands.gd")
const VM := preload("res://addons/novella/script/novella_vm.gd")
const RichTextParser := preload("res://addons/novella/presentation/rich_text_parser.gd")
const TypewriterEffect := preload("res://addons/novella/presentation/typewriter_effect.gd")
const PrinterManager := preload("res://addons/novella/presentation/printer_manager.gd")
const CharacterManager := preload("res://addons/novella/presentation/characters/character_manager.gd")
const BackgroundManager := preload("res://addons/novella/presentation/backgrounds/background_manager.gd")
const EffectManager := preload("res://addons/novella/presentation/effects/effect_manager.gd")
const AudioManager := preload("res://addons/novella/presentation/audio/audio_manager.gd")
const CameraDirector := preload("res://addons/novella/presentation/camera/camera_director.gd")

var failures: Array[String] = []

func _init() -> void:
	_run_all()
	if failures.is_empty():
		print("Novella v0.2 alpha tests passed.")
		quit(0)
	else:
		push_error("Novella tests failed:\n%s" % "\n".join(failures))
		quit(1)


func _run_all() -> void:
	_test_lexer()
	_test_parser()
	_test_expression_evaluator()
	_test_variable_manager_and_commands()
	_test_text_presentation()
	_test_printer_manager()
	_test_printer_views()
	_test_v0_2_managers()
	_test_vm_milestone_script()


func _test_lexer() -> void:
	var lexer := Lexer.new()
	var tokens := lexer.tokenize("@set affinity += 5\nlabel start:")
	_assert(tokens.any(func(token): return token.type == Token.Type.COMMAND and token.literal == "set"), "Lexer should emit @set command token.")
	_assert(tokens.any(func(token): return token.type == Token.Type.KEYWORD and token.lexeme == "label"), "Lexer should emit label keyword.")
	_assert(lexer.errors.is_empty(), "Lexer should not report errors.")


func _test_parser() -> void:
	var parser := Parser.new()
	var ast = parser.parse(_sample_script(), "sample.nvs")
	_assert(parser.errors.is_empty(), "Parser should not report errors: %s" % [parser.errors])
	_assert(ast.children.size() > 0, "Parser should create AST children.")
	_assert(ast.labels.has(&"start"), "Parser should collect start label.")
	_assert(ast.labels.has(&"greet_path"), "Parser should collect greet_path label.")
	_assert(ast.children.any(func(node): return node.kind == &"menu"), "Parser should create a menu node.")


func _test_expression_evaluator() -> void:
	var variables := VariableManager.new()
	variables.declare_variable(&"affinity", 5)
	var evaluator := ExpressionEvaluator.new()
	_assert(evaluator.evaluate("affinity >= 5 and affinity < 10", variables, false) == true, "Expression evaluator should handle comparisons and logic.")
	_assert(evaluator.evaluate("affinity * 2 + 1", variables, 0) == 11, "Expression evaluator should handle arithmetic.")


func _test_variable_manager_and_commands() -> void:
	var variables := VariableManager.new()
	var registry := CommandRegistry.new()
	var basic := BasicCommands.new()
	var presentation := PresentationCommands.new()
	var managers := _make_v0_2_managers()
	basic.register_all(registry, variables)
	presentation.register_all(registry, managers)
	_assert(registry.execute(&"var", "score = 1")["ok"], "@var should execute.")
	_assert(registry.execute(&"set", "score += 4")["ok"], "@set should execute.")
	_assert(variables.get_variable(&"score") == 5, "VariableManager should store command updates.")
	_assert(registry.execute(&"flag", "set met_ryone")["ok"], "@flag set should execute.")
	_assert(variables.flags.check_flag(&"met_ryone"), "FlagSet should contain set flag.")
	_assert(registry.execute(&"mode", "nvl")["mode"] == &"nvl", "@mode should return a printer mode change.")
	_assert(registry.execute(&"bg", "school transition:dissolve time:1.0")["id"] == "school", "@bg should update background state.")
	_assert(registry.execute(&"play_music", "main_theme fade:1.0")["channel"] == "bgm", "@play_music should use BGM channel.")


func _test_text_presentation() -> void:
	var parser := RichTextParser.new()
	var parsed := parser.parse("{b}Hello{/b} {color=#ff0000}red{/color}{w=0.5}{nw}")
	_assert(parsed["bbcode"].contains("[b]Hello[/b]"), "RichTextParser should convert bold tags to BBCode.")
	_assert(parsed["bbcode"].contains("[color=#ff0000]red[/color]"), "RichTextParser should convert color tags to BBCode.")
	_assert(parsed["plain_text"] == "Hello red", "RichTextParser should strip visual and control tags.")
	_assert(parsed["controls"].size() == 2, "RichTextParser should collect wait/no-wait controls.")

	var typewriter := TypewriterEffect.new()
	typewriter.start("Hi!", 10.0)
	typewriter.advance(0.1)
	_assert(typewriter.get_visible_text() == "H", "TypewriterEffect should reveal characters over time.")
	typewriter.reveal_all()
	_assert(typewriter.get_visible_text() == "Hi!", "TypewriterEffect should reveal all text on request.")
	_assert(typewriter.estimate_duration("Hi!", 10.0) > 0.3, "TypewriterEffect should include punctuation delay.")


func _test_printer_manager() -> void:
	var manager := PrinterManager.new()
	var adv_payload := manager.present_dialogue("Ryone", "Hello")
	_assert(adv_payload["mode"] == "adv", "PrinterManager should start in ADV mode.")
	_assert(adv_payload["layout"] == "bottom_dialogue_box", "ADV printer should report bottom dialogue layout.")
	_assert(manager.set_mode(&"nvl"), "PrinterManager should switch to NVL mode.")
	var nvl_payload := manager.present_narration("A quiet wind passes.")
	_assert(nvl_payload["mode"] == "nvl", "PrinterManager should present narration in NVL mode after switch.")
	_assert(nvl_payload["layout"] == "fullscreen_text_page", "NVL printer should report fullscreen page layout.")


func _test_printer_views() -> void:
	var adv_scene: PackedScene = load("res://addons/novella/presentation/ui/adv_printer.tscn")
	var nvl_scene: PackedScene = load("res://addons/novella/presentation/ui/nvl_printer.tscn")
	var adv = adv_scene.instantiate()
	var nvl = nvl_scene.instantiate()
	adv.apply_payload({"speaker": "Ryone", "text": "Hello"})
	nvl.apply_payload({"page_lines": [{"speaker": "Ryone", "text": "Hello"}]})
	_assert(adv.get_node("NameLabel").text == "Ryone", "ADV view should display speaker name.")
	_assert(nvl.get_node("TextLabel").text.contains("Ryone: Hello"), "NVL view should display accumulated lines.")
	adv.free()
	nvl.free()


func _test_v0_2_managers() -> void:
	var managers := _make_v0_2_managers()
	var characters: CharacterManager = managers["character_manager"]
	var backgrounds: BackgroundManager = managers["background_manager"]
	var effects: EffectManager = managers["effect_manager"]
	var audio: AudioManager = managers["audio_manager"]
	var camera: CameraDirector = managers["camera_director"]

	characters.register_character(&"Ryone", {
		"layers": [
			{"group": "body", "attribute": "uniform", "path": "ryone/uniform.png", "order": 0},
			{"group": "expression", "attribute": "happy", "path": "ryone/happy.png", "order": 1},
			{"group": "expression", "attribute": "sad", "path": "ryone/sad.png", "order": 1},
		],
		"side_portraits": {&"default": "ryone/side/default.png", &"happy": "ryone/side/happy.png"},
	})
	var shown := characters.show_character(&"Ryone", ["uniform", "happy"], {"pos": "left", "enter": "slide"})
	_assert(shown["position_name"] == "left", "CharacterManager should place characters by named position.")
	_assert(shown["layers"].size() == 2, "LayeredSprite should select visible layers.")
	var moved := characters.move_character(&"Ryone", "right", {"time": "0.5"})
	_assert(moved["position_name"] == "right", "CharacterManager should move visible characters.")
	characters.focus_character(&"Ryone")
	_assert(characters.get_character_state(&"Ryone")["focused"], "CharacterManager should focus speakers.")

	var bg := backgrounds.show_background(&"school", {"transition": "dissolve", "time": "1.5"})
	_assert(bg["transition"] == "dissolve", "BackgroundManager should store transitions.")
	_assert(backgrounds.set_environment(&"rain", {"intensity": "0.3"})["ok"], "BackgroundManager should store environment effects.")

	_assert(effects.trigger_effect(&"shake", "screen", {"intensity": "0.5"})["ok"], "EffectManager should trigger built-in effects.")
	_assert(audio.play(&"bgm", &"main_theme", {"fade": "2.0"})["playing"], "AudioManager should play BGM state.")
	_assert(audio.play(&"voice", &"voice_001", {"wait": "true"})["channel"] == "voice", "AudioManager should play voice state.")
	_assert(camera.move_camera({"pos": "10,20", "zoom": "1.2"})["zoom"] == Vector2(1.2, 1.2), "CameraDirector should parse zoom.")
	_assert(camera.shake({"intensity": "0.4"})["ok"], "CameraDirector should shake camera.")


func _test_vm_milestone_script() -> void:
	var parser := Parser.new()
	var ast = parser.parse(_sample_script(), "v0_2_demo.nvs")
	var variables := VariableManager.new()
	var registry := CommandRegistry.new()
	var basic := BasicCommands.new()
	var presentation := PresentationCommands.new()
	var managers := _make_v0_2_managers()
	var printer_manager: PrinterManager = managers["printer_manager"]
	var character_manager: CharacterManager = managers["character_manager"]
	var background_manager: BackgroundManager = managers["background_manager"]
	var effect_manager: EffectManager = managers["effect_manager"]
	var audio_manager: AudioManager = managers["audio_manager"]
	var camera_director: CameraDirector = managers["camera_director"]
	basic.register_all(registry, variables)
	presentation.register_all(registry, managers)
	var vm := VM.new()
	vm.variable_manager = variables
	vm.command_registry = registry
	vm.printer_manager = printer_manager
	vm.load_script(ast)
	var transcript := vm.run()
	_assert(not transcript.any(func(entry): return entry.get("type", "") == "error"), "VM should not emit runtime errors: %s" % [transcript])
	_assert(variables.get_variable(&"affinity") == 5, "VM should execute @set affinity += 5.")
	_assert(transcript.any(func(entry): return entry.get("type", "") == "dialogue" and str(entry.get("text", "")).contains("Affinity: 5")), "VM should interpolate affinity into dialogue.")
	_assert(transcript.any(func(entry): return entry.get("presentation", {}).get("mode", "") == "nvl"), "VM should dispatch dialogue to NVL printer after @mode nvl: %s" % [transcript])
	_assert(background_manager.get_state()["background"]["id"] == "sunset", "VM should execute background commands.")
	_assert(character_manager.get_character_state(&"Ryone")["position_name"] == "right", "VM should execute character move commands.")
	_assert(effect_manager.get_state()["active_effects"].size() >= 2, "VM should execute screen and character effects.")
	_assert(audio_manager.get_state()["channels"][&"bgm"]["playing"] == false, "VM should execute music stop command.")
	_assert(audio_manager.get_state()["channels"][&"voice"]["playing"] == false, "VM should execute voice stop command.")
	_assert(camera_director.get_state()["zoom"] == Vector2.ONE, "VM should execute camera reset command.")
	_assert(transcript.back().get("text", "") == "Demo end.", "VM should finish at end_path dialogue.")


func _sample_script() -> String:
	return """@var affinity = 0

label start:
    @bg school transition:dissolve time:1.5
    @char Ryone uniform happy pos:left enter:slide
    @play_music main_theme fade:2.0 volume:0.8
    @camera pos:10,20 zoom:1.2 time:0.5
    Ryone: Welcome to Novella.
    @set affinity += 5
    menu:
        "Greet" if affinity >= 0:
            jump greet_path
        "Ignore":
            jump ignore_path

label greet_path:
    Ryone: Nice to meet you! Affinity: {affinity}
    @char_emotion Ryone happy
    @char_move Ryone pos:right time:0.5
    @char_effect Ryone shake intensity:0.5 duration:0.2
    @shake intensity:0.4 duration:0.2
    @play_se door_open volume:0.7
    @play_voice ryone_001 wait:true
    @mode nvl
    Ryone: {b}This line uses NVL mode.{/b}
    @nvl_clear
    @bg sunset transition:fade time:0.8
    @camera_reset time:0.2
    @stop_music fade:0.5
    @stop_voice
    jump end_path

label ignore_path:
    Ryone: Why ignore me? Affinity: {affinity}
    jump end_path

label end_path:
    @mode adv
    Ryone: Demo end."""


func _make_v0_2_managers() -> Dictionary:
	return {
		"printer_manager": PrinterManager.new(),
		"character_manager": CharacterManager.new(),
		"background_manager": BackgroundManager.new(),
		"effect_manager": EffectManager.new(),
		"audio_manager": AudioManager.new(),
		"camera_director": CameraDirector.new(),
	}


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
