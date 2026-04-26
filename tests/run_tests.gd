extends SceneTree

const Lexer := preload("res://addons/novella/script/lexer.gd")
const Token := preload("res://addons/novella/script/token.gd")
const Parser := preload("res://addons/novella/script/parser.gd")
const ExpressionEvaluator := preload("res://addons/novella/script/expression_evaluator.gd")
const VariableManager := preload("res://addons/novella/script/variable_manager.gd")
const CommandRegistry := preload("res://addons/novella/script/command_registry.gd")
const BasicCommands := preload("res://addons/novella/script/commands/basic_commands.gd")
const VM := preload("res://addons/novella/script/novella_vm.gd")
const RichTextParser := preload("res://addons/novella/presentation/rich_text_parser.gd")
const TypewriterEffect := preload("res://addons/novella/presentation/typewriter_effect.gd")
const PrinterManager := preload("res://addons/novella/presentation/printer_manager.gd")

var failures: Array[String] = []

func _init() -> void:
	_run_all()
	if failures.is_empty():
		print("Novella v0.2 text presentation tests passed.")
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
	basic.register_all(registry, variables)
	_assert(registry.execute(&"var", "score = 1")["ok"], "@var should execute.")
	_assert(registry.execute(&"set", "score += 4")["ok"], "@set should execute.")
	_assert(variables.get_variable(&"score") == 5, "VariableManager should store command updates.")
	_assert(registry.execute(&"flag", "set met_ryone")["ok"], "@flag set should execute.")
	_assert(variables.flags.check_flag(&"met_ryone"), "FlagSet should contain set flag.")
	_assert(registry.execute(&"mode", "nvl")["mode"] == &"nvl", "@mode should return a printer mode change.")


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


func _test_vm_milestone_script() -> void:
	var parser := Parser.new()
	var ast = parser.parse(_sample_script(), "v0_2_demo.nvs")
	var variables := VariableManager.new()
	var registry := CommandRegistry.new()
	var basic := BasicCommands.new()
	var printer_manager := PrinterManager.new()
	basic.register_all(registry, variables)
	var vm := VM.new()
	vm.variable_manager = variables
	vm.command_registry = registry
	vm.printer_manager = printer_manager
	vm.load_script(ast)
	var transcript := vm.run()
	_assert(not transcript.any(func(entry): return entry.get("type", "") == "error"), "VM should not emit runtime errors: %s" % [transcript])
	_assert(variables.get_variable(&"affinity") == 5, "VM should execute @set affinity += 5.")
	_assert(transcript.any(func(entry): return entry.get("type", "") == "dialogue" and str(entry.get("text", "")).contains("Affinity: 5")), "VM should interpolate affinity into dialogue.")
	_assert(transcript.any(func(entry): return entry.get("presentation", {}).get("mode", "") == "nvl"), "VM should dispatch dialogue to NVL printer after @mode nvl.")
	_assert(transcript.back().get("text", "") == "Demo end.", "VM should finish at end_path dialogue.")


func _sample_script() -> String:
	return """@var affinity = 0

label start:
    Ryone: Welcome to Novella.
    @set affinity += 5
    menu:
        "Greet" if affinity >= 0:
            jump greet_path
        "Ignore":
            jump ignore_path

label greet_path:
    Ryone: Nice to meet you! Affinity: {affinity}
    @mode nvl
    Ryone: {b}This line uses NVL mode.{/b}
    jump end_path

label ignore_path:
    Ryone: Why ignore me? Affinity: {affinity}
    jump end_path

label end_path:
    @mode adv
    Ryone: Demo end."""


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
