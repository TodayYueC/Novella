extends RefCounted

class_name NovellaTextInterpolator

const ExpressionEvaluator := preload("res://addons/novella/script/expression_evaluator.gd")

var evaluator := ExpressionEvaluator.new()

func interpolate(text: String, variable_source: Variant) -> String:
	var output := ""
	var index := 0
	while index < text.length():
		var open := text.find("{", index)
		if open == -1:
			output += text.substr(index)
			break
		var close := text.find("}", open + 1)
		if close == -1:
			output += text.substr(index)
			break
		output += text.substr(index, open - index)
		var expression := text.substr(open + 1, close - open - 1).strip_edges()
		output += _evaluate_placeholder(expression, variable_source)
		index = close + 1
	return output


func _evaluate_placeholder(expression: String, variable_source: Variant) -> String:
	if expression.begins_with("if "):
		return _evaluate_conditional(expression.substr(3).strip_edges(), variable_source)
	var value: Variant = evaluator.evaluate(expression, variable_source, "")
	return str(value)


func _evaluate_conditional(expression: String, variable_source: Variant) -> String:
	var question := expression.find("?")
	var colon := expression.rfind(":")
	if question == -1 or colon == -1 or colon < question:
		return ""
	var condition := expression.substr(0, question).strip_edges()
	var true_text := expression.substr(question + 1, colon - question - 1).strip_edges()
	var false_text := expression.substr(colon + 1).strip_edges()
	return true_text if bool(evaluator.evaluate(condition, variable_source, false)) else false_text
