extends RefCounted

class_name NovellaExpressionEvaluator

var variables: Variant = null
var functions: Dictionary = {}
var errors: Array[String] = []

var _tokens: Array = []
var _index: int = 0

func evaluate(expression: String, variable_source: Variant = null, default_value: Variant = null) -> Variant:
	errors.clear()
	variables = variable_source if variable_source != null else variables
	_tokens = _scan(expression)
	_index = 0
	if _tokens.is_empty():
		return default_value
	var result: Variant = _parse_or()
	if _has_more():
		_error("Unexpected token '%s'." % _peek()["value"])
		return default_value
	if errors.is_empty():
		return result
	return default_value


func register_function(function_name: StringName, handler: Callable) -> void:
	functions[function_name] = handler


func _parse_or() -> Variant:
	var value: Variant = _parse_and()
	while _match_value("or") or _match_value("||"):
		var right: Variant = _parse_and()
		value = bool(value) or bool(right)
	return value


func _parse_and() -> Variant:
	var value: Variant = _parse_equality()
	while _match_value("and") or _match_value("&&"):
		var right: Variant = _parse_equality()
		value = bool(value) and bool(right)
	return value


func _parse_equality() -> Variant:
	var value: Variant = _parse_comparison()
	while true:
		if _match_value("=="):
			value = value == _parse_comparison()
		elif _match_value("!="):
			value = value != _parse_comparison()
		else:
			break
	return value


func _parse_comparison() -> Variant:
	var value: Variant = _parse_term()
	while true:
		if _match_value(">="):
			value = value >= _parse_term()
		elif _match_value("<="):
			value = value <= _parse_term()
		elif _match_value(">"):
			value = value > _parse_term()
		elif _match_value("<"):
			value = value < _parse_term()
		else:
			break
	return value


func _parse_term() -> Variant:
	var value: Variant = _parse_factor()
	while true:
		if _match_value("+"):
			value = _add(value, _parse_factor())
		elif _match_value("-"):
			value = value - _parse_factor()
		else:
			break
	return value


func _parse_factor() -> Variant:
	var value: Variant = _parse_unary()
	while true:
		if _match_value("*"):
			value = value * _parse_unary()
		elif _match_value("/"):
			var divisor: Variant = _parse_unary()
			if divisor == 0:
				_error("Division by zero.")
				return 0
			value = value / divisor
		elif _match_value("%"):
			value = int(value) % int(_parse_unary())
		else:
			break
	return value


func _parse_unary() -> Variant:
	if _match_value("not") or _match_value("!"):
		return not bool(_parse_unary())
	if _match_value("-"):
		return -_parse_unary()
	return _parse_primary()


func _parse_primary() -> Variant:
	if not _has_more():
		_error("Expected expression.")
		return null
	var token: Dictionary = _advance()
	match token["type"]:
		"number", "string", "bool":
			return token["literal"]
		"identifier":
			if _match_value("("):
				var args: Array = []
				if not _check_value(")"):
					while true:
						args.append(_parse_or())
						if not _match_value(","):
							break
				_consume(")", "Expected ')' after function arguments.")
				return _call_function(StringName(token["value"]), args)
			return _lookup_variable(StringName(token["value"]))
		"symbol":
			if token["value"] == "(":
				var value: Variant = _parse_or()
				_consume(")", "Expected ')' after expression.")
				return value
	_error("Unexpected token '%s'." % token["value"])
	return null


func _call_function(function_name: StringName, args: Array) -> Variant:
	var handler: Callable = functions.get(function_name, Callable())
	if not handler.is_valid():
		_error("Unknown function '%s'." % function_name)
		return null
	return handler.callv(args)


func _lookup_variable(variable_name: StringName) -> Variant:
	if variables == null:
		_error("No variable source available for '%s'." % variable_name)
		return null
	if variables is Dictionary:
		if variables.has(variable_name):
			return variables[variable_name]
		if variables.has(String(variable_name)):
			return variables[String(variable_name)]
	elif variables.has_method("has_variable") and variables.has_variable(variable_name):
		return variables.get_variable(variable_name)
	elif variables.has_method("get_variable"):
		return variables.get_variable(variable_name, null)
	_error("Unknown variable '%s'." % variable_name)
	return null


func _add(left: Variant, right: Variant) -> Variant:
	if left is String or right is String:
		return str(left) + str(right)
	return left + right


func _scan(expression: String) -> Array:
	var result: Array = []
	var index := 0
	while index < expression.length():
		var ch := expression[index]
		if ch == " " or ch == "\t" or ch == "\n":
			index += 1
			continue
		if ch == "\"":
			var string_result := _scan_string(expression, index)
			result.append({"type": "string", "value": string_result["value"], "literal": string_result["value"]})
			index = int(string_result["next_index"])
			continue
		if _is_digit(ch):
			var start := index
			while index < expression.length() and (_is_digit(expression[index]) or expression[index] == "."):
				index += 1
			var number_text := expression.substr(start, index - start)
			result.append({
				"type": "number",
				"value": number_text,
				"literal": float(number_text) if number_text.contains(".") else int(number_text),
			})
			continue
		if _is_identifier_start(ch):
			var start := index
			while index < expression.length() and _is_identifier_part(expression[index]):
				index += 1
			var word := expression.substr(start, index - start)
			if word == "true" or word == "false":
				result.append({"type": "bool", "value": word, "literal": word == "true"})
			else:
				result.append({"type": "identifier", "value": word, "literal": word})
			continue
		var two := expression.substr(index, 2)
		if ["==", "!=", ">=", "<=", "&&", "||"].has(two):
			result.append({"type": "symbol", "value": two, "literal": two})
			index += 2
			continue
		result.append({"type": "symbol", "value": ch, "literal": ch})
		index += 1
	return result


func _scan_string(expression: String, start_index: int) -> Dictionary:
	var index := start_index + 1
	var value := ""
	while index < expression.length():
		var ch := expression[index]
		if ch == "\\" and index + 1 < expression.length():
			value += expression[index + 1]
			index += 2
			continue
		if ch == "\"":
			return {"value": value, "next_index": index + 1}
		value += ch
		index += 1
	_error("Unterminated string in expression.")
	return {"value": value, "next_index": expression.length()}


func _has_more() -> bool:
	return _index < _tokens.size()


func _peek() -> Dictionary:
	return _tokens[_index]


func _advance() -> Dictionary:
	var token: Dictionary = _tokens[_index]
	_index += 1
	return token


func _check_value(value: String) -> bool:
	return _has_more() and _peek()["value"] == value


func _match_value(value: String) -> bool:
	if _check_value(value):
		_index += 1
		return true
	return false


func _consume(value: String, message: String) -> bool:
	if _match_value(value):
		return true
	_error(message)
	return false


func _error(message: String) -> void:
	errors.append(message)


func _is_digit(ch: String) -> bool:
	return ch >= "0" and ch <= "9"


func _is_identifier_start(ch: String) -> bool:
	return ch == "_" or ch.unicode_at(0) > 127 or (ch >= "A" and ch <= "Z") or (ch >= "a" and ch <= "z")


func _is_identifier_part(ch: String) -> bool:
	return _is_identifier_start(ch) or _is_digit(ch)
