extends SceneTree

const Lexer := preload("res://addons/novella/script/lexer.gd")
const Token := preload("res://addons/novella/script/token.gd")
const Parser := preload("res://addons/novella/script/parser.gd")
const ExpressionEvaluator := preload("res://addons/novella/script/expression_evaluator.gd")
const VariableManager := preload("res://addons/novella/script/variable_manager.gd")
const CommandRegistry := preload("res://addons/novella/script/command_registry.gd")
const BasicCommands := preload("res://addons/novella/script/commands/basic_commands.gd")
const VM := preload("res://addons/novella/script/novella_vm.gd")

var failures: Array[String] = []

func _init() -> void:
	_run_all()
	if failures.is_empty():
		print("Novella v0.1 tests passed.")
		quit(0)
	else:
		push_error("Novella v0.1 tests failed:\n%s" % "\n".join(failures))
		quit(1)


func _run_all() -> void:
	_test_lexer()
	_test_parser()
	_test_expression_evaluator()
	_test_variable_manager_and_commands()
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


func _test_vm_milestone_script() -> void:
	var parser := Parser.new()
	var ast = parser.parse(_sample_script(), "v0_1_demo.nvs")
	var variables := VariableManager.new()
	var registry := CommandRegistry.new()
	var basic := BasicCommands.new()
	basic.register_all(registry, variables)
	var vm := VM.new()
	vm.variable_manager = variables
	vm.command_registry = registry
	vm.load_script(ast)
	var transcript := vm.run()
	_assert(not transcript.any(func(entry): return entry.get("type", "") == "error"), "VM should not emit runtime errors: %s" % [transcript])
	_assert(variables.get_variable(&"affinity") == 5, "VM should execute @set affinity += 5.")
	_assert(transcript.any(func(entry): return entry.get("type", "") == "dialogue" and str(entry.get("text", "")).contains("好感度：5")), "VM should interpolate affinity into dialogue.")
	_assert(transcript.back().get("text", "") == "演示结束。", "VM should finish at end_path dialogue.")


func _sample_script() -> String:
	return """@var affinity = 0

label start:
    凉音: 你好，欢迎来到Novella！
    @set affinity += 5
    menu:
        "打招呼" if affinity >= 0:
            jump greet_path
        "无视":
            jump ignore_path

label greet_path:
    凉音: 很高兴认识你！好感度：{affinity}
    jump end_path

label ignore_path:
    凉音: ...你为什么不理我？好感度：{affinity}
    jump end_path

label end_path:
    凉音: 演示结束。"""


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
